import SwiftUI

struct ResultDetails: View {
    let searchId: String
    @StateObject private var viewModel = FlightResultsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else if viewModel.hasResults {
                    resultsView
                } else {
                    emptyStateView
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                print("🎯 ResultDetails appeared with Search ID: \(searchId)")
                viewModel.pollFlightResults(searchId: searchId)
            }
            .onReceive(viewModel.$pollResponse) { response in
                if let response = response {
                    print("📊 ResultDetails received poll response:")
                    print("   Results count: \(response.count)")
                    print("   Airlines: \(response.airlines.map { $0.airlineName }.joined(separator: ", "))")
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image("BlackArrow")
                        .padding(.trailing, 10)
                }
                
                VStack(alignment: .leading) {
                    Text("Flight Results")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    if let response = viewModel.pollResponse {
                        Text("\(response.count) flights found")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button(action: {
                        viewModel.pollFlightResults(searchId: searchId)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            
            if let response = viewModel.pollResponse {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Price Range")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(viewModel.priceRange)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Duration")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text(viewModel.durationRange)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Airlines")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        Text("\(response.airlines.count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            
            Divider()
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Searching for the best flights...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Text("Search ID: \(searchId)")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.7))
                .padding(.top, 20)
            
            Spacer()
        }
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                viewModel.pollFlightResults(searchId: searchId)
            }) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
            
            Spacer()
        }
    }
    
    // MARK: - Results View
    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Summary Cards
                summaryCardsView
                
                // Airlines Section
                if !viewModel.airlines.isEmpty {
                    airlinesSection
                }
                
                // Results Section
                resultsSection
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Summary Cards
    private var summaryCardsView: some View {
        HStack(spacing: 12) {
            if let response = viewModel.pollResponse {
                SummaryCard(
                    title: "Cheapest",
                    price: "₹\(response.cheapestFlight.price)",
                    subtitle: "\(response.cheapestFlight.duration)m",
                    color: .green
                )
                
                SummaryCard(
                    title: "Best",
                    price: "₹\(response.bestFlight.price)",
                    subtitle: "\(response.bestFlight.duration)m",
                    color: .blue
                )
                
                SummaryCard(
                    title: "Fastest",
                    price: "₹\(response.fastestFlight.price)",
                    subtitle: "\(response.fastestFlight.duration)m",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Airlines Section
    private var airlinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Airlines (\(viewModel.airlines.count))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.airlines.prefix(10)) { airline in
                        VStack(spacing: 6) {
                            AsyncImage(url: URL(string: airline.airlineLogo)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                            
                            Text(airline.airlineIata)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flight Results (\(viewModel.resultsCount))")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            
            ForEach(viewModel.flightResults.prefix(10)) { result in
                FlightResultCard(result: result)
            }
            
            if viewModel.resultsCount > 10 {
                Text("+ \(viewModel.resultsCount - 10) more results")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "airplane")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No flights found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            Text("Try adjusting your search criteria")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views
struct SummaryCard: View {
    let title: String
    let price: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            Text(price)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct FlightResultCard: View {
    let result: FlightResult
    
    var body: some View {
        VStack(spacing: 12) {
            // Price and Duration Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("₹\(result.minPrice)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("per adult")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatDuration(result.totalDuration))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text("\(result.legs.first?.stopCount ?? 0) stops")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            
            // Flight Route Info
            if let leg = result.legs.first {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatTime(leg.departureTimeAirport))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text(leg.originCode)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text(formatDuration(leg.duration))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatTime(leg.arriveTimeAirport))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text(leg.destinationCode)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Divider()
            
            // Provider Info
            if let provider = result.providers.first?.splitProviders.first {
                HStack {
                    AsyncImage(url: URL(string: provider.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 20, height: 20)
                    
                    Text(provider.name)
                        .font(.system(size: 12))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        
                        Text(String(format: "%.1f", provider.rating))
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatTime(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
}

#Preview {
    ResultDetails(searchId: "sample-search-id")
}
