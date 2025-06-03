import Foundation
import Combine

class ResultViewModel: ObservableObject {
    @Published var flightResults: [FlightResult] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchId: String? = nil
    
    // Pagination properties
    @Published var hasMoreResults: Bool = true
    @Published var totalResultsCount: Int = 0
    private var currentOffset: Int = 0
    private let pageSize: Int = 15
    
    // Poll response data
    @Published var pollResponse: PollResponse? = nil
    @Published var selectedFlight: FlightResult? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let pollApi = PollApi.shared
    private var pollTimer: Timer?
    private var maxRetries = 10
    private var currentRetries = 0
    private var isCacheComplete = false
    
    init() {}
    
    func pollFlights(searchId: String) {
        guard !searchId.isEmpty else {
            errorMessage = "Invalid search ID"
            return
        }
        
        // Reset for new search
        resetPagination()
        
        self.searchId = searchId
        isLoading = true
        errorMessage = nil
        currentRetries = 0
        flightResults = [] // Clear previous results
        
        print("🚀 Starting poll for search_id: \(searchId)")
        
        // Start polling with retry mechanism
        loadInitialResults(searchId: searchId)
    }
    
    private func resetPagination() {
        currentOffset = 0
        hasMoreResults = true
        totalResultsCount = 0
        isCacheComplete = false
        isLoadingMore = false
    }
    
    private func loadInitialResults(searchId: String) {
        let emptyRequest = PollRequest()
        
        pollApi.pollFlights(
            searchId: searchId,
            request: emptyRequest,
            offset: 0,
            limit: pageSize
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    self.handleInitialPollSuccess(response)
                    
                case .failure(let error):
                    self.handlePollFailure(error, isInitial: true, searchId: searchId)
                }
            }
        }
    }
    
    private func handleInitialPollSuccess(_ response: PollResponse) {
        pollResponse = response
        totalResultsCount = response.count
        isCacheComplete = response.cache
        
        print("✅ Initial poll successful!")
        print("   Total flights available: \(response.count)")
        print("   Results in this batch: \(response.results.count)")
        print("   Cache complete: \(response.cache)")
        print("   Has next page: \(response.next != nil)")
        
        if response.results.isEmpty && response.count == 0 && currentRetries < maxRetries {
            // If no results but API indicates there should be flights, retry
            print("🔄 No results yet, retrying... (\(currentRetries + 1)/\(maxRetries))")
            currentRetries += 1
            
            // Retry after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let searchId = self.searchId {
                    self.loadInitialResults(searchId: searchId)
                }
            }
        } else {
            // We have results or max retries reached
            isLoading = false
            flightResults = response.results
            currentOffset = response.results.count
            
            // Update hasMoreResults based on cache status and available results
            hasMoreResults = !response.cache && response.results.count == pageSize
            
            if response.results.isEmpty {
                print("⚠️ No flights found after \(currentRetries) retries")
            }
        }
    }
    
    private func handlePollFailure(_ error: Error, isInitial: Bool, searchId: String) {
        if currentRetries < maxRetries {
            print("❌ Poll failed, retrying... (\(currentRetries + 1)/\(maxRetries)): \(error)")
            currentRetries += 1
            
            // Retry after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if isInitial {
                    self.loadInitialResults(searchId: searchId)
                } else {
                    self.loadMoreResults()
                }
            }
        } else {
            if isInitial {
                isLoading = false
            } else {
                isLoadingMore = false
            }
            errorMessage = "Failed to fetch flights: \(error.localizedDescription)"
            print("❌ Poll failed after \(maxRetries) retries: \(error)")
        }
    }
    
    func loadMoreResults() {
        guard let searchId = searchId,
              hasMoreResults,
              !isLoadingMore,
              !isLoading else {
            print("🚫 Cannot load more: searchId=\(searchId ?? "nil"), hasMore=\(hasMoreResults), isLoadingMore=\(isLoadingMore), isLoading=\(isLoading)")
            return
        }
        
        isLoadingMore = true
        errorMessage = nil
        currentRetries = 0
        
        print("📄 Loading more results - offset: \(currentOffset), pageSize: \(pageSize)")
        
        let emptyRequest = PollRequest()
        
        pollApi.pollFlights(
            searchId: searchId,
            request: emptyRequest,
            offset: currentOffset,
            limit: pageSize
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    self.handleLoadMoreSuccess(response)
                    
                case .failure(let error):
                    self.handlePollFailure(error, isInitial: false, searchId: searchId)
                }
            }
        }
    }
    
    private func handleLoadMoreSuccess(_ response: PollResponse) {
        isLoadingMore = false
        
        print("✅ Load more successful!")
        print("   New results count: \(response.results.count)")
        print("   Total results now: \(flightResults.count + response.results.count)")
        print("   Cache status: \(response.cache)")
        
        // Append new results to existing ones (avoid duplicates)
        let newResults = response.results.filter { newResult in
            !flightResults.contains { existingResult in
                existingResult.id == newResult.id
            }
        }
        
        flightResults.append(contentsOf: newResults)
        currentOffset += newResults.count
        isCacheComplete = response.cache
        
        // Update hasMoreResults based on cache status and whether we got a full page
        hasMoreResults = !response.cache && response.results.count == pageSize
        
        print("   Unique new results added: \(newResults.count)")
        print("   Total results in list: \(flightResults.count)")
        print("   Has more results: \(hasMoreResults)")
    }
    
    func selectFlight(_ flight: FlightResult) {
        selectedFlight = flight
        
        // Log selected flight details
        print("✈️ Selected flight:")
        print("   ID: \(flight.id)")
        print("   Duration: \(flight.formattedDuration)")
        print("   Price: \(flight.formattedPrice)")
        print("   Legs: \(flight.legs.count)")
        
        for (index, leg) in flight.legs.enumerated() {
            print("   Leg \(index + 1):")
            print("     \(leg.originCode) → \(leg.destinationCode)")
            print("     Departure: \(leg.formattedDepartureTime)")
            print("     Arrival: \(leg.formattedArrivalTime)")
            print("     Stops: \(leg.stopsText)")
        }
    }
    
    func applyFilters(request: PollRequest) {
        guard let searchId = searchId else { return }
        
        // Reset pagination when applying filters
        resetPagination()
        
        isLoading = true
        errorMessage = nil
        flightResults = [] // Clear existing results
        
        pollApi.pollFlights(
            searchId: searchId,
            request: request,
            offset: 0,
            limit: pageSize
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    self.pollResponse = response
                    self.flightResults = response.results
                    self.currentOffset = response.results.count
                    self.totalResultsCount = response.count
                    self.isCacheComplete = response.cache
                    self.hasMoreResults = !response.cache && response.results.count == self.pageSize
                    
                case .failure(let error):
                    self.errorMessage = "Failed to apply filters: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Check if we should load more results based on scroll position
    func shouldLoadMore(currentItem: FlightResult) -> Bool {
        guard let lastItem = flightResults.last else { return false }
        
        // Load more when we're 5 items from the end
        let thresholdIndex = max(0, flightResults.count - 5)
        let currentIndex = flightResults.firstIndex { $0.id == currentItem.id } ?? 0
        
        return currentIndex >= thresholdIndex && hasMoreResults && !isLoadingMore
    }
    
    deinit {
        pollTimer?.invalidate()
    }
}
