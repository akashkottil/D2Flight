import SwiftUI

struct ResultView: View {
    @StateObject private var viewModel = ResultViewModel()
    @State private var selectedFlight: FlightResult? = nil
    @State private var navigateToDetails = false
    
    // Pass search ID directly
    let searchId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed Top Filter Bar
            ResultHeader()
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
                                FlightResultCard(flight: flight)
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
                viewModel.pollFlights(searchId: searchId)
            } else {
                print("⚠️ No search_id available in ResultView")
            }
        }
    }
}

// MARK: - Updated Flight Result Card
struct FlightResultCard: View {
    let flight: FlightResult
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(spacing: 20) {
                    // Show legs
                    ForEach(flight.legs.indices, id: \.self) { index in
                        FlightLegRow(leg: flight.legs[index])
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(flight.formattedPrice)
                        .font(.system(size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(Color("PriceGreen"))
                    Text("per Adult")
                        .font(.system(size: 12))
                        .fontWeight(.light)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            // Airlines info
            if let firstSegment = flight.legs.first?.segments.first {
                HStack {
                    AsyncImage(url: URL(string: firstSegment.airlineLogo)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image("AirlinesImg")
                            .resizable()
                    }
                    .frame(width: 21, height: 21)
                    
                    Text(firstSegment.airlineName)
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.8))
                        .fontWeight(.light)
                    
                    Spacer()
                    
                    // Show badges
                    HStack(spacing: 8) {
                        if flight.is_best {
                            Badge(text: "Best", color: Color("Violet"))
                        }
                        if flight.is_cheapest {
                            Badge(text: "Cheapest", color: .green)
                        }
                        if flight.is_fastest {
                            Badge(text: "Fastest", color: .orange)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}

// MARK: - Flight Leg Row
struct FlightLegRow: View {
    let leg: FlightLeg
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text(leg.formattedDepartureTime)
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text(leg.originCode)
                    .font(.system(size: 12))
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
            
            VStack {
                Text(formatDuration(leg.duration))
                    .font(.system(size: 11))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                Divider()
                    .frame(width: 100)
                
                Text(leg.stopsText)
                    .font(.system(size: 11))
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading) {
                Text(leg.formattedArrivalTime)
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text(leg.destinationCode)
                    .font(.system(size: 12))
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
}

// MARK: - Badge Component
struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(4)
    }
}

#Preview {
    ResultView(searchId: "sample-search-id")
}
