import Foundation
import Combine

class LocationViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var locations: [Location] = []
    @Published var isLoading: Bool = false
    @Published var isSelectingOrigin: Bool = true
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let locationApi = LocationApi.shared
    
    init() {
        setupSearchDebounce()
    }
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.searchLocations(query: searchText)
            }
            .store(in: &cancellables)
    }
    
    func searchLocations(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            locations = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        locationApi.searchLocations(query: query) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.locations = response.data
                case .failure(let error):
                    self?.errorMessage = "Failed to fetch locations: \(error.localizedDescription)"
                    self?.locations = []
                }
            }
        }
    }
    
    func selectLocation(_ location: Location) -> Bool {
        if isSelectingOrigin {
            // Move to destination selection
            isSelectingOrigin = false
            searchText = ""
            return false // Don't close yet
        } else {
            // Destination selected, close the view
            return true // Close the view
        }
    }
    
    func resetToOriginSelection() {
        isSelectingOrigin = true
        searchText = ""
        locations = []
    }
    
    func getCurrentPlaceholder() -> String {
        return isSelectingOrigin ? "Enter Departure" : "Enter Destination"
    }
    
    func getCurrentTitle() -> String {
        return isSelectingOrigin ? "Select departure location" : "Select destination location"
    }
}
