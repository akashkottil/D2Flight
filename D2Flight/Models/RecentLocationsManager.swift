import Foundation
import SwiftUI

// MARK: - Recent Location Model
struct RecentLocation: Codable, Identifiable, Hashable {
    let id = UUID()
    let iataCode: String
    let airportName: String
    let displayName: String
    let cityName: String
    let countryName: String
    let type: String
    let searchCount: Int
    let lastSearched: Date
    
    // Initialize from Location model
    init(from location: Location, searchCount: Int = 1) {
        self.iataCode = location.iataCode
        self.airportName = location.airportName
        self.displayName = location.displayName
        self.cityName = location.cityName
        self.countryName = location.countryName
        self.type = location.type
        self.searchCount = searchCount
        self.lastSearched = Date()
    }
    
    // Convert back to Location for compatibility
    func toLocation() -> Location {
        return Location(
            iataCode: self.iataCode,
            airportName: self.airportName,
            type: self.type,
            displayName: self.displayName,
            cityName: self.cityName,
            countryName: self.countryName,
            countryCode: "", // We don't store this in recent locations
            imageUrl: "", // We don't store this in recent locations
            coordinates: Coordinates(latitude: "0", longitude: "0") // We don't store this in recent locations
        )
    }
    
    // For Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(iataCode)
    }
    
    static func == (lhs: RecentLocation, rhs: RecentLocation) -> Bool {
        return lhs.iataCode == rhs.iataCode
    }
}

// MARK: - Recent Locations Manager
class RecentLocationsManager: ObservableObject {
    static let shared = RecentLocationsManager()
    
    @AppStorage("recentLocations") private var recentLocationsData: Data = Data()
    @Published var recentLocations: [RecentLocation] = []
    
    private let maxRecentLocations = 8 // Maximum number of recent locations to store
    
    private init() {
        loadRecentLocations()
    }
    
    // MARK: - Load Recent Locations from AppStorage
    private func loadRecentLocations() {
        do {
            let locations = try JSONDecoder().decode([RecentLocation].self, from: recentLocationsData)
            recentLocations = locations.sorted { $0.lastSearched > $1.lastSearched }
            print("📍 Loaded \(recentLocations.count) recent locations from storage")
        } catch {
            print("❌ Failed to load recent locations: \(error)")
            recentLocations = []
        }
    }
    
    // MARK: - Save Recent Locations to AppStorage
    private func saveRecentLocations() {
        do {
            let data = try JSONEncoder().encode(recentLocations)
            recentLocationsData = data
            print("💾 Saved \(recentLocations.count) recent locations to storage")
        } catch {
            print("❌ Failed to save recent locations: \(error)")
        }
    }
    
    // MARK: - Add Location to Recent Searches
    func addLocation(_ location: Location) {
        // Check if location already exists
        if let existingIndex = recentLocations.firstIndex(where: { $0.iataCode == location.iataCode }) {
            // Update existing location with new search count and date
            let existingLocation = recentLocations[existingIndex]
            let updatedLocation = RecentLocation(from: location, searchCount: existingLocation.searchCount + 1)
            recentLocations[existingIndex] = updatedLocation
            print("🔄 Updated existing recent location: \(location.displayName) (count: \(updatedLocation.searchCount))")
        } else {
            // Add new location
            let newLocation = RecentLocation(from: location)
            recentLocations.insert(newLocation, at: 0)
            print("➕ Added new recent location: \(location.displayName)")
        }
        
        // Sort by last searched date (most recent first)
        recentLocations.sort { $0.lastSearched > $1.lastSearched }
        
        // Limit the number of recent locations
        if recentLocations.count > maxRecentLocations {
            recentLocations = Array(recentLocations.prefix(maxRecentLocations))
            print("✂️ Trimmed recent locations to \(maxRecentLocations)")
        }
        
        saveRecentLocations()
    }
    
    // MARK: - Get Recent Locations
    func getRecentLocations() -> [RecentLocation] {
        return recentLocations
    }
    
    // MARK: - Get Last Search Locations (for auto-prefill)
    func getLastSearchLocations() -> (origin: RecentLocation?, destination: RecentLocation?) {
        // Get the two most recent locations
        let sortedByDate = recentLocations.sorted { $0.lastSearched > $1.lastSearched }
        
        let origin = sortedByDate.first
        let destination = sortedByDate.count > 1 ? sortedByDate[1] : nil
        
        return (origin, destination)
    }
    
    // MARK: - Clear Recent Locations
    func clearRecentLocations() {
        recentLocations.removeAll()
        saveRecentLocations()
        print("🗑️ Cleared all recent locations")
    }
    
    // MARK: - Remove Specific Location
    func removeLocation(_ location: RecentLocation) {
        recentLocations.removeAll { $0.iataCode == location.iataCode }
        saveRecentLocations()
        print("🗑️ Removed recent location: \(location.displayName)")
    }
    
    // MARK: - Get Popular Locations (by search count)
    func getPopularLocations(limit: Int = 5) -> [RecentLocation] {
        return recentLocations
            .sorted { $0.searchCount > $1.searchCount }
            .prefix(limit)
            .map { $0 }
    }
}
