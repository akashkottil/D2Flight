import Foundation
import Combine

class FlightSearchViewModel: ObservableObject {
    @Published var departureIATACode: String = ""
    @Published var destinationIATACode: String = ""
    @Published var travelDate: Date = Date()
    @Published var cabinClass: String = "economy"
    @Published var adults: Int = 1
    @Published var childrenAges: [Int] = []
    
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
        let dateString = dateFormatter.string(from: travelDate)
        
        let leg = SearchLeg(origin: departureIATACode, destination: destinationIATACode, date: dateString)
        let request = SearchRequest(
            legs: [leg],
            cabin_class: cabinClass,
            adults: adults,
            children_ages: childrenAges
        )
        
        // Print the search request for debugging
        print("🛫 Starting flight search with request:")
        print("   Origin: \(departureIATACode)")
        print("   Destination: \(destinationIATACode)")
        print("   Date: \(dateString)")
        print("   Cabin Class: \(cabinClass)")
        print("   Adults: \(adults)")
        print("   Children Ages: \(childrenAges)")
        
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
