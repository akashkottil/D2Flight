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

// MARK: - NEW: Recent Search Pair Model
struct RecentSearchPair: Codable, Identifiable {
    let id = UUID()
    let origin: RecentLocation
    let destination: RecentLocation
    let searchDate: Date
    let searchCount: Int
    
    init(origin: Location, destination: Location, searchCount: Int = 1) {
        self.origin = RecentLocation(from: origin)
        self.destination = RecentLocation(from: destination)
        self.searchDate = Date()
        self.searchCount = searchCount
    }
    
    // Create from existing RecentLocations
    init(originLocation: RecentLocation, destinationLocation: RecentLocation, searchCount: Int = 1) {
        self.origin = originLocation
        self.destination = destinationLocation
        self.searchDate = Date()
        self.searchCount = searchCount
    }
}

// MARK: - Recent Locations Manager
class RecentLocationsManager: ObservableObject {
    static let shared = RecentLocationsManager()
    
    @AppStorage("recentLocations") private var recentLocationsData: Data = Data()
    @AppStorage("recentSearchPairs") private var recentSearchPairsData: Data = Data() // NEW
    
    @Published var recentLocations: [RecentLocation] = []
    @Published var recentSearchPairs: [RecentSearchPair] = [] // NEW
    
    private let maxRecentLocations = 8 // Maximum number of recent locations to store
    private let maxRecentSearchPairs = 5 // Maximum number of recent search pairs to store
    
    private init() {
        loadRecentLocations()
        loadRecentSearchPairs() // NEW
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
    
    // MARK: - NEW: Load Recent Search Pairs from AppStorage
    private func loadRecentSearchPairs() {
        do {
            let pairs = try JSONDecoder().decode([RecentSearchPair].self, from: recentSearchPairsData)
            recentSearchPairs = pairs.sorted { $0.searchDate > $1.searchDate }
            print("🔗 Loaded \(recentSearchPairs.count) recent search pairs from storage")
        } catch {
            print("❌ Failed to load recent search pairs: \(error)")
            recentSearchPairs = []
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
    
    // MARK: - NEW: Save Recent Search Pairs to AppStorage
    private func saveRecentSearchPairs() {
        do {
            let data = try JSONEncoder().encode(recentSearchPairs)
            recentSearchPairsData = data
            print("💾 Saved \(recentSearchPairs.count) recent search pairs to storage")
        } catch {
            print("❌ Failed to save recent search pairs: \(error)")
        }
    }
    
    // MARK: - Add Location to Recent Searches (for individual location selection)
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
    
    // MARK: - NEW: Add Complete Search Pair (for completed searches)
    func addSearchPair(origin: Location, destination: Location) {
        // First add individual locations
        addLocation(origin)
        addLocation(destination)
        
        // Check if this exact search pair already exists
        if let existingIndex = recentSearchPairs.firstIndex(where: {
            $0.origin.iataCode == origin.iataCode && $0.destination.iataCode == destination.iataCode
        }) {
            // Update existing search pair
            let existingPair = recentSearchPairs[existingIndex]
            let updatedPair = RecentSearchPair(
                origin: origin,
                destination: destination,
                searchCount: existingPair.searchCount + 1
            )
            recentSearchPairs[existingIndex] = updatedPair
            print("🔄 Updated existing search pair: \(origin.displayName) → \(destination.displayName) (count: \(updatedPair.searchCount))")
        } else {
            // Add new search pair
            let newPair = RecentSearchPair(origin: origin, destination: destination)
            recentSearchPairs.insert(newPair, at: 0)
            print("➕ Added new search pair: \(origin.displayName) → \(destination.displayName)")
        }
        
        // Sort by search date (most recent first)
        recentSearchPairs.sort { $0.searchDate > $1.searchDate }
        
        // Limit the number of recent search pairs
        if recentSearchPairs.count > maxRecentSearchPairs {
            recentSearchPairs = Array(recentSearchPairs.prefix(maxRecentSearchPairs))
            print("✂️ Trimmed recent search pairs to \(maxRecentSearchPairs)")
        }
        
        saveRecentSearchPairs()
    }
    
    // MARK: - Get Recent Locations
    func getRecentLocations() -> [RecentLocation] {
        return recentLocations
    }
    
    // MARK: - UPDATED: Get Last Search Locations (for auto-prefill)
    func getLastSearchLocations() -> (origin: RecentLocation?, destination: RecentLocation?) {
        // Get the most recent complete search pair
        if let lastSearchPair = recentSearchPairs.first {
            print("🎯 Auto-prefill from last search pair: \(lastSearchPair.origin.displayName) → \(lastSearchPair.destination.displayName)")
            return (lastSearchPair.origin, lastSearchPair.destination)
        }
        
        // Fallback: if no search pairs, return nil (don't auto-prefill)
        print("⚠️ No recent search pairs found for auto-prefill")
        return (nil, nil)
    }
    
    // MARK: - Clear Recent Locations
    func clearRecentLocations() {
        recentLocations.removeAll()
        recentSearchPairs.removeAll() // Also clear search pairs
        saveRecentLocations()
        saveRecentSearchPairs()
        print("🗑️ Cleared all recent locations and search pairs")
    }
    
    // MARK: - Remove Specific Location
    func removeLocation(_ location: RecentLocation) {
        recentLocations.removeAll { $0.iataCode == location.iataCode }
        
        // Also remove any search pairs containing this location
        recentSearchPairs.removeAll {
            $0.origin.iataCode == location.iataCode || $0.destination.iataCode == location.iataCode
        }
        
        saveRecentLocations()
        saveRecentSearchPairs()
        print("🗑️ Removed recent location and related search pairs: \(location.displayName)")
    }
    
    // MARK: - Get Popular Locations (by search count)
    func getPopularLocations(limit: Int = 5) -> [RecentLocation] {
        return recentLocations
            .sorted { $0.searchCount > $1.searchCount }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - NEW: Get Recent Search Pairs
    func getRecentSearchPairs() -> [RecentSearchPair] {
        return recentSearchPairs
    }
}
