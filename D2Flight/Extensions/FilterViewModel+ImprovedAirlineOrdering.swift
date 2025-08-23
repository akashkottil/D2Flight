// FilterViewModel+ImprovedAirlineOrdering.swift
// Extension to handle improved airline ordering - only after Apply is clicked

import Foundation
import SwiftUI

extension FilterViewModel {
    
    // MARK: - Improved Airline Ordering Logic
    
    /// Apply the current filter selections and update the cached ordering
    /// This should be called when Apply button is clicked
    func applyAirlineFiltersAndUpdateOrdering() {
        // Cache the current ordering with selected airlines at top
        applyCachedSortedAirlines()
        
        print("🎯 Applied airline filters and updated ordering:")
        print("   Selected airlines: \(selectedAirlines.count)")
        print("   Total airlines: \(availableAirlines.count)")
        
        // Log the new ordering
        for (index, airline) in cachedSortedAirlinesForSheet.enumerated() {
            let isSelected = selectedAirlines.contains(airline.code)
            print("   \(index + 1). \(isSelected ? "✅" : "❌") \(airline.name)")
        }
    }
    
    /// Get airlines for display in sheet - maintains last applied ordering
    /// This preserves the ordering from the last time Apply was clicked
    func getAirlinesForSheetDisplay() -> [AirlineOption] {
        // If cached airlines exist (from previous Apply), use that ordering
        if !cachedSortedAirlinesForSheet.isEmpty {
            print("📋 Using cached airline ordering from last Apply")
            return cachedSortedAirlinesForSheet
        }
        
        // Otherwise, show original alphabetical order (no selected-first sorting)
        let alphabeticalOrder = availableAirlines.sorted { $0.name < $1.name }
        print("📋 Using alphabetical ordering (no Apply yet)")
        return alphabeticalOrder
    }
    
    /// Refresh cached airlines with selected-first ordering
    /// Only call this when Apply button is clicked
    func applyCachedSortedAirlines() {
        cachedSortedAirlinesForSheet = getAirlinesSortedWithSelectedFirst()
        print("🔄 Applied cached airlines with selected-first ordering")
    }
    
    /// Get airlines sorted with selected airlines at the top
    /// This is the "applied" ordering that persists until next Apply
    private func getAirlinesSortedWithSelectedFirst() -> [AirlineOption] {
        guard !availableAirlines.isEmpty else {
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
        
        return sorted
    }
    
    /// Reset airline ordering to alphabetical (call when clearing filters)
    func resetAirlineOrdering() {
        cachedSortedAirlinesForSheet = availableAirlines.sorted { $0.name < $1.name }
        print("🔄 Reset airline ordering to alphabetical")
    }
    
    /// Clear all airline selections and reset ordering
    func clearAirlineFiltersAndOrdering() {
        selectedAirlines.removeAll()
        excludedAirlines.removeAll()
        resetAirlineOrdering()
        print("🗑️ Cleared airline filters and reset ordering")
    }
}
