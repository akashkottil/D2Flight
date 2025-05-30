import Foundation
import Combine

class ResultViewModel: ObservableObject {
    @Published var flightResults: [FlightResult] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchId: String? = nil
    
    // Poll response data
    @Published var pollResponse: PollResponse? = nil
    @Published var selectedFlight: FlightResult? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let pollApi = PollApi.shared
    private var pollTimer: Timer?
    private var maxRetries = 10
    private var currentRetries = 0
    
    init() {}
    
    func pollFlights(searchId: String) {
        guard !searchId.isEmpty else {
            errorMessage = "Invalid search ID"
            return
        }
        
        self.searchId = searchId
        isLoading = true
        errorMessage = nil
        currentRetries = 0
        flightResults = [] // Clear previous results
        
        print("🚀 Starting poll for search_id: \(searchId)")
        
        // Start polling with retry mechanism
        startPollingWithRetry(searchId: searchId)
    }
    
    private func startPollingWithRetry(searchId: String) {
        let emptyRequest = PollRequest()
        
        pollApi.pollFlights(searchId: searchId, request: emptyRequest) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    self.pollResponse = response
                    
                    print("✅ Poll successful!")
                    print("   Total flights: \(response.count)")
                    print("   Results count: \(response.results.count)")
                    print("   Airlines: \(response.airlines.map { $0.airlineName }.joined(separator: ", "))")
                    print("   Price range: $\(response.cheapest_flight?.price ?? 0)")
                    
                    if response.results.isEmpty && response.count == 0 && self.currentRetries < self.maxRetries {
                        // If no results but API indicates there should be flights, retry
                        print("🔄 No results yet, retrying... (\(self.currentRetries + 1)/\(self.maxRetries))")
                        self.currentRetries += 1
                        
                        // Retry after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.startPollingWithRetry(searchId: searchId)
                        }
                    } else {
                        // We have results or max retries reached
                        self.isLoading = false
                        self.flightResults = response.results
                        
                        if response.results.isEmpty {
                            print("⚠️ No flights found after \(self.currentRetries) retries")
                        }
                    }
                    
                case .failure(let error):
                    if self.currentRetries < self.maxRetries {
                        print("❌ Poll failed, retrying... (\(self.currentRetries + 1)/\(self.maxRetries)): \(error)")
                        self.currentRetries += 1
                        
                        // Retry after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.startPollingWithRetry(searchId: searchId)
                        }
                    } else {
                        self.isLoading = false
                        self.errorMessage = "Failed to fetch flights: \(error.localizedDescription)"
                        self.flightResults = []
                        print("❌ Poll failed after \(self.maxRetries) retries: \(error)")
                    }
                }
            }
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
    
    func applyFilters(request: PollRequest) {
        guard let searchId = searchId else { return }
        
        isLoading = true
        errorMessage = nil
        
        pollApi.pollFlights(searchId: searchId, request: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.pollResponse = response
                    self?.flightResults = response.results
                case .failure(let error):
                    self?.errorMessage = "Failed to apply filters: \(error.localizedDescription)"
                }
            }
        }
    }
    
    deinit {
        pollTimer?.invalidate()
    }
}
