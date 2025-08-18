import SwiftUI

struct NotificationSheet: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("NotificationImg")
                .resizable()
                .frame(width: 106, height: 106)
                .padding(.top, 40)

            Text("leta.s.make.sure.you.get.the.best".localized)
                .font(.system(size: 24))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal)

            Text("allow.push.notifications.so.that.we.can.ensure.you.dona.t.mi".localized)
                .font(CustomFont.font(.regular))
                .fontWeight(.light)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)

            HStack(spacing: 12) {
                SecondaryButton(
                    title: "Clear",
                    font: CustomFont.font(.small),
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
                    font: CustomFont.font(.small),
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
