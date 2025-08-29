import Foundation
import Combine

// MARK: - Performance Optimized FlightSearchViewModel
@MainActor
class FlightSearchViewModel: ObservableObject {
    // MARK: - Published Properties (Optimized with @Published where necessary)
    @Published var departureIATACode: String = ""
    @Published var destinationIATACode: String = ""
    @Published var travelDate: Date = Date()
    @Published var returnDate: Date = Date().addingTimeInterval(86400 * 7)
    @Published var cabinClass: String = "economy"
    @Published var adults: Int = 1
    @Published var childrenAges: [Int] = []
    @Published var isRoundTrip: Bool = false
    
    // MARK: - Search State (Optimized)
    @Published private(set) var searchId: String? = nil
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let searchApi = FlightSearchApi.shared
    private var currentSearchTask: Task<Void, Never>? = nil
    
    // MARK: - Search Queue for Performance
    private let searchQueue = DispatchQueue(label: "flight.search.queue", qos: .userInitiated)
    private let validationQueue = DispatchQueue(label: "flight.validation.queue", qos: .utility)
    
    deinit {
        currentSearchTask?.cancel()
        cancellables.removeAll()
    }
    
    // MARK: - Optimized Search Method
    func searchFlights() {
        // Cancel any existing search
        currentSearchTask?.cancel()
        
        // Start new search task
        currentSearchTask = Task { @MainActor in
            await performOptimizedSearch()
        }
    }
    
    private func performOptimizedSearch() async {
        print("🚀 Starting optimized flight search")
        
        // Immediate UI feedback
        isLoading = true
        errorMessage = nil
        searchId = nil
        
        do {
            // Background validation and preparation
            let searchRequest = await prepareSearchRequest()
            
            // Validate search parameters
            try await validateSearchParameters(searchRequest)
            
            // Perform API call
            let response = try await performAPISearch(searchRequest)
            
            // Process successful response
            await processSearchResponse(response)
            
        } catch let error as SearchValidationError {
            await handleValidationError(error)
        } catch {
            await handleSearchError(error)
        }
    }
    
    // MARK: - Background Preparation Methods
    
    private func prepareSearchRequest() async -> SearchRequest {
        return await Task.detached(priority: .userInitiated) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let departureDateString = dateFormatter.string(from: await MainActor.run { self.travelDate })
            
            var legs: [SearchLeg] = []
            
            // Prepare departure leg
            let departureLeg = SearchLeg(
                origin: await MainActor.run { self.departureIATACode },
                destination: await MainActor.run { self.destinationIATACode },
                date: departureDateString
            )
            legs.append(departureLeg)
            
            // Prepare return leg if round trip
            let isRoundTripValue = await MainActor.run { self.isRoundTrip }
            if isRoundTripValue {
                let returnDateString = dateFormatter.string(from: await MainActor.run { self.returnDate })
                let returnLeg = SearchLeg(
                    origin: await MainActor.run { self.destinationIATACode },
                    destination: await MainActor.run { self.departureIATACode },
                    date: returnDateString
                )
                legs.append(returnLeg)
            }
            
            return SearchRequest(
                legs: legs,
                cabin_class: await MainActor.run { self.cabinClass },
                adults: await MainActor.run { self.adults },
                children_ages: await MainActor.run { self.childrenAges }
            )
        }.value
    }
    
    private func validateSearchParameters(_ request: SearchRequest) async throws {
        try await Task.detached(priority: .utility) {
            // Validation logic
            guard !request.legs.isEmpty else {
                throw SearchValidationError.invalidRoute
            }
            
            guard request.adults > 0 else {
                throw SearchValidationError.invalidPassengerCount
            }
            
            for leg in request.legs {
                guard !leg.origin.isEmpty && !leg.destination.isEmpty else {
                    throw SearchValidationError.invalidRoute
                }
                
                guard leg.origin != leg.destination else {
                    throw SearchValidationError.sameOriginDestination
                }
            }
        }.value
    }
    
    private func performAPISearch(_ request: SearchRequest) async throws -> SearchResponse {
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                // Get dynamic API parameters
                let apiParams = APIConstants.getCompleteAPIParameters()
                
                await MainActor.run {
                    print("🛫 Starting flight search with request:")
                    print("   Trip Type: \(self.isRoundTrip ? "Round Trip" : "One Way")")
                    print("   Origin: \(self.departureIATACode)")
                    print("   Destination: \(self.destinationIATACode)")
                    print("   Cabin Class: \(self.cabinClass)")
                    print("   Adults: \(self.adults)")
                    print("   Children Ages: \(self.childrenAges)")
                    print("   Number of legs: \(request.legs.count)")
                    print("   🔧 Using dynamic country: \(apiParams.country)")
                    print("   🔧 Using dynamic currency: \(apiParams.currency)")
                    print("   🔧 Using dynamic language: \(apiParams.language)")
                    print("   🔧 Using dynamic user ID: \(apiParams.userId)")
                }
                
                self.searchApi.startSearch(request: request) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
    
    private func processSearchResponse(_ response: SearchResponse) async {
        print("✅ Flight search successful!")
        print("   Search ID: \(response.search_id)")
        print("   Language: \(response.language)")
        print("   Currency: \(response.currency)")
        print("   Mode: \(response.mode)")
        
        // Update UI state
        searchId = response.search_id
        isLoading = false
        
        // Track successful search
        await Task.detached(priority: .background) {
            UserManager.shared.trackFlightSearch()
        }.value
    }
    
    // MARK: - Error Handling
    
    private func handleValidationError(_ error: SearchValidationError) async {
        let errorMsg: String
        
        switch error {
        case .invalidRoute:
            errorMsg = "Please select valid departure and destination locations."
        case .invalidPassengerCount:
            errorMsg = "Please select at least one adult passenger."
        case .sameOriginDestination:
            errorMsg = "Departure and destination cannot be the same."
        case .invalidDates:
            errorMsg = "Please select valid travel dates."
        }
        
        print("❌ Validation error: \(errorMsg)")
        isLoading = false
        errorMessage = errorMsg
        searchId = nil
    }
    
    private func handleSearchError(_ error: Error) async {
        let errorMsg = "Search failed: \(error.localizedDescription)"
        
        print("❌ Flight search failed:")
        print("   Error: \(error.localizedDescription)")
        
        isLoading = false
        errorMessage = errorMsg
        searchId = nil
    }
    
    // MARK: - Utility Methods
    
    func resetSearch() {
        currentSearchTask?.cancel()
        isLoading = false
        errorMessage = nil
        searchId = nil
    }
    
    func updateSearchParameters(
        origin: String,
        destination: String,
        departureDate: Date,
        returnDate: Date? = nil,
        isRoundTrip: Bool = false,
        adults: Int = 1,
        children: [Int] = [],
        cabinClass: String = "economy"
    ) {
        self.departureIATACode = origin
        self.destinationIATACode = destination
        self.travelDate = departureDate
        if let returnDate = returnDate {
            self.returnDate = returnDate
        }
        self.isRoundTrip = isRoundTrip
        self.adults = adults
        self.childrenAges = children
        self.cabinClass = cabinClass
    }
}

// MARK: - Search Validation Error
enum SearchValidationError: Error, LocalizedError {
    case invalidRoute
    case invalidPassengerCount
    case sameOriginDestination
    case invalidDates
    
    var errorDescription: String? {
        switch self {
        case .invalidRoute:
            return "Invalid route selected"
        case .invalidPassengerCount:
            return "Invalid passenger count"
        case .sameOriginDestination:
            return "Origin and destination cannot be the same"
        case .invalidDates:
            return "Invalid travel dates"
        }
    }
}
