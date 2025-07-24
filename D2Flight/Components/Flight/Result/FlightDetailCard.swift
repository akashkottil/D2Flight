import SwiftUI
// MARK: - Flight Detail Card (Updated to show actual airline data)
struct FlightDetailCard: View {
    let leg: FlightLeg
    let isRoundTrip: Bool
    let legIndex: Int
    
    @State private var showAllSegments = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Airline Header - Use actual segment data
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
                                Text(firstSegment.airlineIata)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(firstSegment.airlineName) \(firstSegment.flightNumber)")
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
                            .fill(leg.stopCount == 0 ? Color.gray : Color.gray)
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
                            .fill(leg.stopCount == 0 ? Color.gray : Color.gray)
                            .frame(width: 6, height: 6)
                    }
                    .frame(width: 100)
                    
                    Text(leg.stopsText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(leg.stopCount == 0 ? .gray : .gray)
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
            
            Divider()
            
            // Aircraft and amenities info with conditional "View details" button
            if let firstSegment = leg.segments.first {
                HStack {
                    Image("airCraftIcon")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text(firstSegment.aircraft ?? "Aircraft N/A")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    // WiFi indicator
                    if firstSegment.wifi {
                        Image(systemName: "wifi")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("WiFi")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Only show "View details" button if there are 2 or more segments
                    if leg.segments.count >= 2 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAllSegments.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(showAllSegments ? "Hide details" : "View details")
                                    .font(.system(size: 14))
                                    .foregroundColor(.purple)
                                
                                Image(systemName: showAllSegments ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.purple)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
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
    
    private func getCabinClassDisplay(_ cabinClass: String?) -> String {
        switch cabinClass?.uppercased() {
        case "E": return "Economy"
        case "B": return "Business"
        case "F": return "First"
        case "P": return "Premium Economy"
        default: return cabinClass ?? "Economy"
        }
    }
}
