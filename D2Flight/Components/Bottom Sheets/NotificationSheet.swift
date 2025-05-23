import SwiftUI

struct NotificationSheet: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("NotificationImg")
                .resizable()
                .frame(width: 106, height: 106)
                .padding(.top, 40)

            Text("Let’s make sure you get the best!")
                .font(.system(size: 24))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal)

            Text("Allow push notifications so that we can ensure you don’t miss out on the best deals.")
                .font(.system(size: 14))
                .fontWeight(.light)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)

            HStack(spacing: 12) {
                SecondaryButton(
                    title: "Clear",
                    font: .system(size: 12),
                    fontWeight: .semibold,
                    textColor: .gray,
                    width: .infinity,
                    height: 40,
                    cornerRadius: 8,
                    
                    action: {
                        print("Clear tapped")
                    }
                )

                PrimaryButton(
                    title: "Allow",
                    font: .system(size: 12),
                    fontWeight: .semibold,
                    textColor: .white,
                    width: .infinity,
                    height: 40,
                    cornerRadius: 8,
                    action: {
                        print("Allow tapped")
                    }
                )
            }
            .padding(.bottom, 40)
        }
        .padding()
    }
}

#Preview {
    NotificationSheet()
}
