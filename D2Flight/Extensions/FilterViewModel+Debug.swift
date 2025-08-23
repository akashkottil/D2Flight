// Add this extension to your FilterViewModel.swift for additional debugging

extension FilterViewModel {
    
    // ✅ ENHANCED: Debug method to print current filter state
    func printCurrentFilterState() {
        print("\n🎛️ ===== CURRENT FILTER STATE DEBUG =====")
        print("🔍 FilterViewModel State:")
        print("   Sort Option: \(selectedSortOption.rawValue)")
        print("   Max Duration: \(maxDuration) minutes (\(Int(maxDuration/60))h \(Int(maxDuration.truncatingRemainder(dividingBy: 60)))m)")
        print("   Max Stops: \(maxStops)")
        print("   Selected Airlines: \(selectedAirlines.count) - \(Array(selectedAirlines).joined(separator: ", "))")
        print("   Excluded Airlines: \(excludedAirlines.count) - \(Array(excludedAirlines).joined(separator: ", "))")
        print("   Selected Class: \(selectedClass)")
        print("   Is Round Trip: \(isRoundTrip)")
        
        // Time ranges
        if departureTimeRange != 0...1440 {
            let startTime = formatMinutesToTime(Int(departureTimeRange.lowerBound))
            let endTime = formatMinutesToTime(Int(departureTimeRange.upperBound))
            print("   Departure Time: \(startTime) - \(endTime)")
        } else {
            print("   Departure Time: Any time")
        }
        
        if isRoundTrip && returnTimeRange != 0...1440 {
            let startTime = formatMinutesToTime(Int(returnTimeRange.lowerBound))
            let endTime = formatMinutesToTime(Int(returnTimeRange.upperBound))
            print("   Return Time: \(startTime) - \(endTime)")
        } else if isRoundTrip {
            print("   Return Time: Any time")
        }
        
        // Price range
        if hasAPIDataLoaded {
            print("   API Price Range: ₹\(originalAPIMinPrice) - ₹\(originalAPIMaxPrice)")
            print("   Current Price Range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound)")
            let isPriceModified = priceRange != originalAPIMinPrice...originalAPIMaxPrice
            print("   Price Modified: \(isPriceModified ? "YES" : "NO")")
        } else {
            print("   Price Range: ₹\(priceRange.lowerBound) - ₹\(priceRange.upperBound) (no API data)")
        }
        
        // Active filters summary
        print("🎯 Active Filters Summary:")
        print("   Has Active Filters: \(hasActiveFilters())")
        
        let activeFilters = getActiveFiltersList()
        if activeFilters.isEmpty {
            print("   No active filters")
        } else {
            for filter in activeFilters {
                print("   ✓ \(filter)")
            }
        }
        
        print("🎛️ ===== END FILTER STATE DEBUG =====\n")
    }
    
    // ✅ Helper method to get list of active filters
    private func getActiveFiltersList() -> [String] {
        var activeFilters: [String] = []
        
        if selectedSortOption != .best {
            activeFilters.append("Sort: \(selectedSortOption.rawValue)")
        }
        
        if departureTimeRange != 0...1440 {
            let start = formatMinutesToTime(Int(departureTimeRange.lowerBound))
            let end = formatMinutesToTime(Int(departureTimeRange.upperBound))
            activeFilters.append("Departure time: \(start)-\(end)")
        }
        
        if isRoundTrip && returnTimeRange != 0...1440 {
            let start = formatMinutesToTime(Int(returnTimeRange.lowerBound))
            let end = formatMinutesToTime(Int(returnTimeRange.upperBound))
            activeFilters.append("Return time: \(start)-\(end)")
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
    
    // ✅ Helper to format minutes to time
    private func formatMinutesToTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }
    
    // ✅ Enhanced buildPollRequest with debug output
    func buildPollRequestWithDebug() -> PollRequest {
        print("\n🔧 ===== BUILDING POLL REQUEST DEBUG =====")
        
        // Print current state before building
        printCurrentFilterState()
        
        // Build the request
        let request = buildPollRequest()
        
        // Print the resulting request
        print("📡 Built PollRequest Analysis:")
        print("   Has Filters: \(request.hasFilters())")
        
        if let sortBy = request.sort_by {
            print("   ✓ Sort: \(sortBy) \(request.sort_order ?? "")")
        }
        if let duration = request.duration_max {
            print("   ✓ Max Duration: \(duration) minutes")
        }
        if let stops = request.stop_count_max {
            print("   ✓ Max Stops: \(stops)")
        }
        if let priceMin = request.price_min {
            print("   ✓ Price Min: ₹\(priceMin)")
        }
        if let priceMax = request.price_max {
            print("   ✓ Price Max: ₹\(priceMax)")
        }
        if let airlines = request.iata_codes_include, !airlines.isEmpty {
            print("   ✓ Include Airlines: \(airlines.joined(separator: ", "))")
        }
        if let excludeAirlines = request.iata_codes_exclude, !excludeAirlines.isEmpty {
            print("   ✓ Exclude Airlines: \(excludeAirlines.joined(separator: ", "))")
        }
        if let timeRanges = request.arrival_departure_ranges, !timeRanges.isEmpty {
            print("   ✓ Time Ranges: \(timeRanges.count) leg(s)")
            for (index, range) in timeRanges.enumerated() {
                let depStart = formatMinutesToTime(range.departure.min)
                let depEnd = formatMinutesToTime(range.departure.max)
                print("     Leg \(index + 1): \(depStart) - \(depEnd)")
            }
        }
        
        print("🔧 ===== END BUILDING POLL REQUEST DEBUG =====\n")
        
        return request
    }
}

// ✅ ENHANCED: Update your ResultHeader to use debug version
extension ResultHeader {
    
    // Add this method to your ResultHeader for debug filter application
    private func applyFiltersWithDebug() {
        print("\n🎛️ ===== FILTER APPLICATION FROM UI DEBUG =====")
        print("🖱️ Filter triggered from ResultHeader")
        
        // Print current filter state before building request
        filterViewModel.printCurrentFilterState()
        
        // Build request with debug
        let pollRequest = filterViewModel.buildPollRequestWithDebug()
        
        print("📡 Sending filter request to ResultViewModel...")
        print("🎛️ ===== END FILTER APPLICATION FROM UI DEBUG =====\n")
        
        // Call the actual filter handler
        onFiltersChanged(pollRequest)
        
        print("🔧 Filters applied:")
        print("   Sort: \(filterViewModel.selectedSortOption.displayName)")
        print("   Max Stops: \(filterViewModel.maxStops)")
        print("   Selected Airlines: \(filterViewModel.selectedAirlines.count)")
        print("   Has Any Filters: \(pollRequest.hasFilters())")
    }
}

// ✅ ENHANCED: Add debug wrapper to PollRequest
extension PollRequest {
    
    // Debug method to print all filter details
    func printDebugInfo() {
        print("\n📋 ===== POLLREQUEST DEBUG INFO =====")
        print("🔍 PollRequest Contents:")
        print("   Has Filters: \(hasFilters())")
        
        if let duration = duration_max {
            print("   Duration Max: \(duration) minutes (\(duration/60)h \(duration%60)m)")
        }
        if let stops = stop_count_max {
            print("   Stop Count Max: \(stops)")
        }
        if let priceMin = price_min {
            print("   Price Min: ₹\(priceMin)")
        }
        if let priceMax = price_max {
            print("   Price Max: ₹\(priceMax)")
        }
        if let sortBy = sort_by {
            print("   Sort By: \(sortBy)")
        }
        if let sortOrder = sort_order {
            print("   Sort Order: \(sortOrder)")
        }
        if let includeAirlines = iata_codes_include, !includeAirlines.isEmpty {
            print("   Include Airlines: \(includeAirlines)")
        }
        if let excludeAirlines = iata_codes_exclude, !excludeAirlines.isEmpty {
            print("   Exclude Airlines: \(excludeAirlines)")
        }
        if let timeRanges = arrival_departure_ranges, !timeRanges.isEmpty {
            print("   Time Ranges: \(timeRanges.count) range(s)")
            for (index, range) in timeRanges.enumerated() {
                print("     Range \(index + 1):")
                print("       Departure: \(range.departure.min) - \(range.departure.max)")
                print("       Arrival: \(range.arrival.min) - \(range.arrival.max)")
            }
        }
        if let includeAgencies = agency_include, !includeAgencies.isEmpty {
            print("   Include Agencies: \(includeAgencies)")
        }
        if let excludeAgencies = agency_exclude, !excludeAgencies.isEmpty {
            print("   Exclude Agencies: \(excludeAgencies)")
        }
        
        print("📋 ===== END POLLREQUEST DEBUG INFO =====\n")
    }
}
