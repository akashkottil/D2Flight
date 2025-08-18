import SwiftUI

struct FlightExploreCard: View {
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("login.to.get.some".localized)
                        .font(CustomFont.font(.medium, weight: .medium))
                    Text("exclusive.deals".localized)
                        .font(CustomFont.font(.large, weight: .bold))
                   
                    PrimaryButton(
                        title: "explore".localized,
                        font: CustomFont.font(.regular),
                        fontWeight: .semibold,
                        textColor: .white,
                        width: 68,
                        height: 31,
                        cornerRadius: 4,
                        action: {
                            print("exploring...")
                        })
                }
                .foregroundColor(.white)
                .padding()
                
                Spacer()

                HStack {
                    Image("FlightImg")
                }
            }
            .padding(.vertical, 0)
            .frame(maxWidth: .infinity) // Expand the content
            .background(GradientColor.Primary) // Background fills the expanded area
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
        }
        .padding(.top, 30)
        .padding(.horizontal) // Optional: padding to keep inside screen safely
    }
}


#Preview {
    FlightExploreCard()
}
