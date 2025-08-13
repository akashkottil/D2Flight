import Foundation
import Combine

class FlightSearchViewModel: ObservableObject {
    @Published var departureIATACode: String = ""
    @Published var destinationIATACode: String = ""
    @Published var travelDate: Date = Date()
    @Published var returnDate: Date = Date().addingTimeInterval(86400 * 7) // Default 7 days later
    @Published var cabinClass: String = "economy"
    @Published var adults: Int = 1
    @Published var childrenAges: [Int] = []
    @Published var isRoundTrip: Bool = false // Add this property
    
    @Published var searchId: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    func searchFlights() {
        guard !departureIATACode.isEmpty,
              !destinationIATACode.isEmpty else {
            errorMessage = "Please select both departure and destination locations."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let departureDateString = dateFormatter.string(from: travelDate)
        
        var legs: [SearchLeg] = []
        
        // First leg (departure)
        let departureLeg = SearchLeg(
            origin: departureIATACode,
            destination: destinationIATACode,
            date: departureDateString
        )
        legs.append(departureLeg)
        
        // Second leg (return) - only if round trip
        if isRoundTrip {
            let returnDateString = dateFormatter.string(from: returnDate)
            let returnLeg = SearchLeg(
                origin: destinationIATACode, // Swap origin and destination
                destination: departureIATACode,
                date: returnDateString
            )
            legs.append(returnLeg)
        }
        
        let request = SearchRequest(
            legs: legs,
            cabin_class: cabinClass,
            adults: adults,
            children_ages: childrenAges
        )
        
        // Get dynamic API parameters
        let apiParams = APIConstants.getAPIParameters()
        
        // Print the search request for debugging
        print("🛫 Starting flight search with request:")
        print("   Trip Type: \(isRoundTrip ? "Round Trip" : "One Way")")
        print("   Origin: \(departureIATACode)")
        print("   Destination: \(destinationIATACode)")
        print("   Departure Date: \(departureDateString)")
        if isRoundTrip {
            print("   Return Date: \(dateFormatter.string(from: returnDate))")
        }
        print("   Cabin Class: \(cabinClass)")
        print("   Adults: \(adults)")
        print("   Children Ages: \(childrenAges)")
        print("   Number of legs: \(legs.count)")
        print("   🔧 Using dynamic country: \(apiParams.country)")
        print("   🔧 Using dynamic currency: \(apiParams.currency)")
        print("   🔧 Using dynamic language: \(apiParams.language)")
        
        // ✅ UPDATED: API call now uses dynamic parameters automatically
        FlightSearchApi.shared.startSearch(request: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    self?.searchId = response.search_id
                    
                    // Print the successful response
                    print("✅ Flight search successful!")
                    print("   Search ID: \(response.search_id)")
                    print("   Language: \(response.language)")
                    print("   Currency: \(response.currency)")
                    print("   Mode: \(response.mode)")
                    
                case .failure(let error):
                    self?.errorMessage = "Search failed: \(error.localizedDescription)"
                    self?.searchId = nil
                    
                    // Print the error
                    print("❌ Flight search failed:")
                    print("   Error: \(error.localizedDescription)")
                }
            }
        }
    }
}
