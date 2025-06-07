import Foundation
import Combine

class ResultViewModel: ObservableObject {
    @Published var flightResults: [FlightResult] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchId: String? = nil
    
    // Updated pagination properties for page-based pagination
    @Published var hasMoreResults: Bool = true
    @Published var totalResultsCount: Int = 0
    private var currentPage: Int = 1
    private let initialPageSize: Int = 8
    private let subsequentPageSize: Int = 30
    
    // Poll response data
    @Published var pollResponse: PollResponse? = nil
    @Published var selectedFlight: FlightResult? = nil
    @Published var totalPollCount: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    private let pollApi = PollApi.shared
    private var maxRetries = 10
    private var currentRetries = 0
    private var isCacheComplete = false
    private var maxTotalPolls = 50
    private var pollStartTime: Date?
    
    // Add flag to control continuous polling
    private var shouldContinuouslyPoll = false
    
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
        flightResults = []
        shouldContinuouslyPoll = true
        
        print("🚀 Starting poll for search_id: \(searchId)")
        
        // Start polling with retry mechanism
        loadInitialResults(searchId: searchId)
    }
    
    private func resetPagination() {
        currentPage = 1
        hasMoreResults = true
        totalResultsCount = 0
        isCacheComplete = false
        isLoadingMore = false
        totalPollCount = 0
        pollStartTime = Date()
        currentRetries = 0
        shouldContinuouslyPoll = false
    }
    
    private func loadInitialResults(searchId: String) {
        // Safety check to prevent infinite polling
        guard totalPollCount < maxTotalPolls else {
            print("⚠️ Reached maximum poll limit (\(maxTotalPolls)), stopping")
            isLoading = false
            errorMessage = "Search timeout - please try again"
            return
        }
        
        totalPollCount += 1
        let emptyRequest = PollRequest()
        
        print("📄 Loading initial results - page: \(currentPage), limit: \(initialPageSize) (poll #\(totalPollCount))")
        
        pollApi.pollFlights(
            searchId: searchId,
            request: emptyRequest,
            page: currentPage,
            limit: initialPageSize
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
        
        if response.results.isEmpty && response.count == 0 && currentRetries < maxRetries && !isCacheComplete {
            // If no results but API indicates there should be flights, retry
            print("🔄 No results yet, retrying... (\(currentRetries + 1)/\(maxRetries))")
            currentRetries += 1
            
            // Retry after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let searchId = self.searchId, self.shouldContinuouslyPoll {
                    self.loadInitialResults(searchId: searchId)
                }
            }
        } else {
            // We have results or max retries reached
            isLoading = false
            flightResults = response.results
            currentPage = 2 // Next page will be 2 (since we just loaded page 1)
            
            // Check if we have more results to load
            let hasAllResults = flightResults.count >= totalResultsCount
            hasMoreResults = !isCacheComplete || !hasAllResults
            
            print("   Current results: \(flightResults.count), Total available: \(totalResultsCount)")
            print("   Has all results: \(hasAllResults), Cache complete: \(isCacheComplete)")
            print("   Has more results: \(hasMoreResults)")
            
            if response.results.isEmpty {
                print("⚠️ No flights found after \(currentRetries) retries")
                hasMoreResults = false
            }
            
            // Start continuous polling only if cache is not complete
            if !isCacheComplete && shouldContinuouslyPoll {
                startContinuousPolling()
            }
        }
    }
    
    private func handlePollFailure(_ error: Error, isInitial: Bool, searchId: String) {
        if currentRetries < maxRetries {
            print("❌ Poll failed, retrying... (\(currentRetries + 1)/\(maxRetries)): \(error)")
            currentRetries += 1
            
            // Exponential backoff: 2s, 4s, 6s, 8s, etc.
            let retryDelay = min(2.0 * Double(currentRetries), 10.0)
            
            // Retry after calculated delay
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
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
            errorMessage = "Failed to fetch flights after \(maxRetries) attempts: \(error.localizedDescription)"
            print("❌ Poll failed after \(maxRetries) retries: \(error)")
        }
    }
    
    // Continuous polling for cache updates (only when cache is not complete)
    private func startContinuousPolling() {
        guard let searchId = searchId, shouldContinuouslyPoll else { return }
        
        // Only poll if cache is not complete
        guard !isCacheComplete else {
            print("🏁 Cache is complete, stopping continuous polling")
            return
        }
        
        print("🔄 Scheduling cache check in 3 seconds...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard self.shouldContinuouslyPoll, !self.isCacheComplete else { return }
            
            // Check for cache updates without changing pagination
            self.checkForCacheUpdates(searchId: searchId)
        }
    }
    
    private func checkForCacheUpdates(searchId: String) {
        guard totalPollCount < maxTotalPolls else {
            print("⚠️ Reached maximum poll limit for cache updates")
            return
        }
        
        totalPollCount += 1
        let emptyRequest = PollRequest()
        
        print("🔍 Checking for cache updates (poll #\(totalPollCount))")
        
        pollApi.pollFlights(
            searchId: searchId,
            request: emptyRequest,
            page: 1,
            limit: initialPageSize
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    let previousCacheStatus = self.isCacheComplete
                    self.isCacheComplete = response.cache
                    self.totalResultsCount = response.count
                    
                    print("   Cache status: \(previousCacheStatus) → \(response.cache)")
                    print("   Total count: \(self.totalResultsCount)")
                    
                    // Update hasMoreResults based on current state
                    let hasAllResults = self.flightResults.count >= self.totalResultsCount
                    self.hasMoreResults = !response.cache || !hasAllResults
                    
                    // Continue polling if cache is still not complete
                    if !response.cache && self.shouldContinuouslyPoll {
                        self.startContinuousPolling()
                    }
                    
                case .failure(let error):
                    print("❌ Cache check failed: \(error)")
                    // Continue polling despite failure
                    if self.shouldContinuouslyPoll {
                        self.startContinuousPolling()
                    }
                }
            }
        }
    }
    
    // Single loadMoreResults method for user-triggered pagination
    func loadMoreResults() {
        guard let searchId = searchId else {
            print("🚫 Cannot load more: no searchId")
            return
        }
        
        // Safety check to prevent infinite polling
        guard totalPollCount < maxTotalPolls else {
            print("⚠️ Reached maximum poll limit (\(maxTotalPolls)), stopping pagination")
            hasMoreResults = false
            return
        }
        
        // Check if we should continue loading
        let hasAllResults = flightResults.count >= totalResultsCount
        let shouldContinue = hasMoreResults && !hasAllResults
        
        guard shouldContinue && !isLoadingMore && !isLoading else {
            print("🚫 Cannot load more:")
            print("   Should continue: \(shouldContinue)")
            print("   Has more results: \(hasMoreResults)")
            print("   Has all results: \(hasAllResults) (\(flightResults.count)/\(totalResultsCount))")
            print("   Loading states - more: \(isLoadingMore), initial: \(isLoading)")
            return
        }
        
        totalPollCount += 1
        isLoadingMore = true
        errorMessage = nil
        currentRetries = 0
        
        let pageSize = currentPage == 1 ? initialPageSize : subsequentPageSize
        
        print("📄 Loading more results - page: \(currentPage), pageSize: \(pageSize) (poll #\(totalPollCount))")
        print("   Current results: \(flightResults.count)/\(totalResultsCount)")
        
        let emptyRequest = PollRequest()
        
        pollApi.pollFlights(
            searchId: searchId,
            request: emptyRequest,
            page: currentPage,
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
        
        // Update cache status and total count
        let previousTotal = totalResultsCount
        isCacheComplete = response.cache
        totalResultsCount = response.count
        
        print("✅ Load more successful!")
        print("   New results count: \(response.results.count)")
        print("   Total count updated: \(previousTotal) → \(totalResultsCount)")
        
        // Append new results to the existing results (avoid duplicates)
        let newResults = response.results.filter { newResult in
            !flightResults.contains { existingResult in
                existingResult.id == newResult.id
            }
        }
        
        flightResults.append(contentsOf: newResults)
        currentPage += 1 // Increment page for the next request
        
        let hasAllResults = flightResults.count >= totalResultsCount
        hasMoreResults = !hasAllResults // Simplified logic
        
        print("   Total results in list: \(flightResults.count)")
        print("   Total available: \(totalResultsCount)")
        print("   Cache complete: \(isCacheComplete)")
        print("   Has more results: \(hasMoreResults)")
        
        if flightResults.count >= totalResultsCount {
            print("🏁 All results loaded!")
            hasMoreResults = false
        }
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
    
    // ✅ FIXED: Improved applyFilters method
        func applyFilters(request: PollRequest) {
            guard let searchId = searchId else {
                print("❌ Cannot apply filters: no searchId")
                return
            }
            
            print("🔧 Applying filters with searchId: \(searchId)")
            print("   Has filters: \(request.hasFilters())")
            
            // Stop continuous polling when applying filters
            shouldContinuouslyPoll = false
            
            // Reset pagination when applying filters
            resetPagination()
            shouldContinuouslyPoll = false // Keep polling stopped for filter results
            
            isLoading = true
            errorMessage = nil
            flightResults = [] // Clear existing results
            totalPollCount += 1
            
            print("📡 Making filtered poll request (poll #\(totalPollCount))")
            
            pollApi.pollFlights(
                searchId: searchId,
                request: request,
                page: currentPage,
                limit: initialPageSize
            ) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        print("✅ Filter poll successful!")
                        print("   Results found: \(response.results.count)")
                        print("   Total available: \(response.count)")
                        print("   Cache status: \(response.cache)")
                        
                        self.pollResponse = response
                        self.flightResults = response.results
                        self.currentPage = 2 // Next page will be 2
                        self.totalResultsCount = response.count
                        self.isCacheComplete = response.cache
                        
                        // Check if we need more results
                        let hasAllResults = self.flightResults.count >= self.totalResultsCount
                        self.hasMoreResults = !hasAllResults && !response.cache
                        
                        print("   Has all results: \(hasAllResults)")
                        print("   Has more results: \(self.hasMoreResults)")
                        
                        // Don't start continuous polling for filtered results
                        // User can manually load more if needed
                        
                    case .failure(let error):
                        print("❌ Filter poll failed: \(error)")
                        self.errorMessage = "Failed to apply filters: \(error.localizedDescription)"
                        self.flightResults = []
                        self.hasMoreResults = false
                    }
                }
            }
        }
    
    // Check if we should load more results based on scroll position
    func shouldLoadMore(currentItem: FlightResult) -> Bool {
        guard let lastItem = flightResults.last else { return false }
        
        // Don't trigger if already loading or no search ID
        guard !isLoadingMore, !isLoading, searchId != nil else { return false }
        
        // Check if we have all results
        let hasAllResults = flightResults.count >= totalResultsCount
        
        // Only load more if we don't have all results
        guard hasMoreResults && !hasAllResults else {
            return false
        }
        
        // Load more when we're 3 items from the end (for better UX)
        let thresholdIndex = max(0, flightResults.count - 3)
        let currentIndex = flightResults.firstIndex { $0.id == currentItem.id } ?? 0
        
        let shouldLoad = currentIndex >= thresholdIndex
        
        if shouldLoad {
            print("🔄 Should load more:")
            print("   Current item index: \(currentIndex)/\(flightResults.count - 1)")
            print("   Threshold: \(thresholdIndex)")
            print("   Results: \(flightResults.count)/\(totalResultsCount)")
            print("   Has more: \(hasMoreResults)")
        }
        
        return shouldLoad
    }
    
    // Call this when the view disappears to stop polling
    func stopPolling() {
        shouldContinuouslyPoll = false
        print("🛑 Polling stopped")
    }
    
    deinit {
        shouldContinuouslyPoll = false
    }
}
