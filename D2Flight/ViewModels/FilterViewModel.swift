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
    
    func buildPollRequest() -> PollRequest {
        var request = PollRequest()
        
        // Sort options
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
        
        // Duration filter
        if maxDuration < 1440 {
            request.duration_max = Int(maxDuration)
        }
        
        // Stop count filter
        if maxStops < 3 {
            request.stop_count_max = maxStops
        }
        
        // Time range filters
        if departureTimeRange != 0...1440 || returnTimeRange != 0...1440 {
            var timeRanges: [ArrivalDepartureRange] = []
            
            // Departure leg time range
            timeRanges.append(ArrivalDepartureRange(
                arrival: TimeRange(min: Int(departureTimeRange.lowerBound * 60), max: Int(departureTimeRange.upperBound * 60)),
                departure: TimeRange(min: Int(departureTimeRange.lowerBound * 60), max: Int(departureTimeRange.upperBound * 60))
            ))
            
            // Return leg time range (if round trip)
            if isRoundTrip {
                timeRanges.append(ArrivalDepartureRange(
                    arrival: TimeRange(min: Int(returnTimeRange.lowerBound * 60), max: Int(returnTimeRange.upperBound * 60)),
                    departure: TimeRange(min: Int(returnTimeRange.lowerBound * 60), max: Int(returnTimeRange.upperBound * 60))
                ))
            }
            
            request.arrival_departure_ranges = timeRanges
        }
        
        // Airline filters
        if !selectedAirlines.isEmpty {
            request.iata_codes_include = Array(selectedAirlines)
        }
        
        if !excludedAirlines.isEmpty {
            request.iata_codes_exclude = Array(excludedAirlines)
        }
        
        // Price filters
        if priceRange.lowerBound > 0 {
            request.price_min = Int(priceRange.lowerBound)
        }
        
        if priceRange.upperBound < 10000 {
            request.price_max = Int(priceRange.upperBound)
        }
        
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
