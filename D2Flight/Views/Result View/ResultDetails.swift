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
                    Image("DefaultLeftArrow")
                        .padding(.trailing, 10)
                        .frame(width: 24,height: 24)
                }
                
                Spacer()
                
                Button(action: {
                    // Share functionality
                }) {
                    Image("ShareIcon")
                        .frame(width: 24,height: 24)
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(Color.white)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Route and Trip Details Section
                    VStack(spacing: 16) {
                        // Route Header
                        HStack {
                            Text(getRouteText())
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                            VStack(alignment:.trailing){
                                Text("1 stop")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.red)
                                Text("1h 54m")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.black.opacity(0.5))
                            }
                        }
                        // trip location
                        HStack{
                            Text("Kozhikode")
                            Text("to")
                            Text("Kannur")
                            Spacer()
                        }
                        .font(.system(size: 14, weight: .semibold))
                        // Trip Details
                        HStack {
                            Text(getTripDetailsText())
                                .font(.system(size: 18))
                                .fontWeight(.light)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    
                    // Booking Platforms Section
                    VStack(spacing: 12) {
                        ForEach(getBookingPlatforms(), id: \.name) { platform in
                            BookingPlatformRow(platform: platform)
                        }
                        
                        if flight.providers.count > 3 {
                            Button(action: {
                                // Show more deals
                            }) {
                                Text("\(flight.providers.count - 3) more deal from \(flight.formattedPrice)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    
                    Divider()
                    HStack {
                        Spacer()
                        Text("3 more deal from $280")
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    
                    Divider()
                    // Price note
                    HStack {
                        Spacer()
                        Text("$ (USD) per ticket, including taxes & Fees")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    Divider()
                    
                    // Flight Details Section
                    VStack(spacing: 16) {
                        ForEach(flight.legs.indices, id: \.self) { index in
                            FlightDetailCard(
                                leg: flight.legs[index],
                                isRoundTrip: flight.legs.count > 1,
                                legIndex: index
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                }
            }
        }
        .navigationBarHidden(true)
        .background(Color.gray.opacity(0.05))
        .onAppear {
            print("📋 Displaying flight details for: \(flight.id)")
        }
    }
    
    private func getRouteText() -> String {
        guard let firstLeg = flight.legs.first else { return "Flight Details" }
        return "\(firstLeg.originCode) → \(firstLeg.destinationCode)"
    }
    
    private func getTripDetailsText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E dd MMM"
        
        var details = ""
        if let firstLeg = flight.legs.first {
            let date = Date(timeIntervalSince1970: TimeInterval(firstLeg.departureTimeAirport))
            details = dateFormatter.string(from: date)
        }
        
        // Add cabin class and traveler info (you might want to pass this from the search)
        details += " • Economy • 1 Traveller"
        
        return details
    }
    
    private func getBookingPlatforms() -> [BookingPlatform] {
        var platforms: [BookingPlatform] = []
        
        // Create sample platforms based on providers or use default ones
        let platformNames = ["Trip.com", "Skyscanner", "Kayak"]
        
        for (index, name) in platformNames.enumerated() {
            if index < flight.providers.count {
                platforms.append(BookingPlatform(
                    name: name,
                    price: flight.providers[index].price
                ))
            } else {
                platforms.append(BookingPlatform(
                    name: name,
                    price: flight.min_price
                ))
            }
        }
        
        return platforms
    }
}

// MARK: - Booking Platform Row
struct BookingPlatformRow: View {
    let platform: BookingPlatform
    
    var body: some View {
        Divider()
        HStack {
            Text(platform.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black.opacity(0.5))
            
            Spacer()
            
            Text(String(format: "$%.0f", platform.price))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            
            Image(systemName: "info.circle")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .padding(.leading, 4)
            
            // Updated Search Flights Button with validation
            PrimaryButton(title: "View Deal",
                          font: .system(size: 12),
                          fontWeight: .bold,
                          textColor: .white,
                          width: 90,
                          height: 39,
                          verticalPadding: 12,
                          cornerRadius: 6,
                          action: {print("View Deal tapped for \(platform.name)")})
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Flight Detail Card
struct FlightDetailCard: View {
    let leg: FlightLeg
    let isRoundTrip: Bool
    let legIndex: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Airline Header
            if let firstSegment = leg.segments.first {
                HStack {
                    AsyncImage(url: URL(string: firstSegment.airlineLogo)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                            .overlay(
                                Text(String(firstSegment.airlineName.prefix(2)))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(firstSegment.airlineName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                        Text(getTripDate())
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
            }
            
            // Flight Route Details
            HStack {
                // Departure
                VStack(alignment: .leading, spacing: 4) {
                    Text(leg.originCode)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.black)
                    Text(leg.formattedDepartureTime)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Text(leg.origin)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                // Duration and Stops
                VStack(spacing: 8) {
                    Text(formatDuration(leg.duration))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    // Flight path line
                    HStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                        
                        Rectangle()
                            .fill(Color.gray)
                            .frame(height: 1)
                        
                        if leg.stopCount > 0 {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 6, height: 6)
                            
                            Rectangle()
                                .fill(Color.gray)
                                .frame(height: 1)
                        }
                        
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                    }
                    .frame(width: 100)
                    
                    Text(leg.stopsText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Arrival
                VStack(alignment: .trailing, spacing: 4) {
                    Text(leg.destinationCode)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.black)
                    Text(leg.formattedArrivalTime)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Text(leg.destination)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            
            // Aircraft Info
            if let firstSegment = leg.segments.first {
                HStack {
                    Image(systemName: "airplane")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text(firstSegment.aircraft ?? "Airbus A32neo")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button("View more") {
                        print("View more details tapped")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.purple)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
    
    private func getTripDate() -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(leg.departureTimeAirport))
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Models
struct BookingPlatform {
    let name: String
    let price: Double
}

#Preview {
    // Create a sample flight for preview
    let sampleSegment = FlightSegment(
        id: "sample-segment",
        arriveTimeAirport: 1735228800,
        departureTimeAirport: 1735221600,
        duration: 135,
        flightNumber: "6E 123",
        airlineName: "Indigo Airways",
        airlineIata: "6E",
        airlineLogo: "https://example.com/logo.png",
        originCode: "CNN",
        origin: "Kozhikode",
        destinationCode: "CCJ",
        destination: "Kannur",
        arrival_day_difference: 0,
        wifi: true,
        cabinClass: "Economy",
        aircraft: "Airbus A32neo"
    )
    
    let sampleLeg = FlightLeg(
        arriveTimeAirport: 1735228800,
        departureTimeAirport: 1735221600,
        duration: 135,
        origin: "Kozhikode",
        originCode: "CNN",
        destination: "Kannur",
        destinationCode: "CCJ",
        stopCount: 1,
        segments: [sampleSegment]
    )
    
    let sampleProvider = Provider(
        isSplit: false,
        transferType: nil,
        price: 280.0,
        splitProviders: nil
    )
    
    let sampleFlight = FlightResult(
        id: "sample-123",
        total_duration: 135,
        min_price: 280.0,
        max_price: 280.0,
        legs: [sampleLeg],
        providers: [sampleProvider],
        is_best: true,
        is_cheapest: false,
        is_fastest: false
    )
    
    ResultDetails(flight: sampleFlight)
}

// MARK: - Sample Data for Preview

let sampleSegment = FlightSegment(
    id: "sample-segment",
    arriveTimeAirport: 1735228800,
    departureTimeAirport: 1735221600,
    duration: 135,
    flightNumber: "6E 123",
    airlineName: "Indigo Airways",
    airlineIata: "6E",
    airlineLogo: "https://example.com/logo.png",
    originCode: "CNN",
    origin: "Kozhikode",
    destinationCode: "CCJ",
    destination: "Kannur",
    arrival_day_difference: 0,
    wifi: true,
    cabinClass: "Economy",
    aircraft: "Airbus A32neo"
)

let sampleLeg = FlightLeg(
    arriveTimeAirport: 1735228800,
    departureTimeAirport: 1735221600,
    duration: 135,
    origin: "Kozhikode",
    originCode: "CNN",
    destination: "Kannur",
    destinationCode: "CCJ",
    stopCount: 1,
    segments: [sampleSegment]
)

let sampleProvider = Provider(
    isSplit: false,
    transferType: nil,
    price: 280.0,
    splitProviders: nil
)

let sampleFlight = FlightResult(
    id: "sample-123",
    total_duration: 135,
    min_price: 280.0,
    max_price: 280.0,
    legs: [sampleLeg],
    providers: [sampleProvider],
    is_best: true,
    is_cheapest: false,
    is_fastest: false
)

// MARK: - Preview

#Preview {
    ResultDetails(flight: sampleFlight)
}

