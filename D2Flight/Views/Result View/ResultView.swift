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
    @State private var isInitialLoad = false  // Track if this is the initial load

    // To cancel any pending hide task
    @State private var loaderHideWorkItem: DispatchWorkItem? = nil

    // Passed in from FlightView
    let searchId: String?
    let searchParameters: SearchParameters

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: 1) Fixed Top Filter Bar
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
                    }
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
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("Something went wrong")
                            .font(.system(size: 20, weight: .semibold))

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
                    // C) Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "airplane.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("No flights found")
                            .font(.system(size: 20, weight: .semibold))

                        Text("Try adjusting your search criteria or filters")
                            .font(CustomFont.font(.regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
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
        // Add debug info for development
//        .debugPagination(viewModel: viewModel)
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
