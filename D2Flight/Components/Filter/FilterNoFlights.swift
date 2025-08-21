import SwiftUI

struct FilterNoFlights : View {
    var body: some View {
        VStack(spacing:20){
            Image("FilterErrorImg")
            Text("edit.filter".localized)
                .font(CustomFont.font(.large))
                .fontWeight(.bold)
            Text("edit.your.filter.to.see.more.results.or.clear.all.filters".localized)
                .font(CustomFont.font(.large))
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .padding(.horizontal,40)
                .multilineTextAlignment(.center)
            PrimaryButton(
                title: "clear all filter",
                font: CustomFont.font(.large),
                fontWeight: .semibold,
                width: 150,
                height: 44,
                cornerRadius: 8
            ) {
                print("filter error")
            }
        }
    }
}

#Preview {
    FilterNoFlights()
}
