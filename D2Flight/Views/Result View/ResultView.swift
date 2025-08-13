import SwiftUI

// ✅ Content type enum for mixing flights and ads
enum ContentType {
    case flight(FlightResult)
    case ad(AdResponse)
}

struct ResultView: View {
    @StateObject private var viewModel = ResultViewModel()
    @StateObject private var headerViewModel = ResultHeaderViewModel()
    @StateObject private var flightSearchVM = FlightSearchViewModel() // NEW: For new searches
    @State private var selectedFlight: FlightResult? = nil
    @State private var navigateToDetails = false

    // ★ Only show loader on first entry ★
    @State private var showAnimatedLoader = false
    @State private var hasInitialized = false
    @State private var isInitialLoad = false  // Track if this is the initial load

    // To cancel any pending hide task
    @State private var loaderHideWorkItem: DispatchWorkItem? = nil

    // Passed in from FlightView
    let searchId: String?
    @State private var searchParameters: SearchParameters // NEW: Make this mutable for updates
    
    // NEW: Navigation state for new searches
    @State private var navigateToNewResults = false
    @State private var newSearchId: String? = nil
    @State private var newSearchParameters: SearchParameters? = nil

    init(searchId: String?, searchParameters: SearchParameters) {
        self.searchId = searchId
        self._searchParameters = State(initialValue: searchParameters)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: 1) Fixed Top Filter Bar with Edit Functionality
                ResultHeaderView(
                    headerViewModel: headerViewModel,
                    originCode: searchParameters.originCode,
                    destinationCode: searchParameters.destinationCode,
                    isRoundTrip: searchParameters.isRoundTrip,
                    travelDate: searchParameters.formattedTravelDate,
                    travelerInfo: searchParameters.formattedTravelerInfo,
                    onFiltersChanged: { pollRequest in
                        print("🔧 Applying filters from ResultHeader")
                        viewModel.applyFilters(request: pollRequest)
                    },
                    // NEW: Handle search parameter updates
                    onSearchUpdated: { updatedSearchParams in
                        handleSearchParametersUpdate(updatedSearchParams)
                    },
                    initialSearchParams: searchParameters
                )
                .padding()
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .zIndex(1)

                // MARK: 2) Content Area
                if viewModel.isLoading {
                    // A) Shimmer placeholders
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0..<5, id: \.self) { _ in
                                ShimmerResultCard(isRoundTrip: searchParameters.isRoundTrip)
                            }
                        }
                        .padding()
                    }
                    .scrollIndicators(.hidden)

                } else if let error = viewModel.errorMessage {
                    // B) Error State
                    VStack(spacing: 20) {
                        Image("SomethingErrorImg")
                        Text("Something went wrong!")
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
                            if let searchId = searchId {
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
                                            isRoundTrip: searchParameters.isRoundTrip
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
                            
                            // Loading indicator for pagination
                            if viewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Loading more flights...")
                                            .font(CustomFont.font(.small))
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 20)
                            }
                            
                            // Cache complete indicator
                            if !viewModel.hasMoreResults && !viewModel.flightResults.isEmpty {
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
            // NEW: Navigation for new search results
            .navigationDestination(isPresented: Binding(
                get: { newSearchId != nil && navigateToNewResults && newSearchParameters != nil },
                set: { newValue in
                    if !newValue {
                        newSearchId = nil
                        navigateToNewResults = false
                        newSearchParameters = nil
                    }
                }
            )) {
                if let validNewSearchId = newSearchId,
                   let newSearchParams = newSearchParameters {
                    ResultView(searchId: validNewSearchId, searchParameters: newSearchParams)
                } else {
                    Text("Invalid Search Parameters")
                }
            }
            .onAppear {
                // Only start polling (and loader) once, on first appear
                guard !hasInitialized else { return }
                hasInitialized = true
                isInitialLoad = true

                if let searchId = searchId {
                    print("🚀 Starting initial poll for searchId: \(searchId)")
                    viewModel.pollFlights(searchId: searchId)
                    
                    // ✅ Load ads in parallel
                    viewModel.loadAdsForSearch(searchParameters: searchParameters)
                }
            }
            // NEW: Handle new search results from FlightSearchViewModel
            .onReceive(flightSearchVM.$searchId) { newSearchIdFromVM in
                if let searchId = newSearchIdFromVM {
                    newSearchId = searchId
                    navigateToNewResults = true
                    print("🔍 ResultView: New search initiated, navigating to new results with searchId: \(searchId)")
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
                // Only trigger loader‐logic for the initial load, not for filter changes
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
        // Full‐screen loader cover
        .fullScreenCover(isPresented: $showAnimatedLoader) {
            AnimatedResultLoader(isVisible: $showAnimatedLoader)
        }
    }
    
    // NEW: Handle search parameter updates from edit sheet
    private func handleSearchParametersUpdate(_ updatedParams: SearchParameters) {
        print("🔄 ResultView: Handling search parameter update")
        
        // Update local search parameters
        searchParameters = updatedParams
        newSearchParameters = updatedParams
        
        // Configure FlightSearchViewModel with new parameters
        flightSearchVM.departureIATACode = updatedParams.originCode
        flightSearchVM.destinationIATACode = updatedParams.destinationCode
        flightSearchVM.isRoundTrip = updatedParams.isRoundTrip
        flightSearchVM.travelDate = updatedParams.departureDate
        
        if updatedParams.isRoundTrip, let returnDate = updatedParams.returnDate {
            flightSearchVM.returnDate = returnDate
        } else if updatedParams.isRoundTrip {
            // Default return date if not specified
            flightSearchVM.returnDate = Calendar.current.date(byAdding: .day, value: 2, to: updatedParams.departureDate) ?? updatedParams.departureDate.addingTimeInterval(86400 * 2)
        }
        
        flightSearchVM.adults = updatedParams.adults
        flightSearchVM.childrenAges = Array(repeating: 2, count: updatedParams.children)
        flightSearchVM.cabinClass = updatedParams.selectedClass.rawValue
        
        print("🚀 Starting new flight search with updated parameters")
        
        // Start the new search
        flightSearchVM.searchFlights()
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
}

// MARK: - Supporting View for ResultHeaderView (wrapper for the updated ResultHeader)
struct ResultHeaderView: View {
    @ObservedObject var headerViewModel: ResultHeaderViewModel
    let originCode: String
    let destinationCode: String
    let isRoundTrip: Bool
    let travelDate: String
    let travelerInfo: String
    let onFiltersChanged: (PollRequest) -> Void
    let onSearchUpdated: ((SearchParameters) -> Void)?
    let initialSearchParams: SearchParameters?
    
    init(
        headerViewModel: ResultHeaderViewModel,
        originCode: String,
        destinationCode: String,
        isRoundTrip: Bool,
        travelDate: String,
        travelerInfo: String,
        onFiltersChanged: @escaping (PollRequest) -> Void,
        onSearchUpdated: ((SearchParameters) -> Void)? = nil,
        initialSearchParams: SearchParameters? = nil
    ) {
        self.headerViewModel = headerViewModel
        self.originCode = originCode
        self.destinationCode = destinationCode
        self.isRoundTrip = isRoundTrip
        self.travelDate = travelDate
        self.travelerInfo = travelerInfo
        self.onFiltersChanged = onFiltersChanged
        self.onSearchUpdated = onSearchUpdated
        self.initialSearchParams = initialSearchParams
    }
    
    var body: some View {
        ResultHeader(
            originCode: originCode,
            destinationCode: destinationCode,
            isRoundTrip: isRoundTrip,
            travelDate: travelDate,
            travelerInfo: travelerInfo,
            onFiltersChanged: onFiltersChanged,
            onSearchUpdated: onSearchUpdated,
            initialSearchParams: initialSearchParams
        )
    }
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
