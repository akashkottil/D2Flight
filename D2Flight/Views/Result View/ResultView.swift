import SwiftUI

struct ResultView: View {
    @StateObject private var viewModel = ResultViewModel()
    @State private var selectedFlight: FlightResult? = nil
    @State private var navigateToDetails = false
    
    // Pass search ID and search parameters
    let searchId: String?
    let searchParameters: SearchParameters
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed Top Filter Bar with dynamic data
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
            
            // Content
            if viewModel.isLoading {
                // Show shimmer while loading
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
                    
                    Text("Try adjusting your search criteria")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            } else {
                // Show flight results
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.flightResults) { flight in
                            Button {
                                // Log and navigate to details
                                print("🎯 Navigating to flight details:")
                                viewModel.selectFlight(flight)
                                selectedFlight = flight
                                navigateToDetails = true
                            } label: {
                                // Determine if it's round trip based on search parameters
                                ResultCard(flight: flight, isRoundTrip: searchParameters.isRoundTrip)
                            }
                            .buttonStyle(PlainButtonStyle())
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
            // Poll flights when view appears if we have a search ID
            if let searchId = searchId {
                print("🔍 ResultView appeared with search_id: \(searchId)")
                print("📋 Search parameters:")
                print("   Route: \(searchParameters.routeDisplayText)")
                print("   Date: \(searchParameters.formattedTravelDate)")
                print("   Travelers: \(searchParameters.formattedTravelerInfo)")
                print("   Round Trip: \(searchParameters.isRoundTrip)")
                
                viewModel.pollFlights(searchId: searchId)
                
                // Update result header with available airlines when poll response is received
                if let pollResponse = viewModel.pollResponse {
                    // You can access airlines data here if needed for filters
                    print("📊 Airlines available: \(pollResponse.airlines.count)")
                }
            } else {
                print("⚠️ No search_id available in ResultView")
            }
        }
        .onReceive(viewModel.$pollResponse) { pollResponse in
            // Update available airlines for filters when poll response changes
            if let response = pollResponse {
                print("📊 Poll response received with \(response.airlines.count) airlines")
                // The ResultHeader will get airlines through the filter viewmodel
            }
        }
    }
}

// MARK: - Preview with Sample Data
#Preview {
    let sampleSearchParams = SearchParameters(
        originCode: "KCH",
        destinationCode: "LON",
        originName: "Kochi",
        destinationName: "London",
        isRoundTrip: true,
        departureDate: Date(),
        returnDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
        adults: 2,
        children: 1,
        infants: 0,
        selectedClass: .business
    )
    
    return ResultView(
        searchId: "sample-search-id",
        searchParameters: sampleSearchParams
    )
}
