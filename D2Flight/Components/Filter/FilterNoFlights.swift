import SwiftUI

struct FilterNoFlights: View {
    let onClearAll: () -> Void   // ← inject the action

    var body: some View {
        VStack(spacing: 20) {
            Image("FilterErrorImg")
            Text("edit.filter".localized)
                .font(CustomFont.font(.large))
                .fontWeight(.bold)
            Text("edit.your.filter.to.see.more.results.or.clear.all.filters".localized)
                .font(CustomFont.font(.large))
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
                .multilineTextAlignment(.center)

            PrimaryButton(
                title: "clear all filter",
                font: CustomFont.font(.large),
                fontWeight: .semibold,
                width: 150,
                height: 44,
                cornerRadius: 8
            ) {
                onClearAll()           // ← call the injected action
                print("filter cleared!")
            }
        }
    }
}

#Preview {
    FilterNoFlights(onClearAll: { })
}
