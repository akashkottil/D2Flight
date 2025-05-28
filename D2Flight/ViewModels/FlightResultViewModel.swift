import Foundation
import Combine

class FlightResultsViewModel: ObservableObject {
    @Published var pollResponse: PollResponse?
    @Published var flightResults: [FlightResult] = []
    @Published var airlines: [Airline] = []
    @Published var agencies: [Agency] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Filter and sort properties
    @Published var selectedSortBy: String? = nil
    @Published var selectedSortOrder: String? = nil
    @Published var maxDuration: Int? = nil
    @Published var maxStops: Int? = nil
    @Published var minPrice: Double? = nil
    @Published var maxPrice: Double? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let pollApi = FlightPollApi.shared
    
    func pollFlightResults(searchId: String) {
        guard !searchId.isEmpty else {
            errorMessage = "Search ID is required to fetch flight results."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("🔄 Starting to poll flight results...")
        print("   Search ID: \(searchId)")
        
        pollApi.pollFlightResults(searchId: searchId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.pollResponse = response
                    self?.flightResults = response.results
                    self?.airlines = response.airlines
                    self?.agencies = response.agencies
                    
                    print("✅ Flight results loaded successfully!")
                    print("   Total results: \(response.results.count)")
                    print("   Price range: \(response.minPrice) - \(response.maxPrice)")
                    print("   Duration range: \(response.minDuration) - \(response.maxDuration) minutes")
                    
                    // Log first few results for debugging
                    for (index, result) in response.results.prefix(3).enumerated() {
                        print("   Result \(index + 1): \(result.id) - Price: \(result.minPrice) - Duration: \(result.totalDuration)m")
                    }
                    
                case .failure(let error):
                    self?.errorMessage = "Failed to fetch flight results: \(error.localizedDescription)"
                    self?.pollResponse = nil
                    self?.flightResults = []
                    self?.airlines = []
                    self?.agencies = []
                    
                    print("❌ Failed to load flight results:")
                    print("   Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func pollWithFilters(searchId: String) {
        guard !searchId.isEmpty else {
            errorMessage = "Search ID is required to fetch flight results."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("🔄 Polling flight results with filters...")
        print("   Search ID: \(searchId)")
        print("   Max Duration: \(maxDuration?.description ?? "nil")")
        print("   Max Stops: \(maxStops?.description ?? "nil")")
        print("   Price Range: \(minPrice?.description ?? "nil") - \(maxPrice?.description ?? "nil")")
        print("   Sort: \(selectedSortBy ?? "nil") \(selectedSortOrder ?? "")")
        
        pollApi.pollFlightResultsWithFilters(
            searchId: searchId,
            durationMax: maxDuration,
            stopCountMax: maxStops,
            priceMin: minPrice,
            priceMax: maxPrice,
            sortBy: selectedSortBy,
            sortOrder: selectedSortOrder
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.pollResponse = response
                    self?.flightResults = response.results
                    self?.airlines = response.airlines
                    self?.agencies = response.agencies
                    
                    print("✅ Filtered flight results loaded!")
                    print("   Filtered results: \(response.results.count)")
                    
                case .failure(let error):
                    self?.errorMessage = "Failed to fetch filtered results: \(error.localizedDescription)"
                    print("❌ Failed to load filtered results: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Helper methods
    func clearResults() {
        pollResponse = nil
        flightResults = []
        airlines = []
        agencies = []
        errorMessage = nil
    }
    
    func resetFilters() {
        selectedSortBy = nil
        selectedSortOrder = nil
        maxDuration = nil
        maxStops = nil
        minPrice = nil
        maxPrice = nil
    }
    
    // Computed properties for UI
    var hasResults: Bool {
        return !flightResults.isEmpty
    }
    
    var resultsCount: Int {
        return flightResults.count
    }
    
    var priceRange: String {
        guard let response = pollResponse else { return "N/A" }
        return "₹\(response.minPrice) - ₹\(response.maxPrice)"
    }
    
    var durationRange: String {
        guard let response = pollResponse else { return "N/A" }
        let minHours = response.minDuration / 60
        let minMinutes = response.minDuration % 60
        let maxHours = response.maxDuration / 60
        let maxMinutes = response.maxDuration % 60
        return "\(minHours)h \(minMinutes)m - \(maxHours)h \(maxMinutes)m"
    }
}
