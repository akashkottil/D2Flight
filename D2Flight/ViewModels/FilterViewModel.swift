//
//  FilterViewModel.swift
//  D2Flight
//
//  Created by Assistant on 31/05/25.
//

import Foundation
import SwiftUI

class FilterViewModel: ObservableObject {
    // Sort options
    @Published var selectedSortOption: SortOption = .best
    
    // Time filters (in minutes from midnight)
    @Published var departureTimeRange: ClosedRange<Double> = 0...1440 // 24 hours in minutes
    @Published var returnTimeRange: ClosedRange<Double> = 0...1440
    
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
    
    // Trip type for conditional filtering
    var isRoundTrip: Bool = false
    
    init() {
        loadDefaultFilters()
    }
    
    private func loadDefaultFilters() {
        // Set default values
        selectedSortOption = .best
        departureTimeRange = 0...1440
        returnTimeRange = 0...1440
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
                price: 350 // Default price, could be calculated from results
            )
        }
        print("✈️ Updated available airlines: \(availableAirlines.count)")
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
    
    // MARK: - Main buildPollRequest method
    func buildPollRequest() -> PollRequest {
        var request = PollRequest()
        
        print("🔧 Building PollRequest with user selections:")
        
        // ✅ Sort options - only if changed from default
        if selectedSortOption != .best {
            switch selectedSortOption {
            case .best:
                break // Don't send anything for default
            case .cheapest:
                request.sort_by = "price"
                request.sort_order = "asc"
                print("   Sort: price asc (cheapest)")
            case .quickest:
                request.sort_by = "duration"
                request.sort_order = "asc"
                print("   Sort: duration asc (quickest)")
            case .earliest:
                request.sort_by = "departure"
                request.sort_order = "asc"
                print("   Sort: departure asc (earliest)")
            }
        }
        
        // ✅ Duration filter - only if user changed it
        if maxDuration < 1440 {
            request.duration_max = Int(maxDuration)
            print("   Duration max: \(Int(maxDuration)) minutes")
        }
        
        // ✅ Stop count filter - only if user changed it
        if maxStops < 3 {
            request.stop_count_max = maxStops
            print("   Max stops: \(maxStops)")
        }
        
        // ✅ Time range filters - only if user modified them
        var timeRanges: [ArrivalDepartureRange] = []
        var hasTimeFilters = false
        
        // Departure time filter
        if departureTimeRange != 0...1440 {
            hasTimeFilters = true
            let range = ArrivalDepartureRange(
                arrival: TimeRange(
                    min: Int(departureTimeRange.lowerBound),
                    max: Int(departureTimeRange.upperBound)
                ),
                departure: TimeRange(
                    min: Int(departureTimeRange.lowerBound),
                    max: Int(departureTimeRange.upperBound)
                )
            )
            timeRanges.append(range)
            print("   Departure time: \(Int(departureTimeRange.lowerBound))-\(Int(departureTimeRange.upperBound))")
        }
        
        // Return time filter (if round trip and modified)
        if isRoundTrip && returnTimeRange != 0...1440 {
            hasTimeFilters = true
            let range = ArrivalDepartureRange(
                arrival: TimeRange(
                    min: Int(returnTimeRange.lowerBound),
                    max: Int(returnTimeRange.upperBound)
                ),
                departure: TimeRange(
                    min: Int(returnTimeRange.lowerBound),
                    max: Int(returnTimeRange.upperBound)
                )
            )
            timeRanges.append(range)
            print("   Return time: \(Int(returnTimeRange.lowerBound))-\(Int(returnTimeRange.upperBound))")
        }
        
        if hasTimeFilters {
            request.arrival_departure_ranges = timeRanges
        }
        
        // ✅ Airline filters - only if user selected airlines
        if !selectedAirlines.isEmpty {
            request.iata_codes_include = Array(selectedAirlines)
            print("   Selected airlines: \(selectedAirlines)")
        }
        
        if !excludedAirlines.isEmpty {
            request.iata_codes_exclude = Array(excludedAirlines)
            print("   Excluded airlines: \(excludedAirlines)")
        }
        
        // ✅ Price filters - only if user modified them from defaults
        // Use a more flexible approach for price comparison
        if priceRange.lowerBound > 0 {
            request.price_min = Int(priceRange.lowerBound)
            print("   Price min: \(Int(priceRange.lowerBound))")
        }
        
        if priceRange.upperBound < 10000 {
            request.price_max = Int(priceRange.upperBound)
            print("   Price max: \(Int(priceRange.upperBound))")
        }
        
        print("🔧 PollRequest built with \(request.hasFilters() ? "filters" : "no filters")")
        return request
    }
    
    // Helper method to check if any filters are active
    func hasActiveFilters() -> Bool {
        return selectedSortOption != .best ||
               departureTimeRange != 0...1440 ||
               returnTimeRange != 0...1440 ||
               maxDuration < 1440 ||
               !selectedAirlines.isEmpty ||
               !excludedAirlines.isEmpty ||
               maxStops < 3 ||
               priceRange != 0...10000
    }
}

// MARK: - Supporting Models
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
