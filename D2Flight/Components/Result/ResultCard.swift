import SwiftUI

// Your existing ResultCard should work, but make sure this section is correct:

struct ResultCard: View {
    let flight: FlightResult
    var isRoundTrip: Bool

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(spacing: 20) {
                    // Show first leg
                    RouteRow(leg: flight.legs.first!)
                    
                    // Show second leg if round trip and exists
                    if isRoundTrip && flight.legs.count > 1 {
                        RouteRow(leg: flight.legs[1])
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(flight.formattedPrice)
                        .font(CustomFont.font(.medium))
                        .fontWeight(.bold)
                        .foregroundColor(Color("PriceGreen"))
                    Text("per.adult".localized)
                        .font(CustomFont.font(.small))
                        .fontWeight(.light)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            HStack {
                if let firstSegment = flight.legs.first?.segments.first {
                    AsyncImage(url: URL(string: firstSegment.airlineLogo)) { image in
                        image.resizable()
                    } placeholder: {
                        Image("AirlinesImg").resizable()
                    }
                    .frame(width: 21, height: 21)
                    
                    Text(firstSegment.airlineName)
                        .font(CustomFont.font(.small))
                        .foregroundColor(.black.opacity(0.8))
                        .fontWeight(.light)
                } else {
                    Image("AirlinesImg")
                        .resizable()
                        .frame(width: 21, height: 21)
                    Text("unknown.airline".localized)
                        .font(CustomFont.font(.small))
                        .foregroundColor(.black.opacity(0.8))
                        .fontWeight(.light)
                }
                Spacer()
                

            }
            .padding(.leading)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}


// MARK: - Reusable RouteRow View
struct RouteRow: View {
    let leg: FlightLeg
    
    var body: some View {
        HStack(spacing: 20) {
            LocationTimeColumn(time: leg.formattedDepartureTime, code: leg.originCode)
            
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
            
            LocationTimeColumn(time: leg.formattedArrivalTime, code: leg.destinationCode)
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
    }
}


// MARK: - Reusable LocationTimeColumn View
struct LocationTimeColumn: View {
    var time: String
    var code: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(time)
                .font(CustomFont.font(.regular))
                .fontWeight(.bold)
                .foregroundColor(.black)
            Text(code)
                .font(CustomFont.font(.small))
                .fontWeight(.medium)
                .foregroundColor(.gray)
        }
    }
}
//
//#Preview {
//    VStack(spacing: 40) {
//        ResultCard(isRoundTrip: true)
//        ResultCard(isRoundTrip: false)
//    }
//    .padding()
//    .background(Color.gray.opacity(0.1))
//}
