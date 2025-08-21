import SwiftUI

// ✅ Content type enum for mixing flights and ads
enum ContentType {
    case flight(FlightResult)
    case ad(AdResponse)
}

struct ResultView: View {
    @StateObject private var viewModel = ResultViewModel()
    @StateObject private var headerViewModel = ResultHeaderViewModel()
    @State private var selectedFlight: FlightResult? = nil
    @State private var navigateToDetails = false

    // ★ Only show loader on first entry ★
    @State private var showAnimatedLoader = false
    @State private var hasInitialized = false
    @State private var isInitialLoad = false

    // To cancel any pending hide task
    @State private var loaderHideWorkItem: DispatchWorkItem? = nil

    // ✅ NEW: Current search and parameters state
    @State private var currentSearchId: String?
    @State private var currentSearchParameters: SearchParameters
    
    // ✅ NEW: Edit search sheet state
    @State private var showEditSearchSheet = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: 1) Fixed Top Filter Bar with Edit Functionality
                ResultHeader(
                    originCode: currentSearchParameters.originCode,
                    destinationCode: currentSearchParameters.destinationCode,
                    isRoundTrip: currentSearchParameters.isRoundTrip,
                    travelDate: currentSearchParameters.formattedTravelDate,
                    travelerInfo: currentSearchParameters.formattedTravelerInfo,
                    searchParameters: currentSearchParameters,
                    onFiltersChanged: { pollRequest in
                        print("🔧 Applying filters from ResultHeader")
                        viewModel.applyFilters(request: pollRequest)
                    },
                    onEditSearchCompleted: { newSearchId, updatedParams in
                        print("🔄 Edit search completed - New searchId: \(newSearchId)")
                        handleEditSearchCompleted(newSearchId: newSearchId, updatedParams: updatedParams)
                    },
                    onEditButtonTapped: {
                        // ✅ NEW: Trigger edit sheet with smooth animation
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showEditSearchSheet = true
                        }
                    }
                )
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .zIndex(1)

                // MARK: 2) Content Area
                if viewModel.isLoading {
                    // A) Shimmer placeholders
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0..<5, id: \.self) { _ in
                                ShimmerResultCard(isRoundTrip: currentSearchParameters.isRoundTrip)
                            }
                        }
                        .padding()
                    }
                    .scrollIndicators(.hidden)

                } else if let error = viewModel.errorMessage {
                    // B) Error State
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
                            if let searchId = currentSearchId {
                                viewModel.pollFlights(searchId: searchId)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)

                } else if viewModel.flightResults.isEmpty {
                    FilterNoFlights()
                        .frame(maxHeight: .infinity)
                } else {
                    // D) Success: list of flight results with ads integration
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // ✅ Mix flight results and ads
                            ForEach(Array(generateMixedContent().enumerated()), id: \.offset) { index, content in
                                switch content {
                                case .flight(let flight):
                                    Button {
                                        viewModel.selectFlight(flight)
                                        selectedFlight = flight
                                        navigateToDetails = true
                                    } label: {
                                        ResultCard(
                                            flight: flight,
                                            isRoundTrip: currentSearchParameters.isRoundTrip
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .onAppear {
                                        // Trigger pagination when user scrolls near the bottom
                                        if viewModel.shouldLoadMore(currentItem: flight) {
                                            print("🔄 Triggering load more for item: \(flight.id)")
                                            viewModel.loadMoreResults()
                                        }
                                    }
                                    
                                case .ad(let ad):
                                    AdCardView(ad: ad) {
                                        print("🎯 Ad tapped: \(ad.headline)")
                                    }
                                }
                            }
                            
                            // ✅ UPDATED: Smart loading/completion indicator
                            if viewModel.isLoadingMore {
                                // Show loading when actively loading more results
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
                                
                            } else if viewModel.hasMoreResults && !viewModel.flightResults.isEmpty {
                                // Show "Load More" option when pagination is available but not actively loading
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Button(action: {
                                            viewModel.loadMoreResults()
                                        }) {
                                            HStack {
                                                Text("load.more.flights".localized)
                                                    .font(CustomFont.font(.small, weight: .semibold))
                                                    .foregroundColor(Color("Violet"))
                                                Image(systemName: "chevron.down")
                                                    .font(CustomFont.font(.small))
                                                    .foregroundColor(Color("Violet"))
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color("Violet").opacity(0.1))
                                            )
                                        }
                                        
                                        Text("Showing \(viewModel.flightResults.count) of \(viewModel.totalResultsCount) flights")
                                            .font(CustomFont.font(.small))
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 20)
                                
                            } else if !viewModel.hasMoreResults && !viewModel.flightResults.isEmpty && viewModel.isCacheComplete {
                                // ✅ ONLY show completion message when cache is complete AND no more pagination
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
                        }
                        .padding()
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .tabBar)
            .background(.gray.opacity(0.2))
            .navigationDestination(isPresented: $navigateToDetails) {
                if let flight = selectedFlight {
                    ResultDetails(flight: flight)
                }
            }
            .onAppear {
                // Only start polling (and loader) once, on first appear
                guard !hasInitialized else { return }
                hasInitialized = true
                isInitialLoad = true

                if let searchId = searchId {
                    print("🚀 Starting initial poll for searchId: \(searchId)")
                    currentSearchId = searchId
                    viewModel.pollFlights(searchId: searchId)
                    
                    // ✅ Load ads in parallel
                    viewModel.loadAdsForSearch(searchParameters: currentSearchParameters)
                }
            }
            // ✅ Handle poll response updates
            .onReceive(viewModel.$pollResponse) { pollResponse in
                if let response = pollResponse {
                    // Log the response
                    print("🖥️ ResultView received poll response with \(response.results.count) results")
                    print("🖥️ Total available flights: \(response.count)")
                    print("🖥️ Available airlines: \(response.airlines.map { $0.airlineName }.joined(separator: ", "))")
                    
                    // Update header with poll data
                    headerViewModel.updatePollData(response)
                    print("✅ Updated ResultHeader with API data")
                }
            }
            // ✅ Handle flight results updates
            .onReceive(viewModel.$flightResults) { flightResults in
                print("🖥️ ResultView received \(flightResults.count) flight results")
                for (index, flight) in flightResults.enumerated() {
                    print("   Flight \(index + 1): \(flight.legs.first?.originCode ?? "?") → \(flight.legs.first?.destinationCode ?? "?") - \(flight.formattedPrice)")
                }
            }
            // ✅ Handle ads updates
            .onReceive(viewModel.adsService.$ads) { ads in
                print("🎯 ResultView received \(ads.count) ads")
                for (index, ad) in ads.enumerated() {
                    print("   Ad \(index + 1): \(ad.headline) - \(ad.companyName)")
                }
            }
            // ✅ Handle ads errors (silently)
            .onReceive(viewModel.adsService.$adsErrorMessage) { error in
                if let error = error {
                    print("🎯 Ads loading error (non-blocking): \(error)")
                }
            }
            // ✅ Handle initial loading state for animated loader
            .onReceive(viewModel.$isLoading) { isLoading in
                // Only trigger loader‐logic for the initial load, not for filter changes or edit searches
                guard hasInitialized && isInitialLoad else { return }

                if isLoading {
                    // Cancel any pending hide task
                    loaderHideWorkItem?.cancel()

                    // Immediately show the loader
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAnimatedLoader = true
                    }

                    // Schedule hiding after 7 seconds
                    let task = DispatchWorkItem {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAnimatedLoader = false
                        }
                    }
                    loaderHideWorkItem = task
                    DispatchQueue.main.asyncAfter(deadline: .now() + 7.0, execute: task)

                } else {
                    // When initial loading completes, mark it as no longer initial load
                    isInitialLoad = false
                }
            }
            
            
        }
        .topSheet(isPresented: $showEditSearchSheet, maxHeightRatio: 0.6) {
            EditSearchSheet(
                isPresented: $showEditSearchSheet,
                searchParameters: $currentSearchParameters
            ) { newSearchId, updatedParams in
                handleEditSearchCompleted(newSearchId: newSearchId, updatedParams: updatedParams)
            }
        }


        // Full‐screen loader cover
        .fullScreenCover(isPresented: $showAnimatedLoader) {
            AnimatedResultLoader(isVisible: $showAnimatedLoader)
        }
    }
    
    // ✅ FIXED: Handle edit search completion with proper filter reset
    private func handleEditSearchCompleted(newSearchId: String, updatedParams: SearchParameters) {
        print("🔄 Handling edit search completion:")
        print("   Previous searchId: \(currentSearchId ?? "nil")")
        print("   New searchId: \(newSearchId)")
        print("   Previous route: \(currentSearchParameters.originCode) → \(currentSearchParameters.destinationCode)")
        print("   New route: \(updatedParams.originCode) → \(updatedParams.destinationCode)")
        
        // Update current state
        currentSearchId = newSearchId
        currentSearchParameters = updatedParams
        
        // Stop any ongoing polling
        viewModel.stopPolling()
        
        // Reset ViewModel state for new search
        viewModel.flightResults = []
        viewModel.errorMessage = nil
        viewModel.hasMoreResults = true
        viewModel.totalResultsCount = 0
        
        // ✅ FIXED: Reset filter state for new search (now accessible)
        viewModel.resetFilterState() // Use the new method instead of direct access
        headerViewModel.filterViewModel.resetFilters()
        
        print("🔄 Filter state reset for new search")
        
        // Start new poll with updated search ID
        viewModel.pollFlights(searchId: newSearchId)
        
        // Load new ads for updated search parameters
        viewModel.loadAdsForSearch(searchParameters: updatedParams)
        
        print("✅ Edit search workflow completed - polling started for new search")
    }
    
    // ✅ Generate mixed content with flights and ads
    private func generateMixedContent() -> [ContentType] {
        var mixedContent: [ContentType] = []
        let flights = viewModel.flightResults
        let ads = viewModel.adsService.ads
        
        // Add all flights first
        for flight in flights {
            mixedContent.append(.flight(flight))
        }
        
        // Insert ads at strategic positions (every 3-4 flights)
        var adIndex = 0
        let positions = [2, 6, 10, 15, 20, 25, 30] // Positions where ads should appear
        
        for position in positions {
            // Only insert ad if we have ads available and the position is valid
            if position < mixedContent.count && adIndex < ads.count {
                mixedContent.insert(.ad(ads[adIndex]), at: position + adIndex)
                adIndex += 1
            } else if adIndex >= ads.count {
                // No more ads to insert
                break
            }
        }
        
        print("🎯 Generated mixed content: \(flights.count) flights + \(adIndex) ads = \(mixedContent.count) total items")
        
        return mixedContent
    }
    
    // ✅ UPDATED: Initialize with current parameters
    init(searchId: String?, searchParameters: SearchParameters) {
        self.searchId = searchId
        self._currentSearchParameters = State(initialValue: searchParameters)
        self._currentSearchId = State(initialValue: searchId)
    }
    
    // Store the initial searchId as a property
    private let searchId: String?
}

// MARK: - Preview
#Preview {
    // Create sample data for preview
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
    
    ResultView(
        searchId: "sample-search-id",
        searchParameters: sampleSearchParams
    )
}
