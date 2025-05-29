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
    
    init() {}
    
    
    
    func pollFlights(searchId: String) {
        guard !searchId.isEmpty else {
            errorMessage = "Invalid search ID"
            return
        }
        
        self.searchId = searchId
        isLoading = true
        errorMessage = nil
        
        print("🚀 Starting poll for search_id: \(searchId)")
        
        // Initial poll without filters
        let emptyRequest = PollRequest()
        
        pollApi.pollFlights(searchId: searchId, request: emptyRequest) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.pollResponse = response
                    self?.flightResults = response.results
                    
                    print("✅ Poll successful!")
                    print("   Total flights: \(response.count)")
                    print("   Results count: \(response.results.count)")
                    print("   Airlines: \(response.airlines.map { $0.airlineName }.joined(separator: ", "))")
                    print("   Price range: $\(response.cheapest_flight?.price ?? 0) - $\(response.results.first?.max_price ?? 0)")
                    
                case .failure(let error):
                    self?.errorMessage = "Failed to fetch flights: \(error.localizedDescription)"
                    self?.flightResults = []
                    print("❌ Poll failed: \(error)")
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
}
