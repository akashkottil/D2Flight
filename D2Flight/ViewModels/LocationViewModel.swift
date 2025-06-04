import Foundation
import Combine

class LocationViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var locations: [Location] = []
    @Published var recentLocations: [RecentLocation] = []
    @Published var isLoading: Bool = false
    @Published var isSelectingOrigin: Bool = true
    @Published var errorMessage: String? = nil
    @Published var showingRecentLocations: Bool = true // NEW: Track if showing recent vs autocomplete
    
    private var cancellables = Set<AnyCancellable>()
    private let locationApi = LocationApi.shared
    private let recentLocationsManager = RecentLocationsManager.shared
    
    init() {
        setupSearchDebounce()
        loadRecentLocations()
        
        // Listen to recent locations updates
        recentLocationsManager.$recentLocations
            .receive(on: DispatchQueue.main)
            .assign(to: \.recentLocations, on: self)
            .store(in: &cancellables)
    }
    
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.handleSearchTextChange(searchText)
            }
            .store(in: &cancellables)
    }
    
    // NEW: Handle search text changes - show recent or autocomplete
    private func handleSearchTextChange(_ searchText: String) {
        let trimmedText = searchText.trimmingCharacters(in: .whitespaces)
        
        if trimmedText.isEmpty {
            // Show recent locations when search is empty
            showRecentLocations()
        } else {
            // Show autocomplete results when typing
            searchLocations(query: trimmedText)
        }
    }
    
    // NEW: Show recent locations
    private func showRecentLocations() {
        showingRecentLocations = true
        locations = [] // Clear autocomplete results
        // recentLocations will be updated automatically via the @Published property
        print("📍 Showing \(recentLocations.count) recent locations")
    }
    
    // UPDATED: Search locations (autocomplete)
    func searchLocations(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            showRecentLocations()
            return
        }
        
        showingRecentLocations = false
        isLoading = true
        errorMessage = nil
        
        print("🔍 Searching autocomplete for: '\(query)'")
        
        locationApi.searchLocations(query: query) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    self?.locations = response.data
                    print("✅ Found \(response.data.count) autocomplete results")
                case .failure(let error):
                    self?.errorMessage = "Failed to fetch locations: \(error.localizedDescription)"
                    self?.locations = []
                    print("❌ Autocomplete search failed: \(error)")
                }
            }
        }
    }
    
    // NEW: Load recent locations
    private func loadRecentLocations() {
        recentLocations = recentLocationsManager.getRecentLocations()
        print("📂 Loaded \(recentLocations.count) recent locations in ViewModel")
    }
    
    // UPDATED: Select location - now handles both recent and autocomplete
    func selectLocation(_ location: Location) -> Bool {
        // Add to recent locations
        recentLocationsManager.addLocation(location)
        print("📌 Added location to recent searches: \(location.displayName)")
        
        if isSelectingOrigin {
            // Move to destination selection
            isSelectingOrigin = false
            searchText = ""
            showRecentLocations() // Show recent locations for destination selection
            return false // Don't close yet
        } else {
            // Destination selected, close the view
            return true // Close the view
        }
    }
    
    // NEW: Select recent location (convenience method)
    func selectRecentLocation(_ recentLocation: RecentLocation) -> Bool {
        let location = recentLocation.toLocation()
        return selectLocation(location)
    }
    
    func resetToOriginSelection() {
        isSelectingOrigin = true
        searchText = ""
        showRecentLocations()
        errorMessage = nil
    }
    
    func getCurrentPlaceholder() -> String {
        return isSelectingOrigin ? "Enter Departure" : "Enter Destination"
    }
    
    func getCurrentTitle() -> String {
        return isSelectingOrigin ? "Select departure location" : "Select destination location"
    }
    
    // NEW: Get section title for UI
    func getSectionTitle() -> String {
        if showingRecentLocations && !recentLocations.isEmpty {
            return "Recent Searches"
        } else if !showingRecentLocations && !locations.isEmpty {
            return "Search Results"
        } else {
            return ""
        }
    }
    
    // NEW: Check if should show recent locations section
    var shouldShowRecentLocations: Bool {
        return showingRecentLocations && !recentLocations.isEmpty
    }
    
    // NEW: Check if should show autocomplete section
    var shouldShowAutocomplete: Bool {
        return !showingRecentLocations && !locations.isEmpty
    }
    
    // NEW: Check if should show empty state
    var shouldShowEmptyState: Bool {
        if showingRecentLocations {
            return recentLocations.isEmpty
        } else {
            return !searchText.isEmpty && locations.isEmpty && !isLoading
        }
    }
    
    // NEW: Get empty state message
    func getEmptyStateMessage() -> (title: String, subtitle: String) {
        if showingRecentLocations {
            return ("No recent searches", "Your recent flight searches will appear here")
        } else {
            return ("No locations found", "Try searching with a different keyword")
        }
    }
}
