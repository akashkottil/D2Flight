//
//  ResultHeader+PriceUpdates.swift
//  D2Flight
//
//  Extension to update ResultHeader with enhanced price filter functionality
//

import SwiftUI

extension ResultHeader {
    
    // ✅ Enhanced price filter button with proper status
    var enhancedPriceFilterButton: some View {
        FilterButton(
            title: filterViewModel.getPriceFilterDisplayText(),
            isSelected: filterViewModel.isPriceFilterActive(),
            action: {
                selectedFilterType = .price
                showUnifiedFilterSheet = true
            }
        )
    }
    
    // ✅ Method to update airlines and price data from poll response
    func updateFromPollResponse(_ pollResponse: PollResponse) {
        print("🔧 ResultHeader: Updating from poll response")
        print("   Airlines: \(pollResponse.airlines.count)")
        print("   Price range: ₹\(pollResponse.min_price) - ₹\(pollResponse.max_price)")
        
        // Update airlines
        filterViewModel.updateAvailableAirlines(from: pollResponse)
        
        // ✅ CRITICAL: Update price range from API
        filterViewModel.updatePriceRangeFromAPI(
            minPrice: pollResponse.min_price,
            maxPrice: pollResponse.max_price
        )
        
        print("✅ ResultHeader updated with API data")
    }
    
    // ✅ Enhanced clear all filters with proper price reset
    private func enhancedClearAllFilters() {
        print("\n🗑️ ===== ENHANCED CLEAR ALL FILTERS =====")
        print("🔄 Clearing all filters including price modifications...")
        
        // Clear all filter values to defaults
        filterViewModel.selectedSortOption = .best
        filterViewModel.maxStops = 3
        filterViewModel.departureTimeRange = 0...86400
        filterViewModel.arrivalTimeRange = 0...86400
        filterViewModel.returnDepartureTimeRange = 0...86400
        filterViewModel.returnArrivalTimeRange = 0...86400
        filterViewModel.maxDuration = 1440
        filterViewModel.selectedAirlines.removeAll()
        filterViewModel.excludedAirlines.removeAll()
        filterViewModel.selectedClass = .economy
        
        // ✅ CRITICAL: Reset price filter properly
        filterViewModel.resetPriceFilter()
        
        print("✅ All filters cleared including price modifications")
        print("🗑️ ===== END ENHANCED CLEAR ALL FILTERS =====\n")
        
        // Apply empty filters
        let emptyRequest = PollRequest()
        onClearAllFilters()
        onFiltersChanged(emptyRequest)
    }
    
    // ✅ Enhanced hasActiveFilters check including price
    func hasActiveFiltersIncludingPrice() -> Bool {
        return filterViewModel.selectedSortOption != .best ||
               filterViewModel.maxStops < 3 ||
               filterViewModel.departureTimeRange != 0...86400 ||
               filterViewModel.arrivalTimeRange != 0...86400 ||
               (isRoundTrip && filterViewModel.returnDepartureTimeRange != 0...86400) ||
               (isRoundTrip && filterViewModel.returnArrivalTimeRange != 0...86400) ||
               filterViewModel.maxDuration < 1440 ||
               !filterViewModel.selectedAirlines.isEmpty ||
               filterViewModel.selectedClass != .economy ||
               filterViewModel.isPriceFilterActive() // ✅ Include price filter
    }
    
    // ✅ Enhanced apply filters with proper price handling
    private func enhancedApplyFilters() {
        // ✅ Use the enhanced buildPollRequest method
        let pollRequest = filterViewModel.buildPollRequestWithPriceSupport()
        onFiltersChanged(pollRequest)
        
        print("🔧 Enhanced filters applied:")
        print("   Sort: \(filterViewModel.selectedSortOption.displayName)")
        print("   Max Stops: \(filterViewModel.maxStops)")
        print("   Selected Airlines: \(filterViewModel.selectedAirlines.count)")
        print("   Price Filter Active: \(filterViewModel.isPriceFilterActive())")
        if filterViewModel.isPriceFilterActive() {
            print("   Price Range: \(filterViewModel.getPriceFilterDisplayText())")
        }
        print("   Has Any Filters: \(pollRequest.hasFilters())")
    }
}

// ✅ Usage instructions for updating your existing ResultHeader.swift:
/*
 
 1. REPLACE the price filter button in your filter buttons section with:
    enhancedPriceFilterButton
 
 2. UPDATE the method that receives poll response data to call:
    updateFromPollResponse(pollResponse)
 
 3. REPLACE hasActiveFilters() calls with:
    hasActiveFiltersIncludingPrice()
 
 4. REPLACE clearAllFilters() calls with:
    enhancedClearAllFilters()
 
 5. REPLACE applyFilters() calls with:
    enhancedApplyFilters()
 
 */
