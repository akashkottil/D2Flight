import Foundation
import Combine
import Alamofire

class ResultViewModel: ObservableObject {
    @Published var flightResults: [FlightResult] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchId: String? = nil
    
    // ✅ NEW: Track final poll after cache complete
    private var hasFinalPolled: Bool = false
    private var isFinalPolling: Bool = false
    
    @Published var hasMoreResults: Bool = true
    @Published var totalResultsCount: Int = 0
    private let initialPageSize: Int = 30
    private let subsequentPageSize: Int = 30
    
    // Poll response data
    @Published var pollResponse: PollResponse? = nil
    @Published var selectedFlight: FlightResult? = nil
    @Published var totalPollCount: Int = 0
    
    // ✅ NEW: Expose cache status to UI
    @Published var isCacheComplete: Bool = false
    
    // ✅ Track next URL availability
    private var nextPageURL: String? = nil
    
    // ✅ CRITICAL FIX: Store current filter state
    var currentFilterRequest: PollRequest = PollRequest()
    var isFilteredResults: Bool = false
    
    // ✅ Ads integration properties
    @Published var adsService = HotelAdsAPIService()
    @Published var hasLoadedAds = false
    
    private var cancellables = Set<AnyCancellable>()
    private let pollApi = PollApi.shared
    private var maxRetries = 10
    private var currentRetries = 0
    private var maxTotalPolls = 50
    private var pollStartTime: Date?
    
    // Add flag to control continuous polling
    private var shouldContinuouslyPoll = false
    
    init() {}
    
    // ✅ ADDED: Clear all filters method directly in the main class
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
        
        // ✅ PRESERVE ADS STATE: Store current ads before clearing
            let currentAds = adsService.ads
            let adsLoaded = hasLoadedAds
        
        // Reset filter state
        currentFilterRequest = PollRequest()
        isFilteredResults = false
        
        // Reset pagination
        resetPagination()
        
        // ✅ RESTORE ADS STATE: Restore ads after clearing filters
            adsService.ads = currentAds
            hasLoadedAds = adsLoaded
        
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
        
        // Make API call with empty filter request
        pollApi.pollFlights(
            searchId: searchId,
            request: PollRequest(), // Empty request = no filters
            limit: initialPageSize
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    print("\n✅ ===== CLEAR FILTERS SUCCESS DEBUG =====")
                    print("✅ Clear filters poll successful!")
                    print("   Original results count: \(response.count)")
                    print("   Results in this batch: \(response.results.count)")
                    print("   Cache status: \(response.cache)")
                    print("   Next page available: \(response.next != nil)")
                    print("   ✅ Showing all flights (no filters applied)")
                    
                    // Log sample results
                    if !response.results.isEmpty {
                        print("📋 Sample Results (first 3):")
                        for (index, flight) in response.results.prefix(3).enumerated() {
                            if let firstLeg = flight.legs.first {
                                print("   \(index + 1). \(firstLeg.originCode) → \(firstLeg.destinationCode)")
                                print("      Price: \(flight.formattedPrice), Duration: \(flight.formattedDuration)")
                                print("      Stops: \(firstLeg.stopsText)")
                            }
                        }
                    }
                    print("✅ ===== END CLEAR FILTERS SUCCESS DEBUG =====\n")
                    
                    self.pollResponse = response
                    self.flightResults = response.results
                    self.totalResultsCount = response.count
                    self.isCacheComplete = response.cache
                    
                    // Store next page URL
                    self.nextPageURL = response.next
                    self.hasMoreResults = (response.next != nil)
                    
                    print("   Total results now: \(self.flightResults.count)")
                    print("   Has more results: \(self.hasMoreResults)")
                    print("   Filter state reset: isFilteredResults = \(self.isFilteredResults)")
                    
                    // Start continuous polling if cache not complete
                    if !self.isCacheComplete && self.shouldContinuouslyPoll {
                        self.startContinuousPolling()
                    }
                    
                case .failure(let error):
                    print("\n❌ ===== CLEAR FILTERS ERROR DEBUG =====")
                    print("❌ Clear filters poll failed: \(error)")
                    print("   Search ID: \(searchId)")
                    print("   Error type: \(type(of: error))")
                    print("   Error description: \(error.localizedDescription)")
                    print("❌ ===== END CLEAR FILTERS ERROR DEBUG =====\n")
                    
                    self.errorMessage = "Failed to clear filters: \(error.localizedDescription)"
                    self.flightResults = []
                    self.hasMoreResults = false
                    self.nextPageURL = nil
                    
                    print("🔄 Keeping filter state reset despite error")
                }
            }
        }
    }
    
    // ✅ ADDED: Enhanced check if filters are currently active
    func hasActiveFilters() -> Bool {
        return isFilteredResults && currentFilterRequest.hasFilters()
    }
    
    // ✅ ADDED: Get summary of active filters
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
    
    func pollFlights(searchId: String) {
        guard !searchId.isEmpty else {
            errorMessage = "Invalid search ID"
            return
        }
        
        resetPaginationForNewSearch()
        
        self.searchId = searchId
        isLoading = true
        errorMessage = nil
        currentRetries = 0
        flightResults = []
        shouldContinuouslyPoll = true
        
        // ✅ CRITICAL FIX: Reset filter state for new search
        currentFilterRequest = PollRequest()
        isFilteredResults = false
        
        print("🚀 Starting poll for search_id: \(searchId)")
        
        // Start polling with retry mechanism
        loadInitialResults(searchId: searchId)
    }
    
    private func resetPagination() {
        hasMoreResults = true
        totalResultsCount = 0
        self.isCacheComplete = false
        isLoadingMore = false
        totalPollCount = 0
        pollStartTime = Date()
        currentRetries = 0
        shouldContinuouslyPoll = false
        nextPageURL = nil
        
        // ✅ NEW: Reset final poll tracking
        hasFinalPolled = false
        isFinalPolling = false
        
        // Reset ads loading state for new search
        hasLoadedAds = false
        adsService.ads = []
        adsService.adsErrorMessage = nil
    }
    
    // ✅ NEW: Method to reset pagination for new searches (including ads)
    private func resetPaginationForNewSearch() {
        resetPagination()
        
        // Reset ads loading state for new search
        hasLoadedAds = false
        adsService.ads = []
        adsService.adsErrorMessage = nil
    }
    
    // ✅ Load initial results with 30 items
    private func loadInitialResults(searchId: String) {
        // Safety check to prevent infinite polling
        guard totalPollCount < maxTotalPolls else {
            print("⚠️ Reached maximum poll limit (\(maxTotalPolls)), stopping")
            isLoading = false
            errorMessage = "Search timeout - please try again"
            return
        }
        
        totalPollCount += 1
        
        // ✅ CRITICAL FIX: Use current filter state instead of empty request
        let requestToUse = isFilteredResults ? currentFilterRequest : PollRequest()
        
        print("   ✅ Using filter request: \(requestToUse.hasFilters())")
        print("   ✅ Using INITIAL page size: \(initialPageSize) results")
        
        pollApi.pollFlights(
            searchId: searchId,
            request: requestToUse,
            limit: initialPageSize
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    self.handleInitialPollSuccess(response)
                    
                case .failure(let error):
                    self.handlePollFailure(error, isInitial: true, searchId: searchId)
                }
            }
        }
    }
    
    private func handleInitialPollSuccess(_ response: PollResponse) {
        pollResponse = response
        totalResultsCount = response.count
        self.isCacheComplete = response.cache
        
        // Store next page URL
        nextPageURL = response.next
        
        print("✅ Initial poll successful!")
        print("   Total flights available: \(response.count)")
        print("   Results in this batch: \(response.results.count)")
        print("   Cache complete: \(response.cache)")
        print("   Next page available: \(response.next != nil)")
        print("   ✅ Loaded \(response.results.count) results in INITIAL batch (target: \(initialPageSize))")
        
        if response.results.isEmpty && response.count == 0 && currentRetries < maxRetries && !isCacheComplete {
            // If no results but API indicates there should be flights, retry
            print("🔄 No results yet, retrying... (\(currentRetries + 1)/\(maxRetries))")
            currentRetries += 1
            
            // Retry after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if let searchId = self.searchId, self.shouldContinuouslyPoll {
                    self.loadInitialResults(searchId: searchId)
                }
            }
        } else {
            // We have results or max retries reached
            isLoading = false
            flightResults = response.results
            
            // Check next URL instead of count comparison
            hasMoreResults = (response.next != nil)
            
            print("   Current results: \(flightResults.count), Total available: \(totalResultsCount)")
            print("   Has next page: \(response.next != nil)")
            print("   Has more results: \(hasMoreResults)")
            print("   ✅ NEXT requests will use subsequent page size: \(subsequentPageSize)")
            
            if response.results.isEmpty {
                print("⚠️ No flights found after \(currentRetries) retries")
                hasMoreResults = false
            }
            
            // Start continuous polling only if cache is not complete
            if !isCacheComplete && shouldContinuouslyPoll {
                startContinuousPolling()
            }
        }
    }
    
    private func handlePollFailure(_ error: Error, isInitial: Bool, searchId: String) {
        if currentRetries < maxRetries {
            print("❌ Poll failed, retrying... (\(currentRetries + 1)/\(maxRetries)): \(error)")
            currentRetries += 1
            
            // Exponential backoff: 2s, 4s, 6s, 8s, etc.
            let retryDelay = min(2.0 * Double(currentRetries), 10.0)
            
            // Retry after calculated delay
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                if isInitial {
                    self.loadInitialResults(searchId: searchId)
                } else {
                    self.loadMoreResults()
                }
            }
        } else {
            if isInitial {
                isLoading = false
            } else {
                isLoadingMore = false
            }
            errorMessage = "Failed to fetch flights after \(maxRetries) attempts: \(error.localizedDescription)"
            print("❌ Poll failed after \(maxRetries) retries: \(error)")
        }
    }
    
    // Continuous polling for cache updates (only when cache is not complete)
    private func startContinuousPolling() {
        guard let searchId = searchId, shouldContinuouslyPoll else { return }
        
        // Only poll if cache is not complete
        guard !isCacheComplete else {
            print("🏁 Cache is complete, stopping continuous polling")
            return
        }
        
        print("🔄 Scheduling cache check in 3 seconds...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard self.shouldContinuouslyPoll, !self.isCacheComplete else { return }
            
            // Check for cache updates without changing pagination
            self.checkForCacheUpdates(searchId: searchId)
        }
    }
    
    private func ensureAdsVisibilityForFilteredResults(_ response: PollResponse) {
        let resultCount = response.results.count
        let adsCount = adsService.ads.count
        
        print("🎯 ===== ADS VISIBILITY CHECK FOR FILTERED RESULTS =====")
        print("   Filtered results count: \(resultCount)")
        print("   Available ads count: \(adsCount)")
        
        if resultCount <= 3 && adsCount > 0 && hasLoadedAds {
            print("   🎯 LOW RESULT COUNT DETECTED - Ensuring ads visibility")
            print("   Strategy: Ads will be positioned at the end of results")
            
            // Log which ads will be displayed
            let adsToShow = min(adsCount, 3) // Show up to 3 ads for low result counts
            print("   📋 Ads that will be displayed:")
            for i in 0..<adsToShow {
                print("     \(i + 1). \(adsService.ads[i].headline) - \(adsService.ads[i].companyName)")
            }
        } else if resultCount > 3 && adsCount > 0 {
            print("   ✅ Normal result count - ads will use strategic positioning")
        } else if adsCount == 0 {
            print("   ⚠️ No ads available to display")
        } else if !hasLoadedAds {
            print("   ⚠️ Ads not loaded yet")
        }
        
        print("🎯 ===== END ADS VISIBILITY CHECK =====")
    }
    
    // ✅ UPDATED: Check for cache updates and trigger final poll when complete
    private func checkForCacheUpdates(searchId: String) {
        guard totalPollCount < maxTotalPolls else {
            print("⚠️ Reached maximum poll limit for cache updates")
            return
        }
        
        totalPollCount += 1
        
        // ✅ CRITICAL FIX: Use current filter state for cache updates
        let requestToUse = isFilteredResults ? currentFilterRequest : PollRequest()
        
        print("🔍 Checking for cache updates (poll #\(totalPollCount))")
        print("   Using filtered request: \(isFilteredResults)")
        
        pollApi.pollFlights(
            searchId: searchId,
            request: requestToUse,
            page: 1,
            limit: initialPageSize
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    let previousCacheStatus = self.isCacheComplete
                    self.isCacheComplete = response.cache
                    self.totalResultsCount = response.count
                    
                    // Update next page URL from cache check
                    self.nextPageURL = response.next
                    
                    print("   Cache status: \(previousCacheStatus) → \(response.cache)")
                    print("   Total count: \(self.totalResultsCount)")
                    print("   Next page available: \(response.next != nil)")
                    
                    // Update hasMoreResults based on next URL
                    self.hasMoreResults = (response.next != nil)
                    
                    // ✅ NEW: Trigger final comprehensive poll when cache becomes complete
                    if !previousCacheStatus && response.cache && !self.hasFinalPolled {
                        print("🏁 Cache just became complete! Starting final comprehensive poll...")
                        self.performFinalComprehensivePoll(searchId: searchId)
                    } else if !response.cache && self.shouldContinuouslyPoll {
                        // Continue polling if cache is still not complete
                        self.startContinuousPolling()
                    }
                    
                case .failure(let error):
                    print("❌ Cache check failed: \(error)")
                    // Continue polling despite failure
                    if self.shouldContinuouslyPoll {
                        self.startContinuousPolling()
                    }
                }
            }
        }
    }
    
    // ✅ NEW: Handle final poll results - merge intelligently without disrupting UX
    private func handleFinalPollSuccess(_ response: PollResponse) {
        print("🎯 Final comprehensive poll completed!")
        print("   Received \(response.results.count) flights in final poll")
        print("   Previous count: \(flightResults.count)")
        print("   API total count: \(response.count)")
        
        // Update the definitive metadata
        totalResultsCount = response.count
        isCacheComplete = response.cache
        nextPageURL = response.next
        hasMoreResults = (response.next != nil)
        
        // ✅ Smart merge: Add any missing flights without disrupting user's scroll position
        let currentFlightIds = Set(flightResults.map { $0.id })
        let newFlights = response.results.filter { !currentFlightIds.contains($0.id) }
        
        if !newFlights.isEmpty {
            print("🆕 Found \(newFlights.count) new flights in final poll - adding silently")
            
            // Add new flights to the end to maintain user's current view
            flightResults.append(contentsOf: newFlights)
            
            // Sort by price or relevance to maintain quality (optional)
            flightResults.sort { flight1, flight2 in
                // Sort by price, but maintain best/cheapest/fastest at top
                if flight1.is_best && !flight2.is_best { return true }
                if flight2.is_best && !flight1.is_best { return false }
                if flight1.is_cheapest && !flight2.is_cheapest { return true }
                if flight2.is_cheapest && !flight1.is_cheapest { return false }
                if flight1.is_fastest && !flight2.is_fastest { return true }
                if flight2.is_fastest && !flight1.is_fastest { return false }
                return flight1.min_price < flight2.min_price
            }
            
            print("✅ Silently added \(newFlights.count) flights. Total now: \(flightResults.count)")
        } else {
            print("✅ No new flights found - results were already complete")
        }
        
        // ✅ Handle potential discrepancies in total count
        if flightResults.count < totalResultsCount && hasMoreResults {
            print("📊 Results count (\(flightResults.count)) < total (\(totalResultsCount))")
            print("   Pagination still available for remaining flights")
        } else if flightResults.count >= totalResultsCount {
            print("🏁 All flights loaded! (\(flightResults.count)/\(totalResultsCount))")
            hasMoreResults = false
            nextPageURL = nil
        }
        
        print("🎯 Final poll integration complete - user experience maintained")
    }
    
    // ✅ NEW: Perform final comprehensive poll after cache complete to ensure no missing results
    private func performFinalComprehensivePoll(searchId: String) {
        guard !hasFinalPolled && !isFinalPolling else {
            print("🚫 Final poll already completed or in progress")
            return
        }
        
        guard !isFilteredResults else {
                print("🚫 Skipping final poll - filters are active")
                return
            }
        
        isFinalPolling = true
        hasFinalPolled = true
        
        print("🎯 Starting final comprehensive poll after cache complete...")
        print("   Current results: \(flightResults.count)")
        print("   Expected total: \(totalResultsCount)")
        
        let requestToUse = isFilteredResults ? currentFilterRequest : PollRequest()
        
        // Poll from page 1 with a larger limit to get comprehensive results
        pollApi.pollFlights(
            searchId: searchId,
            request: requestToUse,
            page: 1,
            limit: max(100, totalResultsCount) // Use larger limit to capture all results
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isFinalPolling = false
                
                switch result {
                case .success(let response):
                    self.handleFinalPollSuccess(response)
                    
                case .failure(let error):
                    print("❌ Final comprehensive poll failed: \(error)")
                    // Don't treat this as a critical error - user still has the previous results
                    print("   User experience maintained with existing \(self.flightResults.count) results")
                }
            }
        }
    }
    
    // ✅ Fixed implementation using next URLs
    func loadMoreResults() {
        guard let searchId = searchId else {
            print("🚫 Cannot load more: no searchId")
            return
        }
        
        // ✅ NEW: Check if we have a next URL to use
        guard let nextURL = nextPageURL else {
            print("🚫 Cannot load more: no next URL available")
            hasMoreResults = false
            return
        }
        
        guard !isLoadingMore && !isLoading else {
            print("🚫 Cannot load more: already loading")
            return
        }
        
        totalPollCount += 1
        isLoadingMore = true
        errorMessage = nil
        currentRetries = 0
        
        print("\n📄 ===== LOAD MORE WITH FILTERS DEBUG =====")
        print("📄 Loading more results using next URL: \(nextURL)")
        print("   Current results: \(flightResults.count)/\(totalResultsCount)")
        print("   Has filters: \(isFilteredResults)")
        print("   Current filter request: \(currentFilterRequest.hasFilters())")
        
        // Debug current filter state
        if isFilteredResults {
            print("🔧 Maintaining filter state for pagination:")
            if let duration = currentFilterRequest.duration_max {
                print("   ⏱️ Duration: ≤ \(duration) minutes")
            }
            if let stops = currentFilterRequest.stop_count_max {
                print("   🛑 Stops: ≤ \(stops)")
            }
            if let airlines = currentFilterRequest.iata_codes_include, !airlines.isEmpty {
                print("   ✈️ Airlines: \(airlines.joined(separator: ", "))")
            }
        }
        print("📄 ===== END LOAD MORE DEBUG =====\n")
        
        // ✅ Use the next URL instead of manual pagination
        pollApi.pollFlightsWithURL(
            nextURL: nextURL,
            request: currentFilterRequest // ✅ Pass current filters
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let response):
                    self.handleLoadMoreSuccess(response)
                    
                case .failure(let error):
                    print("\n❌ ===== LOAD MORE ERROR DEBUG =====")
                    print("❌ Load more failed: \(error)")
                    print("   URL: \(nextURL)")
                    print("   Had filters: \(self.isFilteredResults)")
                    print("❌ ===== END LOAD MORE ERROR DEBUG =====\n")
                    
                    self.handlePollFailure(error, isInitial: false, searchId: searchId)
                }
            }
        }
    }
    
    private func handleLoadMoreSuccess(_ response: PollResponse) {
        isLoadingMore = false
        
        // Update cache status and total count
        let previousTotal = totalResultsCount
        self.isCacheComplete = response.cache
        totalResultsCount = response.count
        
        // ✅ Update next page URL from response
        nextPageURL = response.next
        
        print("✅ Load more successful!")
        print("   New results count: \(response.results.count)")
        print("   Total count updated: \(previousTotal) → \(totalResultsCount)")
        print("   Next page available: \(response.next != nil)")
        
        // Append new results to the existing results (avoid duplicates)
        let newResults = response.results.filter { newResult in
            !flightResults.contains { existingResult in
                existingResult.id == newResult.id
            }
        }
        
        flightResults.append(contentsOf: newResults)
        
        // ✅ Check next URL to determine if more results available
        hasMoreResults = (response.next != nil)
        
        print("   Total results in list: \(flightResults.count)")
        print("   Total available: \(totalResultsCount)")
        print("   Cache complete: \(isCacheComplete)")
        print("   Has more results: \(hasMoreResults)")
        
        if response.next == nil {
            print("🏁 No more pages available - all results loaded!")
            hasMoreResults = false
        }
    }
    
    func selectFlight(_ flight: FlightResult) {
        selectedFlight = flight
        
        // Log selected flight details
        print("✈️ Selected flight:")
        print("   ID: \(flight.id)")
        print("   Duration: \(flight.formattedDuration)")
        print("   Price: \(flight.formattedPrice)")
        print("   Legs: \(flight.legs.count)")
        
        for (index, leg) in flight.legs.enumerated() {
            print("   Leg \(index + 1):")
            print("     \(leg.originCode) → \(leg.destinationCode)")
            print("     Departure: \(leg.formattedDepartureTime)")
            print("     Arrival: \(leg.formattedArrivalTime)")
            print("     Stops: \(leg.stopsText)")
        }
    }
    
    // ✅ FINAL CORRECTED: Apply filters method with ads preservation - no compilation errors
    func applyFilters(request: PollRequest) {
        guard let searchId = searchId else {
            print("❌ Cannot apply filters: no searchId")
            return
        }
        
        // ✅ ENHANCED: Detailed filter debug logging
        print("\n🔧 ===== APPLYING FILTERS DEBUG =====")
        print("🔍 Filter Request Analysis:")
        print("   Search ID: \(searchId)")
        print("   Has Filters: \(request.hasFilters())")
        print("   Previous Filter State: \(isFilteredResults)")
        print("   Previous Results Count: \(flightResults.count)")
        
        // Log each filter type with detailed breakdown
        if let duration = request.duration_max {
            print("   ⏱️ Duration Filter: ≤ \(duration) minutes (\(duration/60)h \(duration%60)m)")
        }
        if let stops = request.stop_count_max {
            let stopText = stops == 0 ? "Direct only" : "≤ \(stops) stops"
            print("   🛑 Stops Filter: \(stopText)")
        }
        if let stopsMin = request.stop_count_min {
            print("   🛑 Min Stops Filter: ≥ \(stopsMin) stops")
        }
        if let exactStops = request.stop_count_exact {
            print("   🛑 Exact Stops Filter: = \(exactStops) stops")
        }
        if let priceMin = request.price_min {
            print("   💰 Price Min Filter: ≥ ₹\(priceMin)")
        }
        if let priceMax = request.price_max {
            print("   💰 Price Max Filter: ≤ ₹\(priceMax)")
        }
        if let airlines = request.iata_codes_include, !airlines.isEmpty {
            print("   ✈️ Include Airlines Filter: \(airlines.joined(separator: ", "))")
        }
        if let excludeAirlines = request.iata_codes_exclude, !excludeAirlines.isEmpty {
            print("   🚫 Exclude Airlines Filter: \(excludeAirlines.joined(separator: ", "))")
        }
        if let sortBy = request.sort_by {
            let sortOrder = request.sort_order ?? "asc"
            print("   📊 Sort Filter: \(sortBy) (\(sortOrder))")
        }
        if let timeRanges = request.arrival_departure_ranges, !timeRanges.isEmpty {
            print("   🕐 Time Filters: \(timeRanges.count) leg(s)")
            for (index, range) in timeRanges.enumerated() {
                let depStart = minutesToTimeString(range.departure.min)
                let depEnd = minutesToTimeString(range.departure.max)
                let arrStart = minutesToTimeString(range.arrival.min)
                let arrEnd = minutesToTimeString(range.arrival.max)
                print("     Leg \(index + 1): Dep \(depStart)-\(depEnd), Arr \(arrStart)-\(arrEnd)")
            }
        }
        if let agenciesInclude = request.agency_include, !agenciesInclude.isEmpty {
            print("   🏢 Include Agencies: \(agenciesInclude.joined(separator: ", "))")
        }
        if let agenciesExclude = request.agency_exclude, !agenciesExclude.isEmpty {
            print("   🚫 Exclude Agencies: \(agenciesExclude.joined(separator: ", "))")
        }
        
        // ✅ CRITICAL FIX: Store filter state for pagination
        currentFilterRequest = request
        isFilteredResults = request.hasFilters()
        
        print("🔧 Filter State Updated:")
        print("   currentFilterRequest stored: ✓")
        print("   isFilteredResults: \(isFilteredResults)")
        
        // Stop continuous polling when applying filters
        shouldContinuouslyPoll = false
        print("   shouldContinuouslyPoll: \(shouldContinuouslyPoll)")
        
        // ✅ PRESERVE ADS STATE: Store current ads before resetting
        let currentAds = adsService.ads
        let adsLoaded = hasLoadedAds
        
        print("🎯 ADS STATE PRESERVATION:")
        print("   Current ads count: \(currentAds.count)")
        print("   Has loaded ads: \(adsLoaded)")
        print("   ✅ Ads state preserved before reset")
        
        // Reset pagination when applying filters
        resetPagination()
        shouldContinuouslyPoll = false // Keep polling stopped for filter results
        
        // ✅ RESTORE ADS STATE: Restore ads after pagination reset
        adsService.ads = currentAds
        hasLoadedAds = adsLoaded
        
        print("   ✅ Ads state restored after pagination reset")
        print("   Restored ads count: \(adsService.ads.count)")
        print("   Restored hasLoadedAds: \(hasLoadedAds)")
        
        isLoading = true
        errorMessage = nil
        flightResults = [] // Clear existing results
        totalPollCount += 1
        
        print("📡 Making filtered poll request (poll #\(totalPollCount))")
        print("   ✅ Filter request will use INITIAL page size: \(initialPageSize)")
        print("   🔧 Storing filter state for future pagination")
        print("🔧 ===== END APPLYING FILTERS DEBUG =====\n")
        
        pollApi.pollFlights(
            searchId: searchId,
            request: request,
            limit: initialPageSize
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    print("\n✅ ===== FILTER RESULTS DEBUG =====")
                    print("✅ Filter poll successful!")
                    print("   Filtered results count: \(response.count)")
                    print("   Results in this batch: \(response.results.count)")
                    print("   Cache status: \(response.cache)")
                    print("   Next page available: \(response.next != nil)")
                    
                    // Log filter effectiveness
                    if response.results.isEmpty {
                        print("   ⚠️ No flights match the applied filters")
                        print("   💡 Consider relaxing some filter criteria")
                    } else {
                        print("   ✅ Found \(response.results.count) flights matching filters")
                    }
                    
                    // ✅ ADS STATE VERIFICATION AFTER SUCCESS
                    print("\n🎯 ADS STATE VERIFICATION (After Filter Success):")
                    print("   Ads count in service: \(self.adsService.ads.count)")
                    print("   hasLoadedAds flag: \(self.hasLoadedAds)")
                    
                    if !self.adsService.ads.isEmpty {
                        print("   ✅ Ads successfully preserved through filter operation")
                        print("   📋 Sample ads preserved:")
                        for (index, ad) in self.adsService.ads.prefix(3).enumerated() {
                            print("     \(index + 1). \(ad.headline) - \(ad.companyName)")
                        }
                    } else if self.hasLoadedAds {
                        print("   ⚠️ hasLoadedAds is true but ads array is empty")
                    } else {
                        print("   ℹ️ No ads were loaded for this search")
                    }
                    
                    // Log sample filtered results
                    if !response.results.isEmpty {
                        print("📋 Sample Filtered Results (first 3):")
                        for (index, flight) in response.results.prefix(3).enumerated() {
                            if let firstLeg = flight.legs.first {
                                print("   \(index + 1). \(firstLeg.originCode)-\(firstLeg.destinationCode) | ₹\(Int(flight.min_price)) | \(flight.formattedDuration)")
                                
                                // Log airline information for airline filter verification
                                let airlines = flight.legs.flatMap { leg in
                                    leg.segments.map { $0.airlineIata }
                                }.joined(separator: ", ")
                                print("      Airlines: \(airlines)")
                                
                                // Log stops information for stops filter verification
                                if let firstLeg = flight.legs.first {
                                    let stops = firstLeg.segments.count - 1
                                    print("      Stops: \(stops)")
                                }
                            }
                        }
                    }
                    
                    // ✅ Update results and properties directly
                    self.pollResponse = response
                    self.totalResultsCount = response.count
                    self.isCacheComplete = response.cache
                    self.nextPageURL = response.next
                    self.hasMoreResults = (response.next != nil)
                    self.flightResults = response.results
                    
                    // ✅ CRITICAL: Update available airlines with new filtered data
                    if !response.airlines.isEmpty {
                        print("   ✅ Updating available airlines from filtered results:")
                        print("   Airlines in filtered response: \(response.airlines.count)")
                        
                        // This should be handled by your FilterViewModel update method
                        // You might need to trigger an update here if the airlines list should change
                        // based on filtered results
                    }
                    
                    print("✅ ===== END FILTER RESULTS DEBUG =====\n")
                    
                case .failure(let error):
                    print("\n❌ ===== FILTER ERROR DEBUG =====")
                    print("❌ Filter poll failed!")
                    print("   Error: \(error.localizedDescription)")
                    print("   Search ID: \(searchId)")
                    print("   Applied Filters: \(request.hasFilters() ? "YES" : "NO")")
                    
                    if let afError = error.asAFError {
                        print("   AF Error: \(afError)")
                        if let responseCode = afError.responseCode {
                            print("   Response Code: \(responseCode)")
                        }
                    }
                    
                    // ✅ ADS STATE VERIFICATION AFTER ERROR
                    print("\n🎯 ADS STATE VERIFICATION (After Filter Error):")
                    print("   Ads count in service: \(self.adsService.ads.count)")
                    print("   hasLoadedAds flag: \(self.hasLoadedAds)")
                    
                    if !self.adsService.ads.isEmpty {
                        print("   ✅ Ads preserved despite filter error")
                    } else {
                        print("   ⚠️ Ads may have been lost during error")
                    }
                    
                    self.errorMessage = "Failed to apply filters: \(error.localizedDescription)"
                    print("❌ ===== END FILTER ERROR DEBUG =====\n")
                }
            }
        }
    }
    
    // ✅ Helper function to convert minutes to time string
    private func minutesToTimeString(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }
    
    // Check if we should load more results based on scroll position
    func shouldLoadMore(currentItem: FlightResult) -> Bool {
        guard let lastItem = flightResults.last else { return false }
        
        // Don't trigger if already loading or no search ID
        guard !isLoadingMore, !isLoading, searchId != nil else { return false }
        
        // Only load more if next page is available
        guard hasMoreResults else {
            return false
        }
        
        // Load more when we're 3 items from the end (for better UX)
        let thresholdIndex = max(0, flightResults.count - 3)
        let currentIndex = flightResults.firstIndex { $0.id == currentItem.id } ?? 0
        
        let shouldLoad = currentIndex >= thresholdIndex
        
        if shouldLoad {
            print("🔄 Should load more:")
            print("   Current item index: \(currentIndex)/\(flightResults.count - 1)")
            print("   Threshold: \(thresholdIndex)")
            print("   Results: \(flightResults.count)/\(totalResultsCount)")
            print("   Has more: \(hasMoreResults)")
            print("   Next page available: \(nextPageURL != nil)")
            print("   ✅ Will load \(subsequentPageSize) more results")
            print("   🔧 Will maintain filter state: \(isFilteredResults)")
        }
        
        return shouldLoad
    }
    
    // Call this when the view disappears to stop polling
    func stopPolling() {
        shouldContinuouslyPoll = false
        print("🛑 Polling stopped")
    }
    


    
    
    // Load ads for search - integrate with existing flight search
    func loadAdsForSearch(searchParameters: SearchParameters) {
        guard !hasLoadedAds else {
            print("🎯 Ads already loaded for this search")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: searchParameters.departureDate)
        
        // Convert TravelClass to string
        let cabinClass: String
        switch searchParameters.selectedClass {
        case .economy:
            cabinClass = "economy"
        case .premiumEconomy:
            cabinClass = "premium_economy"
        case .business:
            cabinClass = "business"
        case .firstClass:
            cabinClass = "first"
        }
        
        // Create passengers array
        let passengerCount = searchParameters.adults + searchParameters.children + searchParameters.infants
        let passengers = Array(repeating: "adult", count: max(1, passengerCount))
        
        Task {
            await adsService.searchFlightAds(
                originAirport: searchParameters.originCode,
                destinationAirport: searchParameters.destinationCode,
                date: dateString,
                cabinClass: cabinClass,
                passengers: passengers
            )
        }
        
        hasLoadedAds = true
        print("🎯 Initiated ads loading for route: \(searchParameters.originCode) → \(searchParameters.destinationCode)")
        print("🎯 Search parameters - Date: \(dateString), Class: \(cabinClass), Passengers: \(passengers.count)")
    }
    
    deinit {
        shouldContinuouslyPoll = false
    }
}
