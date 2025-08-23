// Add these enhanced methods to your FilterViewModel.swift

extension FilterViewModel {
    
    // ✅ ENHANCED: Clear filters with proper reset including new arrival time filters
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
        departureTimeRange = 0...86400 // ✅ UPDATED: seconds
        arrivalTimeRange = 0...86400 // ✅ UPDATED: seconds
        returnDepartureTimeRange = 0...86400 // ✅ UPDATED: seconds
        returnArrivalTimeRange = 0...86400 // ✅ UPDATED: seconds
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
    
    // ✅ UPDATED: Get user-friendly description of current time filters
    func getTimeFilterDescription() -> String {
        var descriptions: [String] = []
        
        // Departure time filter
        if departureTimeRange != 0...86400 { // ✅ UPDATED: seconds
            let start = formatSecondsToTime(Int(departureTimeRange.lowerBound))
            let end = formatSecondsToTime(Int(departureTimeRange.upperBound))
            descriptions.append("Departure: \(start)-\(end)")
        }
        
        // ✅ NEW: Arrival time filter
        if arrivalTimeRange != 0...86400 { // ✅ UPDATED: seconds
            let start = formatSecondsToTime(Int(arrivalTimeRange.lowerBound))
            let end = formatSecondsToTime(Int(arrivalTimeRange.upperBound))
            descriptions.append("Arrival: \(start)-\(end)")
        }
        
        // Return departure time filter (if round trip)
        if isRoundTrip && returnDepartureTimeRange != 0...86400 { // ✅ UPDATED: seconds
            let start = formatSecondsToTime(Int(returnDepartureTimeRange.lowerBound))
            let end = formatSecondsToTime(Int(returnDepartureTimeRange.upperBound))
            descriptions.append("Return Departure: \(start)-\(end)")
        }
        
        // ✅ NEW: Return arrival time filter (if round trip)
        if isRoundTrip && returnArrivalTimeRange != 0...86400 { // ✅ UPDATED: seconds
            let start = formatSecondsToTime(Int(returnArrivalTimeRange.lowerBound))
            let end = formatSecondsToTime(Int(returnArrivalTimeRange.upperBound))
            descriptions.append("Return Arrival: \(start)-\(end)")
        }
        
        return descriptions.isEmpty ? "No time filters" : descriptions.joined(separator: ", ")
    }
    
    // ✅ UPDATED: Check if time filters are active
    func hasActiveTimeFilters() -> Bool {
        return departureTimeRange != 0...86400 || // ✅ UPDATED: seconds
               arrivalTimeRange != 0...86400 || // ✅ UPDATED: seconds
               (isRoundTrip && returnDepartureTimeRange != 0...86400) || // ✅ UPDATED: seconds
               (isRoundTrip && returnArrivalTimeRange != 0...86400) // ✅ UPDATED: seconds
    }
    
    // ✅ UPDATED: Reset only time filters
    func clearTimeFilters() {
        print("\n🕐 ===== CLEAR TIME FILTERS =====")
        print("🔄 Clearing time filters only...")
        print("   Previous time filters: \(getTimeFilterDescription())")
        
        departureTimeRange = 0...86400 // ✅ UPDATED: seconds
        arrivalTimeRange = 0...86400 // ✅ UPDATED: seconds
        returnDepartureTimeRange = 0...86400 // ✅ UPDATED: seconds
        returnArrivalTimeRange = 0...86400 // ✅ UPDATED: seconds
        
        print("   New time filters: \(getTimeFilterDescription())")
        print("🕐 ===== END CLEAR TIME FILTERS =====\n")
    }
    
    // ✅ UPDATED: Helper to get list of active filters including new arrival time filters
    func getActiveFiltersList() -> [String] {
        var activeFilters: [String] = []
        
        if selectedSortOption != .best {
            activeFilters.append("Sort: \(selectedSortOption.rawValue)")
        }
        
        if departureTimeRange != 0...86400 { // ✅ UPDATED: seconds
            let start = formatSecondsToTime(Int(departureTimeRange.lowerBound))
            let end = formatSecondsToTime(Int(departureTimeRange.upperBound))
            activeFilters.append("Departure time: \(start)-\(end)")
        }
        
        // ✅ NEW: Arrival time filter
        if arrivalTimeRange != 0...86400 { // ✅ UPDATED: seconds
            let start = formatSecondsToTime(Int(arrivalTimeRange.lowerBound))
            let end = formatSecondsToTime(Int(arrivalTimeRange.upperBound))
            activeFilters.append("Arrival time: \(start)-\(end)")
        }
        
        if isRoundTrip && returnDepartureTimeRange != 0...86400 { // ✅ UPDATED: seconds
            let start = formatSecondsToTime(Int(returnDepartureTimeRange.lowerBound))
            let end = formatSecondsToTime(Int(returnDepartureTimeRange.upperBound))
            activeFilters.append("Return departure time: \(start)-\(end)")
        }
        
        // ✅ NEW: Return arrival time filter
        if isRoundTrip && returnArrivalTimeRange != 0...86400 { // ✅ UPDATED: seconds
            let start = formatSecondsToTime(Int(returnArrivalTimeRange.lowerBound))
            let end = formatSecondsToTime(Int(returnArrivalTimeRange.upperBound))
            activeFilters.append("Return arrival time: \(start)-\(end)")
        }TimeRange.lowerBound))
            let end = formatMinutesToTime(Int(departureTimeRange.upperBound))
            activeFilters.append("Departure time: \(start)-\(end)")
        }
        
        // ✅ NEW: Arrival time filter
        if arrivalTimeRange != 0...1440 {
            let start = formatMinutesToTime(Int(arrivalTimeRange.lowerBound))
            let end = formatMinutesToTime(Int(arrivalTimeRange.upperBound))
            activeFilters.append("Arrival time: \(start)-\(end)")
        }
        
        if isRoundTrip && returnDepartureTimeRange != 0...1440 {
            let start = formatMinutesToTime(Int(returnDepartureTimeRange.lowerBound))
            let end = formatMinutesToTime(Int(returnDepartureTimeRange.upperBound))
            activeFilters.append("Return departure time: \(start)-\(end)")
        }
        
        // ✅ NEW: Return arrival time filter
        if isRoundTrip && returnArrivalTimeRange != 0...1440 {
            let start = formatMinutesToTime(Int(returnArrivalTimeRange.lowerBound))
            let end = formatMinutesToTime(Int(returnArrivalTimeRange.upperBound))
            activeFilters.append("Return arrival time: \(start)-\(end)")
        }
        
        if maxDuration < 1440 {
            let hours = Int(maxDuration / 60)
            let minutes = Int(maxDuration.truncatingRemainder(dividingBy: 60))
            activeFilters.append("Max duration: \(hours)h \(minutes)m")
        }
        
        if maxStops < 3 {
            let stopsText = maxStops == 0 ? "Direct only" : "≤ \(maxStops) stops"
            activeFilters.append("Stops: \(stopsText)")
        }
        
        if !selectedAirlines.isEmpty {
            activeFilters.append("Airlines: \(selectedAirlines.count) selected")
        }
        
        if !excludedAirlines.isEmpty {
            activeFilters.append("Excluded airlines: \(excludedAirlines.count)")
        }
        
        if hasAPIDataLoaded && priceRange != originalAPIMinPrice...originalAPIMaxPrice {
            activeFilters.append("Price: ₹\(Int(priceRange.lowerBound))-₹\(Int(priceRange.upperBound))")
        }
        
        return activeFilters
    }
    
    // ✅ UPDATED: Helper to format seconds to time
    private func formatSecondsToTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        return String(format: "%02d:%02d", hours, mins)
    }
}
