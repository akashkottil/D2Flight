import SwiftUI

struct ResultDetails: View {
    let flight: FlightResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image("BlackArrow")
                        .padding(.trailing, 10)
                }
                
                Text("Flight Details")
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.trailing, 44)
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Flight Summary Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Duration")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text(flight.formattedDuration)
                                    .font(.system(size: 18, weight: .bold))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Price")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Text(flight.formattedPrice)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color("PriceGreen"))
                            }
                        }
                        
                        // Badges
                        HStack(spacing: 8) {
                            if flight.is_best {
                                Badge(text: "Best Value", color: Color("Violet"))
                            }
                            if flight.is_cheapest {
                                Badge(text: "Cheapest", color: .green)
                            }
                            if flight.is_fastest {
                                Badge(text: "Fastest", color: .orange)
                            }
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    
                    // Flight Legs
                    ForEach(flight.legs.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 16) {
                            if flight.legs.count > 1 {
                                Text("Flight \(index + 1)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(.horizontal)
                            }
                            
                            FlightLegDetailCard(leg: flight.legs[index])
                        }
                    }
                    
                    // Providers Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Book with")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal)
                        
                        ForEach(flight.providers.indices, id: \.self) { index in
                            ProviderCard(provider: flight.providers[index])
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.gray.opacity(0.05))
        }
        .navigationBarHidden(true)
        .onAppear {
            // Log flight details when view appears
            print("📋 Displaying flight details:")
            print("   Flight ID: \(flight.id)")
            print("   Total Duration: \(flight.formattedDuration)")
            print("   Price Range: \(flight.formattedPrice) - $\(String(format: "%.0f", flight.max_price))")
            print("   Number of legs: \(flight.legs.count)")
            print("   Number of providers: \(flight.providers.count)")
        }
    }
}

// MARK: - Flight Leg Detail Card
struct FlightLegDetailCard: View {
    let leg: FlightLeg
    
    var body: some View {
        VStack(spacing: 0) {
            // Route Header
            HStack {
                VStack(alignment: .leading) {
                    Text(leg.origin)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(leg.originCode)
                        .font(.system(size: 20, weight: .bold))
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: "airplane")
                        .font(.system(size: 20))
                        .foregroundColor(Color("Violet"))
                    Text(formatDuration(leg.duration))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(leg.destination)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(leg.destinationCode)
                        .font(.system(size: 20, weight: .bold))
                }
            }
            .padding()
            
            Divider()
            
            // Segments
            VStack(spacing: 0) {
                ForEach(leg.segments.indices, id: \.self) { index in
                    SegmentRow(segment: leg.segments[index])
                    
                    if index < leg.segments.count - 1 {
                        // Layover info
                        HStack {
                            Spacer()
                            Text("Layover")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.05))
                    }
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
}

// MARK: - Segment Row
struct SegmentRow: View {
    let segment: FlightSegment
    
    var body: some View {
        VStack(spacing: 12) {
            // Airline info
            HStack {
                AsyncImage(url: URL(string: segment.airlineLogo)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 32, height: 32)
                
                VStack(alignment: .leading) {
                    Text(segment.airlineName)
                        .font(.system(size: 14, weight: .semibold))
                    Text("Flight \(segment.flightNumber)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text((segment.cabinClass ?? "Unknown").capitalized)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    if segment.wifi {
                        Image(systemName: "wifi")
                            .font(.system(size: 12))
                            .foregroundColor(Color("Violet"))
                    }
                }
            }
            
            // Time and Location
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatTime(segment.departureTimeAirport))
                        .font(.system(size: 16, weight: .bold))
                    Text(segment.originCode)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(segment.origin)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack {
                    Text(formatDuration(segment.duration))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatTime(segment.arriveTimeAirport))
                        .font(.system(size: 16, weight: .bold))
                    if segment.arrival_day_difference > 0 {
                        Text("+\(segment.arrival_day_difference)")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    Text(segment.destinationCode)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(segment.destination)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            // Aircraft info
            HStack {
                Image(systemName: "airplane")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(segment.aircraft ?? "unknown")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding()
    }
    
    private func formatTime(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
}

// MARK: - Provider Card
struct ProviderCard: View {
    let provider: Provider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let splitProviders = provider.splitProviders, !splitProviders.isEmpty {
                ForEach(splitProviders.indices, id: \.self) { index in
                    HStack {
                        AsyncImage(url: URL(string: splitProviders[index].imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 60, height: 30)
                        
                        VStack(alignment: .leading) {
                            Text(splitProviders[index].name)
                                .font(.system(size: 14, weight: .semibold))
                            
                            if let rating = splitProviders[index].rating,
                               let ratingCount = splitProviders[index].ratingCount {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", rating))
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text("(\(ratingCount))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(String(format: "$%.0f", splitProviders[index].price))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color("PriceGreen"))
                            
                            Button {
                                print("🔗 Opening deeplink: \(splitProviders[index].deeplink)")
                                // Handle deeplink opening
                            } label: {
                                Text("Select")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(Color("Violet"))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    if index < splitProviders.count - 1 {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            } else {
                // Single provider
                HStack {
                    VStack(alignment: .leading) {
                        Text("Provider")
                            .font(.system(size: 14, weight: .semibold))
                        if let transferType = provider.transferType {
                            Text(transferType)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Text(String(format: "$%.0f", provider.price))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("PriceGreen"))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    // Create a sample flight for preview
    let sampleFlight = FlightResult(
        id: "sample-123",
        total_duration: 135,
        min_price: 234.0,
        max_price: 456.0,
        legs: [
            FlightLeg(
                arriveTimeAirport: 1735228800,
                departureTimeAirport: 1735221600,
                duration: 135,
                origin: "Kochi",
                originCode: "COK",
                destination: "London",
                destinationCode: "LON",
                stopCount: 1,
                segments: []
            )
        ],
        providers: [],
        is_best: true,
        is_cheapest: false,
        is_fastest: false
    )
    
    ResultDetails(flight: sampleFlight)
}
