//
//  FilterViewModel+PriceHandling_Fixed.swift
//  D2Flight
//
//  Fixed extension to handle price filtering functionality
//

import Foundation
import SwiftUI

extension FilterViewModel {
    
    // MARK: - Public Price Management Methods
    
    /// Track when user manually modifies price range from UI
    func userDidModifyPriceRange(newRange: ClosedRange<Double>) {
        print("🔧 User modifying price range:")
        print("   Previous: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        print("   New: ₹\(newRange.lowerBound) - ₹\(newRange.upperBound)")
        
        priceRange = newRange
        
        // Mark that user has modified the price (store in UserDefaults for persistence)
        UserDefaults.standard.set(true, forKey: "FilterViewModel_userModifiedPrice")
        
        print("   ✅ Price range updated and marked as user-modified")
    }
    
    /// Update price range when API data is received (doesn't mark as user-modified)
    func setPriceRangeFromAPI(minPrice: Double, maxPrice: Double) {
        print("🔧 Setting price range from API:")
        print("   API Min Price: ₹\(minPrice)")
        print("   API Max Price: ₹\(maxPrice)")
        print("   Current Price Range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        
        // Store original API values for comparison
        UserDefaults.standard.set(minPrice, forKey: "FilterViewModel_apiMinPrice")
        UserDefaults.standard.set(maxPrice, forKey: "FilterViewModel_apiMaxPrice")
        UserDefaults.standard.set(true, forKey: "FilterViewModel_hasAPIData")
        
        // Only update the range if user hasn't manually modified it
        let userHasModified = UserDefaults.standard.bool(forKey: "FilterViewModel_userModifiedPrice")
        
        if !userHasModified {
            priceRange = minPrice...maxPrice
            print("   ✅ Updated price range to API values: ₹\(minPrice) - ₹\(maxPrice)")
        } else {
            print("   ⚠️ Price range already modified by user, keeping current values")
        }
    }
    
    /// Check if price filter should be applied to API request
    func shouldIncludePriceFilter() -> Bool {
        let hasAPIData = UserDefaults.standard.bool(forKey: "FilterViewModel_hasAPIData")
        let userHasModified = UserDefaults.standard.bool(forKey: "FilterViewModel_userModifiedPrice")
        
        guard hasAPIData else {
            print("🔧 Price filter check: No API data loaded")
            return false
        }
        
        let apiMinPrice = UserDefaults.standard.double(forKey: "FilterViewModel_apiMinPrice")
        let apiMaxPrice = UserDefaults.standard.double(forKey: "FilterViewModel_apiMaxPrice")
        let apiRange = apiMinPrice...apiMaxPrice
        let hasChanged = priceRange != apiRange
        
        print("🔧 Price filter check:")
        print("   API Range: ₹\(apiMinPrice) - ₹\(apiMaxPrice)")
        print("   Current Range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        print("   User Modified: \(userHasModified)")
        print("   Has Changed: \(hasChanged)")
        print("   Should Apply: \(hasChanged && userHasModified)")
        
        return hasChanged && userHasModified
    }
    
    /// Get display text for price filter button
    func priceFilterDisplayText() -> String {
        if shouldIncludePriceFilter() {
            return "₹\(formatPriceValue(priceRange.lowerBound)) - ₹\(formatPriceValue(priceRange.upperBound))"
        } else {
            return "Price"
        }
    }
    
    /// Check if price filter is currently active for UI
    func isPriceFilterCurrentlyActive() -> Bool {
        return shouldIncludePriceFilter()
    }
    
    /// Reset price filter to API defaults
    func resetPriceToDefaults() {
        print("🗑️ Resetting price filter:")
        print("   Previous range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        
        let hasAPIData = UserDefaults.standard.bool(forKey: "FilterViewModel_hasAPIData")
        
        if hasAPIData {
            let apiMinPrice = UserDefaults.standard.double(forKey: "FilterViewModel_apiMinPrice")
            let apiMaxPrice = UserDefaults.standard.double(forKey: "FilterViewModel_apiMaxPrice")
            priceRange = apiMinPrice...apiMaxPrice
            print("   ✅ Reset to API values: ₹\(apiMinPrice) - ₹\(apiMaxPrice)")
        } else {
            priceRange = 0...10000
            print("   ✅ Reset to default: ₹0 - ₹10000")
        }
        
        // Clear user modification flag
        UserDefaults.standard.set(false, forKey: "FilterViewModel_userModifiedPrice")
    }
    
    /// Enhanced buildPollRequest that includes price parameters when needed
    func buildPollRequestWithPrice() -> PollRequest {
        var request = buildPollRequest() // Call existing method
        
        // ✅ ADD: Price filter logic
        if shouldIncludePriceFilter() {
            request.price_min = Int(priceRange.lowerBound)
            request.price_max = Int(priceRange.upperBound)
            
            print("   ✅ PRICE FILTER APPLIED:")
            print("     price_min: \(request.price_min!)")
            print("     price_max: \(request.price_max!)")
            print("     Range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        } else {
            print("   ❌ Price filter NOT applied")
            let hasAPIData = UserDefaults.standard.bool(forKey: "FilterViewModel_hasAPIData")
            let userHasModified = UserDefaults.standard.bool(forKey: "FilterViewModel_userModifiedPrice")
            
            if !hasAPIData {
                print("     Reason: No API data loaded yet")
            } else if !userHasModified {
                print("     Reason: User hasn't modified price range")
            } else {
                print("     Reason: Price range matches API defaults")
            }
        }
        
        return request
    }
    
    /// Enhanced hasActiveFilters that includes price filter
    func hasActiveFiltersIncludingPrice() -> Bool {
        let hasNonPriceFilters = selectedSortOption != .best ||
                                departureTimeRange != 0...86400 ||
                                arrivalTimeRange != 0...86400 ||
                                returnDepartureTimeRange != 0...86400 ||
                                returnArrivalTimeRange != 0...86400 ||
                                maxDuration < 1440 ||
                                !selectedAirlines.isEmpty ||
                                !excludedAirlines.isEmpty ||
                                maxStops < 3 ||
                                selectedClass != .economy
        
        let hasPriceFilter = shouldIncludePriceFilter()
        
        return hasNonPriceFilters || hasPriceFilter
    }
    
    /// Enhanced clear filters that includes price reset
    func clearAllFiltersIncludingPrice() {
        print("\n🗑️ ===== CLEARING ALL FILTERS INCLUDING PRICE =====")
        
        // Clear existing filters
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
        
        // Reset price filter
        resetPriceToDefaults()
        
        print("✅ All filters cleared including price modifications")
        print("🗑️ ===== END CLEARING ALL FILTERS =====\n")
    }
    
    // MARK: - Helper Methods
    
    private func formatPriceValue(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        
        return formatter.string(from: NSNumber(value: Int(price))) ?? "\(Int(price))"
    }
    
    /// Debug method to print current price state
    func debugCurrentPriceState() {
        print("\n🔍 ===== PRICE FILTER DEBUG =====")
        print("Current Price Range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
        
        let hasAPIData = UserDefaults.standard.bool(forKey: "FilterViewModel_hasAPIData")
        let userHasModified = UserDefaults.standard.bool(forKey: "FilterViewModel_userModifiedPrice")
        let apiMinPrice = UserDefaults.standard.double(forKey: "FilterViewModel_apiMinPrice")
        let apiMaxPrice = UserDefaults.standard.double(forKey: "FilterViewModel_apiMaxPrice")
        
        print("API Price Range: ₹\(apiMinPrice) - ₹\(apiMaxPrice)")
        print("Has API Data: \(hasAPIData)")
        print("User Modified: \(userHasModified)")
        print("Should Apply Filter: \(shouldIncludePriceFilter())")
        print("Filter Active: \(isPriceFilterCurrentlyActive())")
        print("Display Text: \(priceFilterDisplayText())")
        print("🔍 ===== END PRICE DEBUG =====\n")
    }
}
