//
//  FilterViewModel.swift
//  D2Flight
//
//  Created by Assistant on 31/05/25.
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
    
    // Price filters
    @Published var priceRange: ClosedRange<Double> = 0...10000
    
    private var originalAPIMinPrice: Double = 0
    private var originalAPIMaxPrice: Double = 10000
    private var hasAPIDataLoaded: Bool = false
    
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
        departureTimeRange = 0...86400 // ✅ UPDATED: seconds
        arrivalTimeRange = 0...86400 // ✅ UPDATED: seconds
        returnDepartureTimeRange = 0...86400 // ✅ UPDATED: seconds
        returnArrivalTimeRange = 0...86400 // ✅ UPDATED: seconds
        maxDuration = 1440
        selectedClass = .economy
        selectedAirlines = []
        excludedAirlines = []
        maxStops = 3
        priceRange = 0...10000
    }
    
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
    }
    
    // ✅ Helper methods for price filter detection
    private func getAPIMinPrice() -> Double {
        return originalAPIMinPrice
    }
    
    private func getAPIMaxPrice() -> Double {
        return originalAPIMaxPrice
    }
    
    // ✅ FIXED: Update method to store original API prices
    func updatePriceRangeFromAPI(minPrice: Double, maxPrice: Double) {
        // Store original API values for comparison
        originalAPIMinPrice = minPrice
        originalAPIMaxPrice = maxPrice
        hasAPIDataLoaded = true
        
        // Only update if the price range is still at default values
        if priceRange == 0...10000 {
            priceRange = minPrice...maxPrice
            print("🔧 Updated price range from API: ₹\(minPrice) - ₹\(maxPrice)")
        } else {
            print("🔧 Price range already modified by user, keeping: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        }
    }
    
    // MARK: - ✅ UPDATED: Main buildPollRequest method with FIXED time parameter structure
    func buildPollRequest() -> PollRequest {
        var request = PollRequest()
        
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
        }
        
        // ✅ Duration filter - only apply if different from default
        if maxDuration < 1440 {
            request.duration_max = Int(maxDuration)
        }
        
        // ✅ Stop count filter - only apply if different from default
        if maxStops < 3 {
            request.stop_count_max = maxStops
        }
        
        // ✅ FIXED: Smart time range filters - only send what user actually selected
        var timeRanges: [ArrivalDepartureRange] = []
        
        // Process outbound leg
        let hasDepartureFilter = departureTimeRange != 0...86400
        let hasArrivalFilter = arrivalTimeRange != 0...86400
        
        if hasDepartureFilter || hasArrivalFilter {
            // Convert to proper structure for API
            let departure = hasDepartureFilter ?
                TimeRange(min: Int(departureTimeRange.lowerBound), max: Int(departureTimeRange.upperBound)) :
                TimeRange(min: 0, max: 86400)
            
            let arrival = hasArrivalFilter ?
                TimeRange(min: Int(arrivalTimeRange.lowerBound), max: Int(arrivalTimeRange.upperBound)) :
                TimeRange(min: 0, max: 86400)
            
            timeRanges.append(ArrivalDepartureRange(arrival: arrival, departure: departure))
            
            print("🕐 Outbound time filter:")
            if hasDepartureFilter {
                print("   ✓ Departure: \(formatSecondsToTime(Int(departureTimeRange.lowerBound))) - \(formatSecondsToTime(Int(departureTimeRange.upperBound)))")
            }
            if hasArrivalFilter {
                print("   ✓ Arrival: \(formatSecondsToTime(Int(arrivalTimeRange.lowerBound))) - \(formatSecondsToTime(Int(arrivalTimeRange.upperBound)))")
            }
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
                
                // If no outbound filters, add default outbound first
                if timeRanges.isEmpty {
                    timeRanges.append(ArrivalDepartureRange(
                        arrival: TimeRange(min: 0, max: 86400),
                        departure: TimeRange(min: 0, max: 86400)
                    ))
                }
                
                timeRanges.append(ArrivalDepartureRange(arrival: returnArrival, departure: returnDeparture))
                
                print("🕐 Return time filter:")
                if hasReturnDepartureFilter {
                    print("   ✓ Return Departure: \(formatSecondsToTime(Int(returnDepartureTimeRange.lowerBound))) - \(formatSecondsToTime(Int(returnDepartureTimeRange.upperBound)))")
                }
                if hasReturnArrivalFilter {
                    print("   ✓ Return Arrival: \(formatSecondsToTime(Int(returnArrivalTimeRange.lowerBound))) - \(formatSecondsToTime(Int(returnArrivalTimeRange.upperBound)))")
                }
            }
        }
        
        // Only set if we have actual time filters
        if !timeRanges.isEmpty {
            request.arrival_departure_ranges = timeRanges
        }
        
        // ✅ Airline filters - only apply if airlines are selected
        if !selectedAirlines.isEmpty {
            request.iata_codes_include = Array(selectedAirlines)
        }
        
        if !excludedAirlines.isEmpty {
            request.iata_codes_exclude = Array(excludedAirlines)
        }
        
        // ✅ SIMPLIFIED: Price filters - apply if user has modified from API defaults
        if hasAPIDataLoaded {
            // Use simplified price filter detection as recommended
            if priceRange != originalAPIMinPrice...originalAPIMaxPrice {
                request.price_min = Int(priceRange.lowerBound)
                request.price_max = Int(priceRange.upperBound)
                
                print("🔧 Applying price filter:")
                print("   API Range: ₹\(originalAPIMinPrice) - ₹\(originalAPIMaxPrice)")
                print("   User Range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
                print("   Price Min: \(request.price_min!)")
                print("   Price Max: \(request.price_max!)")
            }
        }
        
        // ✅ Debug logging
        print("🔧 Built PollRequest:")
        print("   Sort: \(request.sort_by ?? "none") \(request.sort_order ?? "")")
        print("   Max Duration: \(request.duration_max ?? -1)")
        print("   Max Stops: \(request.stop_count_max ?? -1)")
        print("   Selected Airlines: \(selectedAirlines.count)")
        print("   Time Filters: \(!timeRanges.isEmpty)")
        if !timeRanges.isEmpty {
            for (index, range) in timeRanges.enumerated() {
                print("     Range \(index): Departure \(range.departure.min)-\(range.departure.max), Arrival \(range.arrival.min)-\(range.arrival.max)")
            }
        }
        print("   Price Min: \(request.price_min?.description ?? "not set")")
        print("   Price Max: \(request.price_max?.description ?? "not set")")
        print("   Has Filters: \(request.hasFilters())")
        
        return request
    }
    
    // ✅ Helper function to format seconds to time string for debugging
    private func formatSecondsToTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        return String(format: "%02d:%02d", hours, mins)
    }
    
    func clearFilters() {
        selectedSortOption = .best
        departureTimeRange = 0...86400 // ✅ UPDATED: seconds
        arrivalTimeRange = 0...86400 // ✅ UPDATED: seconds
        returnDepartureTimeRange = 0...86400 // ✅ UPDATED: seconds
        returnArrivalTimeRange = 0...86400 // ✅ UPDATED: seconds
        maxDuration = 1440
        selectedClass = .economy
        selectedAirlines.removeAll()
        excludedAirlines.removeAll()
        maxStops = 3
        
        // Reset price range to API values if available
        if hasAPIDataLoaded {
            priceRange = originalAPIMinPrice...originalAPIMaxPrice
        } else {
            priceRange = 0...10000
        }
        
        print("🔧 Filters cleared, price range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
    }
    
    private func getCurrentPollData() -> PollResponse? {
        return nil
    }
    
    // ✅ UPDATED: Helper method to check if any filters are active
    func hasActiveFilters() -> Bool {
        return selectedSortOption != .best ||
               departureTimeRange != 0...86400 || // ✅ UPDATED: seconds
               arrivalTimeRange != 0...86400 || // ✅ UPDATED: seconds
               returnDepartureTimeRange != 0...86400 || // ✅ UPDATED: seconds
               returnArrivalTimeRange != 0...86400 || // ✅ UPDATED: seconds
               maxDuration < 1440 ||
               !selectedAirlines.isEmpty ||
               !excludedAirlines.isEmpty ||
               maxStops < 3 ||
               (hasAPIDataLoaded && priceRange != originalAPIMinPrice...originalAPIMaxPrice)
    }
}
