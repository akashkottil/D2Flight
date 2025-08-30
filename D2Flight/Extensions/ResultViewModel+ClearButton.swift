// Add these methods to your ResultViewModel.swift for clear filters functionality

extension ResultViewModel {
    
    // ✅ ADD: Make sure the ResultViewModel clearAllFilters method is complete
    func clearAllFilters() {
        guard let searchId = searchId else {
            print("❌ Cannot clear filters: no searchId")
            return
        }
        
        print("\n🗑️ ===== CLEAR ALL FILTERS IN RESULTVIEWMODEL =====")
        print("🔄 Clearing all filters and reloading original results...")
        print("   Search ID: \(searchId)")
        print("   Previous filter state: \(isFilteredResults)")
        print("   Previous results count: \(flightResults.count)")
        
        // ✅ CRITICAL: Reset filter state completely
        currentFilterRequest = PollRequest()  // Empty request = no filters
        isFilteredResults = false
        
        // Reset pagination
        resetPagination()
        
        // Enable continuous polling for unfiltered results
        shouldContinuouslyPoll = true
        
        isLoading = true
        errorMessage = nil
        flightResults = [] // Clear existing results
        totalPollCount += 1
        
        print("📡 Making clear filters poll request (poll #\(totalPollCount))")
        print("   ✅ Using empty PollRequest (no filters)")
        print("   ✅ Continuous polling enabled: \(shouldContinuouslyPoll)")
        print("🗑️ ===== END CLEAR ALL FILTERS IN RESULTVIEWMODEL =====\n")
        
        // Make API call with completely empty filter request
        pollApi.pollFlights(
            searchId: searchId,
            request: PollRequest(), // ✅ CRITICAL: Empty request = no filters
            limit: initialPageSize
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    print("\n✅ ===== CLEAR FILTERS SUCCESS FROM NO FLIGHTS VIEW =====")
                    print("✅ Clear filters poll successful!")
                    print("   Original results count: \(response.count)")
                    print("   Results in this batch: \(response.results.count)")
                    print("   ✅ All flights restored (no filters applied)")
                    print("✅ ===== END CLEAR FILTERS SUCCESS =====\n")
                    
                    self.pollResponse = response
                    self.flightResults = response.results
                    self.totalResultsCount = response.count
                    self.isCacheComplete = response.cache
                    
                    // Store next page URL
                    self.nextPageURL = response.next
                    self.hasMoreResults = (response.next != nil)
                    
                    // Start continuous polling if cache not complete
                    if !self.isCacheComplete && self.shouldContinuouslyPoll {
                        self.startContinuousPolling()
                    }
                    
                case .failure(let error):
                    print("\n❌ Clear filters from NoFlights failed: \(error)")
                    self.errorMessage = "Failed to clear filters: \(error.localizedDescription)"
                    self.flightResults = []
                    self.hasMoreResults = false
                    self.nextPageURL = nil
                }
            }
        }
    }
    
    // ✅ NEW: Apply specific stops filter
    func applyStopsFilter(maxStops: Int) {
        guard let searchId = searchId else {
            print("❌ Cannot apply stops filter: no searchId")
            return
        }
        
        print("\n🛑 ===== APPLY STOPS FILTER IN RESULTVIEWMODEL =====")
        print("🔧 Applying stops filter...")
        print("   Search ID: \(searchId)")
        print("   Max Stops: \(maxStops)")
        
        // Create filter request with only stops filter
        var request = PollRequest()
        if maxStops < 3 {
            request.stop_count_max = maxStops
            print("   API Parameter: \"stop_count_max\": \(maxStops)")
        } else {
            print("   API Parameter: No stop_count_max (show all stops)")
        }
        
        // Update filter state
        currentFilterRequest = request
        isFilteredResults = request.hasFilters()
        
        print("   Filter state updated: isFilteredResults = \(isFilteredResults)")
        print("🛑 ===== END APPLY STOPS FILTER IN RESULTVIEWMODEL =====\n")
        
        // Apply the filter using existing method
        applyFilters(request: request)
    }
    
    // ✅ ENHANCED: Check if filters are currently active
    func hasActiveFilters() -> Bool {
        return isFilteredResults && currentFilterRequest.hasFilters()
    }
    
    // ✅ NEW: Get summary of active filters
    func getActiveFiltersSummary() -> String {
        guard hasActiveFilters() else {
            return "No filters active"
        }
        
        var summary: [String] = []
        
        if let stops = currentFilterRequest.stop_count_max {
            let stopsText = stops == 0 ? "Direct only" : "≤ \(stops) stops"
            summary.append(stopsText)
        }
        
        if let duration = currentFilterRequest.duration_max {
            summary.append("≤ \(duration/60)h")
        }
        
        if let priceMin = currentFilterRequest.price_min {
            summary.append("≥ ₹\(priceMin)")
        }
        
        if let priceMax = currentFilterRequest.price_max {
            summary.append("≤ ₹\(priceMax)")
        }
        
        if let airlines = currentFilterRequest.iata_codes_include, !airlines.isEmpty {
            summary.append("\(airlines.count) airlines")
        }
        
        if let sortBy = currentFilterRequest.sort_by {
            summary.append("Sort: \(sortBy)")
        }
        
        if let timeRanges = currentFilterRequest.arrival_departure_ranges, !timeRanges.isEmpty {
            summary.append("Time filters")
        }
        
        return summary.joined(separator: ", ")
    }
    
    // ✅ NEW: Reset filter state method (for external access)
    func resetFilterState() {
        print("\n🔄 ===== RESET FILTER STATE =====")
        print("🔄 Resetting filter state in ResultViewModel")
        print("   Previous state: isFilteredResults = \(isFilteredResults)")
        print("   Previous request had filters: \(currentFilterRequest.hasFilters())")
        
        currentFilterRequest = PollRequest()
        isFilteredResults = false
        
        print("   New state: isFilteredResults = \(isFilteredResults)")
        print("   New request has filters: \(currentFilterRequest.hasFilters())")
        print("🔄 ===== END RESET FILTER STATE =====\n")
    }
}
