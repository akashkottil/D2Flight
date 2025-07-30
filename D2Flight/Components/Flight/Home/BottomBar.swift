import SwiftUI

struct BottomBar: View {
    var body: some View {
        VStack(spacing: 0) { // 👈 Set spacing to 0 to eliminate the gap
            Image("bwimg")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .clipped()

            VStack { }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .background(Color(hex: "#151838"))
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    BottomBar()
}
