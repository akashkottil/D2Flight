//
//  FilterViewModel+ClearButton.swift
//  D2Flight
//
//  Created by Akash Kottil on 21/08/25.
//


// Add these enhanced methods to your FilterViewModel.swift

extension FilterViewModel {
    
    // ✅ ENHANCED: Clear filters with proper reset
    func clearFilters() {
        print("\n🗑️ ===== CLEAR FILTERS DEBUG =====")
        print("🔄 Clearing all filters...")
        
        // Print state before clearing
        print("   State before clear:")
        let activeFiltersBefore = getActiveFiltersList()
        for filter in activeFiltersBefore {
            print("     - \(filter)")
        }
        
        // Reset all filter values to defaults
        selectedSortOption = .best
        departureTimeRange = 0...1440
        returnTimeRange = 0...1440
        maxDuration = 1440
        selectedClass = .economy
        selectedAirlines.removeAll()
        excludedAirlines.removeAll()
        maxStops = 3  // ✅ Reset to "Any" (3 = any stops)
        
        // Reset price range to API values if available
        if hasAPIDataLoaded {
            priceRange = originalAPIMinPrice...originalAPIMaxPrice
            print("   Reset price range to API values: ₹\(originalAPIMinPrice) - ₹\(originalAPIMaxPrice)")
        } else {
            priceRange = 0...10000
            print("   Reset price range to default: ₹0 - ₹10000")
        }
        
        print("   State after clear:")
        let activeFiltersAfter = getActiveFiltersList()
        if activeFiltersAfter.isEmpty {
            print("     ✅ No active filters (all cleared)")
        } else {
            for filter in activeFiltersAfter {
                print("     - \(filter)")
            }
        }
        
        print("🗑️ ===== END CLEAR FILTERS DEBUG =====\n")
    }
    
    // ✅ ENHANCED: Build poll request for clear operation
    func buildClearPollRequest() -> PollRequest {
        print("\n🗑️ ===== BUILDING CLEAR POLL REQUEST =====")
        print("🔄 Building empty poll request (no filters)...")
        
        let emptyRequest = PollRequest()
        
        print("📡 Clear Poll Request Analysis:")
        print("   Has Filters: \(emptyRequest.hasFilters())")
        print("   Sort By: \(emptyRequest.sort_by?.description ?? "not set")")
        print("   Duration Max: \(emptyRequest.duration_max?.description ?? "not set")")
        print("   Stop Count Max: \(emptyRequest.stop_count_max?.description ?? "not set")")
        print("   Price Min: \(emptyRequest.price_min?.description ?? "not set")")
        print("   Price Max: \(emptyRequest.price_max?.description ?? "not set")")
        print("   Airlines Include: \(emptyRequest.iata_codes_include?.description ?? "not set")")
        print("   Airlines Exclude: \(emptyRequest.iata_codes_exclude?.description ?? "not set")")
        print("   Time Ranges: \(emptyRequest.arrival_departure_ranges?.description ?? "not set")")
        
        print("✅ Empty request will show ALL flight results")
        print("🗑️ ===== END BUILDING CLEAR POLL REQUEST =====\n")
        
        return emptyRequest
    }
    
    // ✅ NEW: Get user-friendly description of current stops filter
    func getStopsFilterDescription() -> String {
        switch maxStops {
        case 0: return "Direct flights only"
        case 1: return "Up to 1 stop"
        case 2: return "Up to 2 stops"
        default: return "Any number of stops"
        }
    }
    
    // ✅ NEW: Check if stops filter is active
    func hasActiveStopsFilter() -> Bool {
        return maxStops < 3
    }
    
    // ✅ NEW: Reset only stops filter
    func clearStopsFilter() {
        print("\n🛑 ===== CLEAR STOPS FILTER =====")
        print("🔄 Clearing stops filter only...")
        print("   Previous max stops: \(maxStops) (\(getStopsFilterDescription()))")
        
        maxStops = 3 // Reset to "Any"
        
        print("   New max stops: \(maxStops) (\(getStopsFilterDescription()))")
        print("🛑 ===== END CLEAR STOPS FILTER =====\n")
    }
    
    // ✅ ENHANCED: Detailed stops filter logging
    func logStopsFilterChange(from oldValue: Int, to newValue: Int) {
        print("\n🛑 ===== STOPS FILTER CHANGE =====")
        print("🔄 Stops filter changed:")
        print("   From: \(oldValue) (\(getStopsDescription(oldValue)))")
        print("   To: \(newValue) (\(getStopsDescription(newValue)))")
        
        // Log API parameter that will be sent
        if newValue < 3 {
            print("   API Parameter: \"stop_count_max\": \(newValue)")
        } else {
            print("   API Parameter: No stop_count_max (show all)")
        }
        
        print("🛑 ===== END STOPS FILTER CHANGE =====\n")
    }
    
    // Helper to get stops description
    private func getStopsDescription(_ maxStops: Int) -> String {
        switch maxStops {
        case 0: return "Direct only"
        case 1: return "Up to 1 stop"
        case 2: return "Up to 2 stops"
        default: return "Any stops"
        }
    }
}

// ✅ ENHANCED: Property observer for maxStops changes
extension FilterViewModel {
    
    // Add this to monitor stops changes - you can add this as a computed property wrapper
    func setMaxStops(_ newValue: Int) {
        let oldValue = maxStops
        maxStops = newValue
        
        if oldValue != newValue {
            logStopsFilterChange(from: oldValue, to: newValue)
        }
    }
}
