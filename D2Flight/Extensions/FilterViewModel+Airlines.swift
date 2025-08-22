// FilterViewModel+Airlines.swift
// Extension to handle airline filtering functionality

import Foundation
import SwiftUI

extension FilterViewModel {
    
    // MARK: - Airline Management
    
    /// Update available airlines with real pricing data from poll response
    func updateAvailableAirlines(from pollResponse: PollResponse) {
        print("🔧 Updating available airlines from poll response")
        print("   Airlines in response: \(pollResponse.airlines.count)")
        
        // Create a map of airline codes to minimum prices from flight results
        var airlinePrices: [String: Double] = [:]
        
        // Calculate minimum price for each airline from actual flight results
        for flight in pollResponse.results {
            for leg in flight.legs {
                for segment in leg.segments {
                    let airlineCode = segment.airlineIata
                    let flightPrice = flight.min_price
                    
                    if let existingPrice = airlinePrices[airlineCode] {
                        airlinePrices[airlineCode] = min(existingPrice, flightPrice)
                    } else {
                        airlinePrices[airlineCode] = flightPrice
                    }
                }
            }
        }
        
        // Create AirlineOption objects with real pricing
        let newAirlines = pollResponse.airlines.map { airline in
            AirlineOption(
                code: airline.airlineIata,
                name: airline.airlineName,
                logo: airline.airlineLogo,
                price: airlinePrices[airline.airlineIata] ?? 0
            )
        }
        
        // Update the available airlines
        availableAirlines = newAirlines
        
        print("✅ Updated airlines:")
        for airline in availableAirlines {
            print("   \(airline.name) (\(airline.code)): ₹\(Int(airline.price))")
        }
        
        // Update cached sorted airlines for sheet
        refreshCachedSortedAirlines()
    }
    
    /// Cache sorted airlines for the filter sheet display
    func refreshCachedSortedAirlines() {
        cachedSortedAirlinesForSheet = getAirlinesSortedForDisplay()
        print("🔧 Cached \(cachedSortedAirlinesForSheet.count) sorted airlines for sheet")
    }
    
    /// Get airlines sorted with selected airlines at the top
    func getAirlinesSortedForDisplay() -> [AirlineOption] {
        guard !availableAirlines.isEmpty else {
            print("⚠️ No available airlines to sort")
            return []
        }
        
        let sorted = availableAirlines.sorted { airline1, airline2 in
            let isSelected1 = selectedAirlines.contains(airline1.code)
            let isSelected2 = selectedAirlines.contains(airline2.code)
            
            // Selected airlines come first
            if isSelected1 && !isSelected2 {
                return true
            } else if !isSelected1 && isSelected2 {
                return false
            } else {
                // Within each group (selected/unselected), sort alphabetically
                return airline1.name < airline2.name
            }
        }
        
        print("📋 Sorted airlines: \(sorted.count) total")
        print("   Selected: \(sorted.filter { selectedAirlines.contains($0.code) }.count)")
        print("   Unselected: \(sorted.filter { !selectedAirlines.contains($0.code) }.count)")
        
        return sorted
    }
    
    // MARK: - Airline Selection Logic
    
    /// Toggle selection of a specific airline
    func toggleAirlineFilter(_ airlineCode: String) {
        if selectedAirlines.contains(airlineCode) {
            selectedAirlines.remove(airlineCode)
            print("❌ Deselected airline: \(airlineCode)")
        } else {
            selectedAirlines.insert(airlineCode)
            print("✅ Selected airline: \(airlineCode)")
        }
        
        print("📊 Current selection: \(selectedAirlines.count)/\(availableAirlines.count) airlines")
    }
    
    /// Select all available airlines
    func selectAllAirlinesFilter() {
        let allCodes = Set(availableAirlines.map { $0.code })
        selectedAirlines = allCodes
        print("✅ Selected all \(allCodes.count) airlines")
    }
    
    /// Deselect all airlines
    func deselectAllAirlines() {
        selectedAirlines.removeAll()
        print("❌ Deselected all airlines")
    }
    
    /// Toggle select all - if all are selected, deselect all; otherwise select all
    func toggleSelectAllAirlinesFilter() {
        if selectedAirlines.count == availableAirlines.count {
            deselectAllAirlines()
        } else {
            selectAllAirlinesFilter()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if all airlines are selected
    var areAllAirlinesSelected: Bool {
        return selectedAirlines.count == availableAirlines.count && !availableAirlines.isEmpty
    }
    
    /// Get count of selected airlines
    var selectedAirlinesCount: Int {
        return selectedAirlines.count
    }
    
    /// Get names of selected airlines
    var selectedAirlineNames: [String] {
        return availableAirlines
            .filter { selectedAirlines.contains($0.code) }
            .map { $0.name }
    }
    
    /// Get airline by code
    func getAirline(by code: String) -> AirlineOption? {
        return availableAirlines.first { $0.code == code }
    }
    
    /// Check if airline is selected
    func isAirlineSelected(_ code: String) -> Bool {
        return selectedAirlines.contains(code)
    }
    
    /// Get display text for airline filter button
    func getAirlineFilterDisplayText() -> String {
        if selectedAirlines.isEmpty {
            return "Airlines"
        } else if selectedAirlines.count == 1,
                  let airline = getAirline(by: selectedAirlines.first!) {
            return airline.name
        } else {
            return "\(selectedAirlines.count) Airlines"
        }
    }
    
    /// Reset airline filters
    func resetAirlineFilters() {
        selectedAirlines.removeAll()
        excludedAirlines.removeAll()
        print("🔄 Reset airline filters")
    }
    
    /// Debug print current airline state
    func debugPrintAirlineState() {
        print("\n🔍 ===== AIRLINE FILTER DEBUG =====")
        print("Available Airlines: \(availableAirlines.count)")
        print("Selected Airlines: \(selectedAirlines.count)")
        print("Selected Codes: \(Array(selectedAirlines).joined(separator: ", "))")
        print("All Selected: \(areAllAirlinesSelected)")
        
        print("Airlines List:")
        for airline in availableAirlines {
            let isSelected = selectedAirlines.contains(airline.code)
            print("   \(isSelected ? "✅" : "❌") \(airline.name) (\(airline.code)) - ₹\(Int(airline.price))")
        }
        print("🔍 ===== END AIRLINE DEBUG =====\n")
    }
}
