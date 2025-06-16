
import SwiftUI

struct FlightExploreCard: View {
    var body: some View {
        VStack{
            HStack{
                VStack(alignment: .leading){
                    Text("Explore")
                        .font(CustomFont.font(.regular, weight: .bold))
                    Text("Explore low fare flights to any destinations from your location")
                        .font(CustomFont.font(.small, weight: .medium))
                    
                    PrimaryButton(title: "Explore", font: CustomFont.font(.small), fontWeight: .semibold, textColor: .white,
                                  width: 68,
                                  height: 31,
                                  cornerRadius: 4, action: {
                        print("exploring...")
                    })
                }
                .padding()
                HStack{
                    Image("FlightImg")
                }
            }
            .padding(.vertical,0)
            .background(GradientColor.BlueWhite)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
        }
        .padding(.top, 30)
        
    }
}

#Preview {
    FlightExploreCard()
}
