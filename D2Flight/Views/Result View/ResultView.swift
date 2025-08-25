import SwiftUI

// MARK: - Content type enum for mixing flights and ads
enum ContentType {
    case flight(FlightResult)
    case ad(AdResponse)
}

// MARK: - Performance Optimized ResultView
struct ResultView: View {
    // MARK: - Global Loader Binding from FlightView (the ONLY loader)
    @Binding var globalLoaderVisible: Bool
    
    // MARK: - Core ViewModels (Lazy initialization where possible)
    @StateObject private var viewModel = ResultViewModel()
    @StateObject private var sharedFilterViewModel = FilterViewModel()
    @StateObject private var headerViewModel = ResultHeaderViewModel()
    
    // MARK: - Navigation State
    @State private var selectedFlight: FlightResult? = nil
    @State private var navigateToDetails = false
    
    // MARK: - Init/State not related to loader
    @State private var hasInitialized = false
    
    // MARK: - Search Parameters
    @State private var currentSearchId: String?
    @State private var currentSearchParameters: SearchParameters
    @State private var showEditSearchSheet = false
    
    // MARK: - Performance Optimization States
    @State private var isViewAppeared = false
    @State private var contentItems: [ContentType] = []
    @State private var isProcessingContent = false
    
    // MARK: - Track filter application phase to avoid flashing "no flights"
    @State private var isApplyingFilters = false

    // MARK: - Debounced "settled" flag to suppress early Load More/Completion
    @State private var hasSettledInitialResults = false
    @State private var settleDebounceID: Int = 0

    // MARK: - Guards
    private var shouldShowCompletion: Bool {
        hasSettledInitialResults &&     // wait until initial results have settled
        !viewModel.isLoading &&         // initial / filter apply / edit search off
        !viewModel.isLoadingMore &&     // not paging
        !isApplyingFilters &&           // not applying filters
        !isProcessingContent &&         // not mixing flights + ads
        !viewModel.hasMoreResults &&    // nothing left to load
        !viewModel.flightResults.isEmpty &&
        viewModel.isCacheComplete
    }
    
    private var shouldShowLoadMore: Bool {
        hasSettledInitialResults &&     // avoid during initial load / filter / processing
        !viewModel.isLoading &&
        !viewModel.isLoadingMore &&
        !isApplyingFilters &&
        !isProcessingContent &&
        viewModel.hasMoreResults &&     // only if more pages exist
        !viewModel.flightResults.isEmpty
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: - Fixed Top Filter Bar (Performance Optimized)
                if isViewAppeared {
                    ResultHeader(
                        originCode: currentSearchParameters.originCode,
                        destinationCode: currentSearchParameters.destinationCode,
                        isRoundTrip: currentSearchParameters.isRoundTrip,
                        travelDate: currentSearchParameters.formattedTravelDate,
                        travelerInfo: currentSearchParameters.formattedTravelerInfo,
                        searchParameters: currentSearchParameters,
                        filterViewModel: sharedFilterViewModel,
                        onFiltersChanged: { pollRequest in
                            handleFiltersChanged(pollRequest)
                        },
                        onEditSearchCompleted: { newSearchId, updatedParams in
                            handleEditSearchCompleted(newSearchId: newSearchId, updatedParams: updatedParams)
                        },
                        onEditButtonTapped: {
                            showEditSearchSheet = true
                        },
                        onClearAllFilters: {
                            handleClearAllFilters()
                        }
                    )
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .zIndex(1)
                } else {
                    // Header placeholder during very early stage (under the global loader anyway)
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: 120)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .zIndex(1)
                }
                
                // MARK: - Content Area (Optimized Loading)
                Group {
                    if viewModel.isLoading && !hasInitialized {
                        // Optional: initial shimmer (usually covered by the global loader)
                        initialLoadingView
                    } else if let error = viewModel.errorMessage {
                        // Error state
                        errorView(error)
                    } else if viewModel.flightResults.isEmpty {
                        // Show shimmer instead of FilterNoFlights when filtering/loading
                        if viewModel.isLoading || isApplyingFilters {
                            initialLoadingView
                        } else {
                            FilterNoFlights(onClearAll: { clearAllFiltersFromNoFlights() })
                                .frame(maxHeight: .infinity)
                        }
                    } else {
                        // Success: Optimized content list
                        optimizedContentView
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .tabBar)
            .background(.gray.opacity(0.2))
        }
        
        // MARK: - Navigation and Sheets
        .navigationDestination(isPresented: $navigateToDetails) {
            if let flight = selectedFlight {
                NavigationLazyView(ResultDetails(flight: flight))
            }
        }
        
        .topSheet(isPresented: $showEditSearchSheet, maxHeightRatio: 0.6) {
            NavigationLazyView(
                EditSearchSheet(
                    isPresented: $showEditSearchSheet,
                    searchParameters: $currentSearchParameters
                ) { newSearchId, updatedParams in
                    handleEditSearchCompleted(newSearchId: newSearchId, updatedParams: updatedParams)
                }
            )
        }
        
        // MARK: - Optimized Lifecycle Events
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
                globalLoaderVisible = false
            }
            handleViewAppear()
        }


        // When poll response arrives, we only update filter VM; not needed for settle flag.

        .onReceive(viewModel.$pollResponse.throttle(for: .milliseconds(200), scheduler: RunLoop.main, latest: true)) { pollResponse in
            handlePollResponse(pollResponse)
        }
        
        .onReceive(viewModel.$flightResults.throttle(for: .milliseconds(300), scheduler: RunLoop.main, latest: true)) { flightResults in
            handleFlightResultsUpdate(flightResults)
            if !viewModel.isLoading { isApplyingFilters = false }
            scheduleSettleCheck()
        }
        
        .onReceive(viewModel.adsService.$ads.throttle(for: .milliseconds(500), scheduler: RunLoop.main, latest: true)) { _ in
            handleAdsUpdate(viewModel.adsService.ads)
            scheduleSettleCheck()
        }
        
        .onReceive(viewModel.$isLoading.debounce(for: .milliseconds(100), scheduler: RunLoop.main)) { isLoading in
            if !isLoading { isApplyingFilters = false }
            scheduleSettleCheck()
        }

        // Track local state changes and re-run the debounce
        .onChange(of: isProcessingContent) { _ in scheduleSettleCheck() }
        .onChange(of: isApplyingFilters) { _ in scheduleSettleCheck() }
        .onChange(of: hasInitialized) { _ in scheduleSettleCheck() }
    }
    
    // MARK: - Initial Loading View
    private var initialLoadingView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<5, id: \.self) { _ in
                    ShimmerResultCard(isRoundTrip: currentSearchParameters.isRoundTrip)
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image("SomethingErrorImg")
            Text("something.went.wrong".localized)
                .font(.system(size: 24, weight: .semibold))

            Text(error)
                .font(CustomFont.font(.regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            PrimaryButton(
                title: "Try Again",
                font: CustomFont.font(.medium),
                fontWeight: .semibold,
                width: 150,
                height: 44,
                cornerRadius: 8
            ) {
                retrySearch()
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Optimized Content View
    private var optimizedContentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Use pre-processed content items for better performance
                ForEach(Array(contentItems.enumerated()), id: \.offset) { _, content in
                    switch content {
                    case .flight(let flight):
                        Button {
                            selectFlight(flight)
                        } label: {
                            ResultCard(
                                flight: flight,
                                isRoundTrip: currentSearchParameters.isRoundTrip
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onAppear {
                            handleFlightCardAppear(flight)
                        }
                        
                    case .ad(let ad):
                        AdCardView(ad: ad) {
                            handleAdTap(ad)
                        }
                        .id("ad-\(ad.id)")
                    }
                }
                
                // MARK: - Loading/Completion Indicator (Optimized)
                bottomIndicatorView
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Bottom Indicator View
    private var bottomIndicatorView: some View {
        Group {
            if viewModel.isLoadingMore {
                loadingMoreView
            } else if shouldShowLoadMore {
                loadMoreButtonView
            } else if shouldShowCompletion {
                completionView
            }
        }
    }

    private var loadingMoreView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("loading.more.flights".localized)
                    .font(CustomFont.font(.small))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 20)
    }
    
    private var loadMoreButtonView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                AnimatedDotsText(
                    text: "searching.flights".localized, // or "Searching flights"
                    interval: 0.5,
                    maxDots: 3,
                    color: Color("Violet"),
                    font: CustomFont.font(.small, weight: .semibold)
                )
                Text("Showing \(viewModel.flightResults.count) of \(viewModel.totalResultsCount) flights")
                    .font(CustomFont.font(.small))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 20)
    }

    
    private var completionView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(CustomFont.font(.medium))
                Text("All \(viewModel.totalResultsCount) flights loaded")
                    .font(CustomFont.font(.small))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Performance Optimized Event Handlers
    
    private func handleViewAppear() {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        // Smooth header appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isViewAppeared = true
        }
        
        if let searchId = searchId {
            print("🚀 Starting initial poll for searchId: \(searchId)")
            currentSearchId = searchId
            
            // Background initialization
            Task.detached(priority: .userInitiated) {
                await MainActor.run {
                    viewModel.pollFlights(searchId: searchId)
                    viewModel.loadAdsForSearch(searchParameters: currentSearchParameters)
                }
            }
        }
    }
    
    private func handlePollResponse(_ pollResponse: PollResponse?) {
        guard let response = pollResponse else { return }
        
        Task.detached(priority: .background) {
            // Process response data in background
            let airlines = response.airlines
            let priceRange = (response.min_price, response.max_price)
            
            await MainActor.run {
                // Update FilterViewModel efficiently
                sharedFilterViewModel.updateAvailableAirlines(from: response)
                
                print("✅ Updated FilterViewModel with API data:")
                print("   Airlines: \(airlines.count)")
                print("   Price Range: ₹\(priceRange.0) - ₹\(priceRange.1)")
            }
        }
    }
    
    private func handleFlightResultsUpdate(_ flightResults: [FlightResult]) {
        guard !isProcessingContent else { return }
        
        Task.detached(priority: .background) {
            await processContentItems(flightResults)
        }
    }
    
    @MainActor
    private func processContentItems(_ flightResults: [FlightResult]) async {
        isProcessingContent = true
        defer {
            isProcessingContent = false
        }
        
        // Generate mixed content in background
        let mixedContent = await generateMixedContentOptimized(flightResults)
        
        // Update UI
        withAnimation(.easeInOut(duration: 0.3)) {
            contentItems = mixedContent
        }
    }
    
    private func generateMixedContentOptimized(_ flights: [FlightResult]) async -> [ContentType] {
        return await Task.detached(priority: .background) {
            var mixedContent: [ContentType] = []
            let ads = await MainActor.run { viewModel.adsService.ads }
            
            // Add all flights first
            for flight in flights {
                mixedContent.append(.flight(flight))
            }
            
            // Insert ads at strategic positions
            var adIndex = 0
            let positions = [2, 6, 10, 15, 20, 25, 30]
            
            for position in positions {
                if position < mixedContent.count && adIndex < ads.count {
                    mixedContent.insert(.ad(ads[adIndex]), at: position + adIndex)
                    adIndex += 1
                } else if adIndex >= ads.count {
                    break
                }
            }
            
            return mixedContent
        }.value
    }
    
    private func handleAdsUpdate(_ ads: [AdResponse]) {
        // Regenerate content when ads are updated
        if !viewModel.flightResults.isEmpty {
            Task.detached(priority: .background) {
                await processContentItems(viewModel.flightResults)
            }
        }
    }
    
    private func handleFiltersChanged(_ pollRequest: PollRequest) {
        // Mark that we're applying filters to control UI state
        isApplyingFilters = true
        hasSettledInitialResults = false    // reset settled state
        
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                print("🔧 Applying filters from ResultHeader")
                viewModel.applyFilters(request: pollRequest)
            }
        }
    }
    
    private func handleClearAllFilters() {
        isApplyingFilters = true
        hasSettledInitialResults = false    // reset settled state
        
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                print("🗑️ Clear all filters triggered from ResultHeader")
                viewModel.clearAllFilters()
            }
        }
    }
    
    private func handleEditSearchCompleted(newSearchId: String, updatedParams: SearchParameters) {
        isApplyingFilters = true
        hasSettledInitialResults = false    // reset settled state
        
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                print("🔄 Handling edit search completion:")
                print("   Previous searchId: \(currentSearchId ?? "nil")")
                print("   New searchId: \(newSearchId)")
                
                // Update current state
                currentSearchId = newSearchId
                currentSearchParameters = updatedParams
                
                // Stop ongoing polling
                viewModel.stopPolling()
                
                // Reset states
                resetViewModelState()
                
                // Start new poll
                viewModel.pollFlights(searchId: newSearchId)
                viewModel.loadAdsForSearch(searchParameters: updatedParams)
                
                print("✅ Edit search workflow completed")
            }
        }
    }
    
    private func handleFlightCardAppear(_ flight: FlightResult) {
        if viewModel.shouldLoadMore(currentItem: flight) {
            loadMoreResults()
        }
    }
    
    private func handleAdTap(_ ad: AdResponse) {
        print("🎯 Ad tapped: \(ad.headline)")
        // Handle ad tap logic
    }
    
    // MARK: - Action Methods
    
    private func selectFlight(_ flight: FlightResult) {
        Task { @MainActor in
            viewModel.selectFlight(flight)
            selectedFlight = flight
            navigateToDetails = true
        }
    }
    
    private func loadMoreResults() {
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
                viewModel.loadMoreResults()
            }
        }
    }
    
    private func retrySearch() {
        if let searchId = currentSearchId {
            // Consider this like a new attempt → show shimmer if empty
            isApplyingFilters = true
            hasSettledInitialResults = false
            Task.detached(priority: .userInitiated) {
                await MainActor.run {
                    viewModel.pollFlights(searchId: searchId)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func scheduleSettleCheck() {
        // Debounce: bump the token and schedule a check after 250ms
        let newID = settleDebounceID &+ 1
        settleDebounceID = newID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            guard newID == settleDebounceID else { return } // another change happened; skip
            // Only mark settled when everything is calm and we have some results
            if !viewModel.isLoading,
               !isProcessingContent,
               !isApplyingFilters,
               hasInitialized,
               !viewModel.flightResults.isEmpty {
                hasSettledInitialResults = true
            }
        }
    }

    private func resetViewModelState() {
        viewModel.flightResults = []
        viewModel.errorMessage = nil
        viewModel.hasMoreResults = true
        viewModel.totalResultsCount = 0
        viewModel.resetFilterState()
        headerViewModel.filterViewModel.resetFilters()
        contentItems = []
        hasSettledInitialResults = false
    }
    
    private func clearAllFiltersFromNoFlights() {
        // reset the chips/UI state the same way ResultHeader.clearAllFilters() does
        sharedFilterViewModel.selectedSortOption = .best
        sharedFilterViewModel.maxStops = 3
        sharedFilterViewModel.departureTimeRange = 0...86400
        sharedFilterViewModel.arrivalTimeRange = 0...86400
        sharedFilterViewModel.returnDepartureTimeRange = 0...86400
        sharedFilterViewModel.returnArrivalTimeRange = 0...86400
        sharedFilterViewModel.maxDuration = 1440
        sharedFilterViewModel.selectedAirlines.removeAll()
        sharedFilterViewModel.excludedAirlines.removeAll()
        sharedFilterViewModel.selectedClass = .economy
        sharedFilterViewModel.resetPriceFilter()    // uses API range if loaded

        // trigger the network-side clear (your existing flow)
        handleClearAllFilters()
    }
    
    // MARK: - Initialization
    init(searchId: String?, searchParameters: SearchParameters, loaderBinding: Binding<Bool>) {
        self.searchId = searchId
        self._currentSearchParameters = State(initialValue: searchParameters)
        self._currentSearchId = State(initialValue: searchId)
        self._globalLoaderVisible = loaderBinding
    }
    
    private let searchId: String?
}

// MARK: - Preview
#Preview {
    let sampleSearchParams = SearchParameters(
        originCode: "NYC",
        destinationCode: "LAX",
        originName: "New York",
        destinationName: "Los Angeles",
        isRoundTrip: true,
        departureDate: Date(),
        returnDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
        adults: 2,
        children: 0,
        infants: 0,
        selectedClass: .economy
    )
    
    // Provide a constant binding for preview
    ResultView(
        searchId: "sample-search-id",
        searchParameters: sampleSearchParams,
        loaderBinding: .constant(false)
    )
}
