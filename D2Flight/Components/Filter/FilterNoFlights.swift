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
                title: "clear.all.filter",
                font: CustomFont.font(.large),
                fontWeight: .semibold,
                width: 150,
                height: 44,
                cornerRadius: 8
            ) {
                print("\n🎯 ===== CLEAR ALL FILTER BUTTON PRESSED =====")
                print("🎯 User clicked 'Clear All Filter' from FilterNoFlights view")
                print("🎯 Calling onClearAll() action...")
                onClearAll()           // ← call the injected action
                print("🎯 ===== END CLEAR ALL FILTER BUTTON =====\n")
            }
        }
    }
}

#Preview {
    FilterNoFlights(onClearAll: { })
}
