import SwiftUI

struct ResultCard: View {
    var isRoundTrip: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(spacing: 20) {
                    RouteRow()

                    if isRoundTrip {
                        RouteRow()
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("$234")
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
            
            HStack {
                Image("AirlinesImg")
                    .resizable()
                    .frame(width: 21, height: 21)
                Text("Indigo Airways")
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.8))
                    .fontWeight(.light)
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
    var body: some View {
        HStack(spacing: 20) {
            LocationTimeColumn(time: "18:50", code: "COK")
            
            VStack {
                Text("2h 15m")
                    .font(.system(size: 11))
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                Divider()
                    .frame(width: 100)
                
                Text("1 Stop")
                    .font(.system(size: 11))
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
            
            LocationTimeColumn(time: "18:50", code: "COK")
        }
    }
}

// MARK: - Reusable LocationTimeColumn View
struct LocationTimeColumn: View {
    var time: String
    var code: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(time)
                .font(.system(size: 14))
                .fontWeight(.bold)
                .foregroundColor(.black)
            Text(code)
                .font(.system(size: 12))
                .fontWeight(.medium)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        ResultCard(isRoundTrip: true)
        ResultCard(isRoundTrip: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
