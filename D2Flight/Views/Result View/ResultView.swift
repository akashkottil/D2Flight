import SwiftUI

struct ResultView: View {
    @StateObject private var viewModel = ResultViewModel()
    @State private var selectedFlight: FlightResult? = nil
    @State private var navigateToDetails = false
    
    // Pass search ID directly
    let searchId: String?
    
    // Flight search data for header
    @State private var originCode: String = "KCH"
    @State private var destinationCode: String = "LON"
    @State private var isRoundTrip: Bool = false
    @State private var travelDate: String = "Wed 17 Oct"
    @State private var travelerInfo: String = "1 Traveler, 1 Economy"
    
    // AnimatedResultLoader state
    @State private var showAnimatedLoader = true
    
    var body: some View {
        ZStack {
            // Main ResultView content
            VStack(spacing: 0) {
                // Fixed Top Filter Bar with filter functionality
                ResultHeader(
                    originCode: originCode,
                    destinationCode: destinationCode,
                    isRoundTrip: isRoundTrip,
                    travelDate: travelDate,
                    travelerInfo: travelerInfo,
                    onFiltersChanged: { pollRequest in
                        print("🔍 Applying filters: \(pollRequest)")
                        viewModel.applyFilters(request: pollRequest)
                    }
                )
                .padding()
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .zIndex(1)
                
                // Content
                if viewModel.isLoading {
                    // Show shimmer while loading initial results
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
                    // Show error state
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
                    // Show empty state
                    VStack(spacing: 20) {
                        Image(systemName: "airplane.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No flights found")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Try adjusting your search criteria or filters")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    // Show flight results with pagination
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.flightResults) { flight in
                                Button {
                                    // Log and navigate to details
                                    print("🎯 Navigating to flight details:")
                                    viewModel.selectFlight(flight)
                                    selectedFlight = flight
                                    navigateToDetails = true
                                } label: {
                                    // Determine if it's round trip based on number of legs
                                    let isRoundTrip = flight.legs.count > 1
                                    ResultCard(flight: flight, isRoundTrip: isRoundTrip)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onAppear {
                                    // Check if we should load more when this item appears
                                    if viewModel.shouldLoadMore(currentItem: flight) {
                                        print("📄 Triggering load more for item: \(flight.id)")
                                        viewModel.loadMoreResults()
                                    }
                                }
                            }
                            
                            // Loading more indicator
                            if viewModel.isLoadingMore {
                                VStack(spacing: 16) {
                                    // Show 2 shimmer cards when loading more
                                    ForEach(0..<2, id: \.self) { _ in
                                        ShimmerResultCard()
                                    }
                                    
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                        Text("Loading more flights...")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                            
                            // Results summary at the bottom
                            if !viewModel.hasMoreResults && viewModel.totalResultsCount > 0 {
                                VStack(spacing: 8) {
                                    Divider()
                                        .padding(.horizontal)
                                    
                                    Text("Showing all \(viewModel.flightResults.count) of \(viewModel.totalResultsCount) flights")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 12)
                                }
                            }
                        }
                        .padding()
                    }
                    .scrollIndicators(.hidden)
                    .refreshable {
                        // Pull to refresh - reload from beginning
                        if let searchId = searchId {
                            viewModel.pollFlights(searchId: searchId)
                        }
                    }
                }
            }
            .opacity(showAnimatedLoader ? 0 : 1)
            .animation(.easeInOut(duration: 0.5), value: showAnimatedLoader)
            
            // Full-screen AnimatedResultLoader overlay
            if showAnimatedLoader {
                AnimatedResultLoader(isVisible: $showAnimatedLoader)
                    .zIndex(999) // Ensure it's on top
                    .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .background(.gray.opacity(0.2))
        .debugPagination(viewModel: viewModel) // Add debug info in debug builds
        .navigationDestination(isPresented: $navigateToDetails) {
            if let flight = selectedFlight {
                ResultDetails(flight: flight)
            }
        }
        .onAppear {
            // Poll flights when view appears if we have a search ID
            if let searchId = searchId {
                print("🔍 ResultView appeared with search_id: \(searchId)")
                print("📊 Current state - Results: \(viewModel.flightResults.count), HasMore: \(viewModel.hasMoreResults), IsLoading: \(viewModel.isLoading)")
                
                // Start polling immediately when view appears, but don't show results until loader is done
                if viewModel.flightResults.isEmpty && !viewModel.isLoading {
                    // Add a small delay to let the animated loader show first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.pollFlights(searchId: searchId)
                    }
                }
            } else {
                print("⚠️ No search_id available in ResultView")
            }
        }
        .onReceive(viewModel.$pollResponse) { response in
            // Update available airlines when poll response is received
            if let response = response {
                updateFlightInfo(from: response)
            }
        }
        .onChange(of: showAnimatedLoader) { isVisible in
            // When loader disappears, ensure the main content is visible
            if !isVisible {
                print("🎬 AnimatedResultLoader finished, showing main content")
            }
        }
    }
    
    private func updateFlightInfo(from response: PollResponse) {
        // Extract flight route info from first result if available
        if let firstResult = response.results.first,
           let firstLeg = firstResult.legs.first {
            originCode = firstLeg.originCode
            destinationCode = firstLeg.destinationCode
            isRoundTrip = firstResult.legs.count > 1
        }
        
        // You could also update travel date and traveler info if available
        // For now, keeping default values
    }
}

// MARK: - Updated Flight Result Card (keeping the existing one but adding debug info)
extension ResultView {
    private func debugPrint(_ message: String) {
        #if DEBUG
        print("🔍 ResultView: \(message)")
        #endif
    }
}

#Preview {
    ResultView(searchId: "sample-search-id")
}
