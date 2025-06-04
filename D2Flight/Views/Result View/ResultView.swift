import SwiftUI

struct ResultView: View {
    @StateObject private var viewModel = ResultViewModel()
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
                ResultHeader(
                    originCode: searchParameters.originCode,
                    destinationCode: searchParameters.destinationCode,
                    isRoundTrip: searchParameters.isRoundTrip,
                    travelDate: searchParameters.formattedTravelDate,
                    travelerInfo: searchParameters.formattedTravelerInfo,
                    onFiltersChanged: { pollRequest in
                        viewModel.applyFilters(request: pollRequest)
                    }
                )
                .padding()
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .zIndex(1)

                // MARK: 2) Content Area
                if viewModel.isLoading {
                    // A) Shimmer placeholders (still shown underneath)
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(0..<5, id: \.self) { _ in
                                ShimmerResultCard()
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
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        PrimaryButton(
                            title: "Try Again",
                            font: .system(size: 16),
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

                        Text("Try adjusting your search criteria")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)

                } else {
                    // D) Success: list of flight results with pagination
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.flightResults) { flight in
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
                            }
                            
                            // Loading indicator for pagination
                            if viewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Loading more flights...")
                                            .font(.system(size: 12))
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
                                            .font(.system(size: 16))
                                        Text("All \(viewModel.totalResultsCount) flights loaded")
                                            .font(.system(size: 12))
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
                isInitialLoad = true  // Mark this as initial load

                if let searchId = searchId {
                    print("🚀 Starting initial poll for searchId: \(searchId)")
                    viewModel.pollFlights(searchId: searchId)
                }
            }
            .onReceive(viewModel.$pollResponse) { pollResponse in
                // (unchanged) collect filter metadata if needed
                if let response = pollResponse {
                    print("📊 Poll response received with \(response.airlines.count) airlines")
                }
            }
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
        .debugPagination(viewModel: viewModel)
    }
}
