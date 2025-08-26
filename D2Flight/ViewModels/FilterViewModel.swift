//
//  FilterViewModel.swift
//  D2Flight
//
//  Enhanced with proper price filtering support
//

import Foundation
import SwiftUI

// MARK: - Supporting Models (defined first to avoid scope issues)
enum SortOption: String, CaseIterable {
    case best = "Best"
    case cheapest = "Cheapest"
    case quickest = "Quickest"
    case earliest = "Earliest"
    
    var displayName: String {
        return self.rawValue
    }
}

struct AirlineOption: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let logo: String
    let price: Double
}

class FilterViewModel: ObservableObject {
    // Sort options
    @Published var selectedSortOption: SortOption = .best
    
    // ✅ UPDATED: Separate time filters for departure and arrival (in seconds)
    @Published var departureTimeRange: ClosedRange<Double> = 0...86400 // 24 hours in seconds
    @Published var arrivalTimeRange: ClosedRange<Double> = 0...86400 // 24 hours in seconds
    @Published var returnDepartureTimeRange: ClosedRange<Double> = 0...86400
    @Published var returnArrivalTimeRange: ClosedRange<Double> = 0...86400
    
    // Duration filters (in minutes)
    @Published var maxDuration: Double = 1440 // 24 hours
    @Published var departureStopoverRange: ClosedRange<Double> = 0...1440
    @Published var departureLegRange: ClosedRange<Double> = 0...1440
    @Published var returnStopoverRange: ClosedRange<Double> = 0...1440
    @Published var returnLegRange: ClosedRange<Double> = 0...1440
    
    // Class filter
    @Published var selectedClass: TravelClass = .economy
    
    // Airline filters
    @Published var selectedAirlines: Set<String> = []
    @Published var excludedAirlines: Set<String> = []
    @Published var availableAirlines: [AirlineOption] = []
    
    // Stop count filter
    @Published var maxStops: Int = 3
    
    // ✅ FIXED: Price filters with proper API-based initialization
    @Published var priceRange: ClosedRange<Double> = 0...10000 {
        didSet {
            print("🔧 Price range changed: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        }
    }
    
    // ✅ NEW: Store API price data
    @Published private(set) var apiMinPrice: Double = 0
    @Published private(set) var apiMaxPrice: Double = 10000
    @Published private(set) var hasAPIDataLoaded: Bool = false
    @Published private(set) var userHasModifiedPrice: Bool = false
    
    // Trip type for conditional filtering
    var isRoundTrip: Bool = false
    
    @Published var cachedSortedAirlinesForSheet: [AirlineOption] = []
    
    init() {
        loadDefaultFilters()
    }
    
    func cacheSortedAirlinesForSheet() {
        cachedSortedAirlinesForSheet = getSortedAirlinesForSheet()
    }
    
    private func loadDefaultFilters() {
        // Set default values
        selectedSortOption = .best
        departureTimeRange = 0...86400
        arrivalTimeRange = 0...86400
        returnDepartureTimeRange = 0...86400
        returnArrivalTimeRange = 0...86400
        maxDuration = 1440
        selectedClass = .economy
        selectedAirlines = []
        excludedAirlines = []
        maxStops = 3
        // ✅ Don't set priceRange here - wait for API data
        userHasModifiedPrice = false
        hasAPIDataLoaded = false
    }
    
    // MARK: - ✅ ENHANCED: Price Filter Methods
    
    /// Update price range when API data is received
    func updatePriceRangeFromAPI(minPrice: Double, maxPrice: Double) {
        print("🔧 Setting price range from API:")
        print("   API Min Price: ₹\(minPrice)")
        print("   API Max Price: ₹\(maxPrice)")
        print("   Current Price Range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        print("   Has API Data Loaded: \(hasAPIDataLoaded)")
        print("   User Has Modified: \(userHasModifiedPrice)")
        
        // ✅ CRITICAL: Store API values
        apiMinPrice = minPrice
        apiMaxPrice = maxPrice
        hasAPIDataLoaded = true
        
        // ✅ FIXED: Only update the range if user hasn't manually modified it
        if !userHasModifiedPrice {
            priceRange = minPrice...maxPrice
            print("   ✅ Updated price range to API values: ₹\(minPrice) - ₹\(maxPrice)")
        } else {
            print("   ⚠️ Price range already modified by user, keeping current values")
        }
        
        print("   Final state:")
        print("     hasAPIDataLoaded: \(hasAPIDataLoaded)")
        print("     userHasModifiedPrice: \(userHasModifiedPrice)")
        print("     shouldApplyPriceFilter: \(shouldApplyPriceFilter())")
    }
    
    /// Track when user manually modifies price range
    func updatePriceRange(newRange: ClosedRange<Double>) {
        print("🔧 User modifying price range:")
        print("   Previous: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        print("   New: ₹\(newRange.lowerBound) - ₹\(newRange.upperBound)")
        
        priceRange = newRange
        
        // ✅ Mark that user has modified the price
        userHasModifiedPrice = true
        
        print("   ✅ Price range updated and marked as user-modified")
        print("   shouldApplyPriceFilter: \(shouldApplyPriceFilter())")
    }
    
    /// Check if price filter should be applied to API request
    func shouldApplyPriceFilter() -> Bool {
        guard hasAPIDataLoaded else {
            print("🔧 Price filter check: No API data loaded")
            return false
        }
        
        let apiRange = apiMinPrice...apiMaxPrice
        let hasChanged = priceRange != apiRange
        
        print("🔧 Price filter check:")
        print("   API Range: ₹\(apiMinPrice) - ₹\(apiMaxPrice)")
        print("   Current Range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        print("   User Modified: \(userHasModifiedPrice)")
        print("   Has Changed: \(hasChanged)")
        print("   Should Apply: \(hasChanged && userHasModifiedPrice)")
        
        return hasChanged && userHasModifiedPrice
    }
    
    /// Check if price filter is currently active for UI
    func isPriceFilterActive() -> Bool {
        return shouldApplyPriceFilter()
    }
    
    /// Get display text for price filter button
    func getPriceFilterDisplayText() -> String {
        if isPriceFilterActive() {
            return "₹\(formatPriceValue(priceRange.lowerBound)) - ₹\(formatPriceValue(priceRange.upperBound))"
        } else {
            return "Price"
        }
    }
    
    /// Reset price filter to API defaults
    func resetPriceFilter() {
        print("🗑️ Resetting price filter:")
        print("   Previous range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        
        if hasAPIDataLoaded {
            priceRange = apiMinPrice...apiMaxPrice
            print("   ✅ Reset to API values: ₹\(apiMinPrice) - ₹\(apiMaxPrice)")
        } else {
            priceRange = 0...10000
            print("   ✅ Reset to default: ₹0 - ₹10000 (no API data)")
        }
        
        // Clear user modification flag
        userHasModifiedPrice = false
        print("   ✅ Cleared user modification flag")
    }
    
    private func formatPriceValue(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        
        return formatter.string(from: NSNumber(value: Int(price))) ?? "\(Int(price))"
    }
    
    // MARK: - Airlines Management
    
    func updateAvailableAirlines(_ airlines: [Airline]) {
        availableAirlines = airlines.map { airline in
            AirlineOption(
                code: airline.airlineIata,
                name: airline.airlineName,
                logo: airline.airlineLogo,
                price: 350 // Default price, will be updated with real prices
            )
        }
        print("✈️ Updated available airlines: \(availableAirlines.count)")
    }
    
    func getSortedAirlinesForSheet() -> [AirlineOption] {
        return availableAirlines.sorted { airline1, airline2 in
            let isSelected1 = selectedAirlines.contains(airline1.code)
            let isSelected2 = selectedAirlines.contains(airline2.code)
            
            if isSelected1 && !isSelected2 {
                return true // Selected airlines come first
            } else if !isSelected1 && isSelected2 {
                return false // Non-selected airlines come after
            } else {
                return airline1.name < airline2.name // Alphabetical within each group
            }
        }
    }
    
    func toggleAirlineSelection(_ airlineCode: String) {
        if selectedAirlines.contains(airlineCode) {
            selectedAirlines.remove(airlineCode)
        } else {
            selectedAirlines.insert(airlineCode)
        }
    }
    
    func selectAllAirlines() {
        selectedAirlines = Set(availableAirlines.map { $0.code })
    }
    
    func clearAllAirlines() {
        selectedAirlines.removeAll()
    }
    
    func resetFilters() {
        loadDefaultFilters()
        resetPriceFilter()
    }
    
    // MARK: - ✅ UPDATED: Main buildPollRequest method with FIXED price filter support
    func buildPollRequest() -> PollRequest {
        var request = PollRequest()
        
        print("\n🔧 ===== BUILDING POLL REQUEST =====")
        
        // ✅ Sort options - always apply if not default
        if selectedSortOption != .best {
            switch selectedSortOption {
            case .best:
                request.sort_by = "quality"
                request.sort_order = "desc"
            case .cheapest:
                request.sort_by = "price"
                request.sort_order = "asc"
            case .quickest:
                request.sort_by = "duration"
                request.sort_order = "asc"
            case .earliest:
                request.sort_by = "departure"
                request.sort_order = "asc"
            }
            print("   ✓ Sort: \(request.sort_by!) \(request.sort_order!)")
        }
        
        // ✅ Duration filter - only apply if different from default
        if maxDuration < 1440 {
            request.duration_max = Int(maxDuration)
            print("   ✓ Duration: ≤ \(Int(maxDuration)) minutes")
        }
        
        // ✅ Stop count filter - only apply if different from default
        if maxStops < 3 {
            request.stop_count_max = maxStops
            print("   ✓ Stops: ≤ \(maxStops)")
        }
        
        // ✅ Time range filters
        var timeRanges: [ArrivalDepartureRange] = []
        
        // Process outbound leg
        let hasDepartureFilter = departureTimeRange != 0...86400
        let hasArrivalFilter = arrivalTimeRange != 0...86400
        
        if hasDepartureFilter || hasArrivalFilter {
            let departure = hasDepartureFilter ?
                TimeRange(min: Int(departureTimeRange.lowerBound), max: Int(departureTimeRange.upperBound)) :
                TimeRange(min: 0, max: 86400)
            
            let arrival = hasArrivalFilter ?
                TimeRange(min: Int(arrivalTimeRange.lowerBound), max: Int(arrivalTimeRange.upperBound)) :
                TimeRange(min: 0, max: 86400)
            
            timeRanges.append(ArrivalDepartureRange(arrival: arrival, departure: departure))
            print("   ✓ Outbound time filters applied")
        }
        
        // Process return leg (if round trip)
        if isRoundTrip {
            let hasReturnDepartureFilter = returnDepartureTimeRange != 0...86400
            let hasReturnArrivalFilter = returnArrivalTimeRange != 0...86400
            
            if hasReturnDepartureFilter || hasReturnArrivalFilter {
                let returnDeparture = hasReturnDepartureFilter ?
                    TimeRange(min: Int(returnDepartureTimeRange.lowerBound), max: Int(returnDepartureTimeRange.upperBound)) :
                    TimeRange(min: 0, max: 86400)
                
                let returnArrival = hasReturnArrivalFilter ?
                    TimeRange(min: Int(returnArrivalTimeRange.lowerBound), max: Int(returnArrivalTimeRange.upperBound)) :
                    TimeRange(min: 0, max: 86400)
                
                if timeRanges.isEmpty {
                    timeRanges.append(ArrivalDepartureRange(
                        arrival: TimeRange(min: 0, max: 86400),
                        departure: TimeRange(min: 0, max: 86400)
                    ))
                }
                
                timeRanges.append(ArrivalDepartureRange(arrival: returnArrival, departure: returnDeparture))
                print("   ✓ Return time filters applied")
            }
        }
        
        if !timeRanges.isEmpty {
            request.arrival_departure_ranges = timeRanges
        }
        
        // ✅ Airline filters
        if !selectedAirlines.isEmpty {
            request.iata_codes_include = Array(selectedAirlines)
            print("   ✓ Include Airlines: \(selectedAirlines.joined(separator: ", "))")
        }
        
        if !excludedAirlines.isEmpty {
            request.iata_codes_exclude = Array(excludedAirlines)
            print("   ✓ Exclude Airlines: \(excludedAirlines.joined(separator: ", "))")
        }
        
        // ✅ CRITICAL: Enhanced price filters with proper logic
        if shouldApplyPriceFilter() {
            request.price_min = Int(priceRange.lowerBound)
            request.price_max = Int(priceRange.upperBound)
            
            print("   ✅ PRICE FILTER APPLIED:")
            print("     price_min: \(request.price_min!)")
            print("     price_max: \(request.price_max!)")
            print("     Range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        } else {
            print("   ❌ Price filter NOT applied")
            if !hasAPIDataLoaded {
                print("     Reason: No API data loaded yet")
            } else if !userHasModifiedPrice {
                print("     Reason: User hasn't modified price range")
            } else {
                print("     Reason: Price range matches API defaults")
            }
        }
        
        print("🔧 Built PollRequest with \(request.hasFilters() ? "filters" : "no filters")")
        print("🔧 ===== END BUILDING POLL REQUEST =====\n")
        
        return request
    }
    
    func clearFilters() {
        selectedSortOption = .best
        departureTimeRange = 0...86400
        arrivalTimeRange = 0...86400
        returnDepartureTimeRange = 0...86400
        returnArrivalTimeRange = 0...86400
        maxDuration = 1440
        selectedClass = .economy
        selectedAirlines.removeAll()
        excludedAirlines.removeAll()
        maxStops = 3
        
        // Reset price filter properly
        resetPriceFilter()
        
        print("🔧 All filters cleared including price modifications")
    }
    
    // ✅ UPDATED: Helper method to check if any filters are active
    func hasActiveFilters() -> Bool {
        return selectedSortOption != .best ||
               departureTimeRange != 0...86400 ||
               arrivalTimeRange != 0...86400 ||
               returnDepartureTimeRange != 0...86400 ||
               returnArrivalTimeRange != 0...86400 ||
               maxDuration < 1440 ||
               !selectedAirlines.isEmpty ||
               !excludedAirlines.isEmpty ||
               maxStops < 3 ||
               isPriceFilterActive()
    }
    
    func getLocalizedAirlineFilterDisplayText() -> String {
        if selectedAirlines.isEmpty {
            return "airlines".localized
        } else if selectedAirlines.count == 1,
                  let airline = getAirline(by: selectedAirlines.first!) {
            return airline.name
        } else {
            return "\(selectedAirlines.count) \("airlines".localized)"
        }
    }

    /// Get localized price filter display text
    func getLocalizedPriceFilterDisplayText() -> String {
        if isPriceFilterActive() {
            return "₹\(formatPriceValue(priceRange.lowerBound)) - ₹\(formatPriceValue(priceRange.upperBound))"
        } else {
            return "price".localized
        }
    }
}

extension SortOption {
    var localizedDisplayName: String {
        switch self {
        case .best:
            return "best".localized
        case .cheapest:
            return "cheapest".localized
        case .quickest:
            return "quickest".localized
        case .earliest:
            return "earliest".localized
        }
    }
}
