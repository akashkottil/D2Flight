


import SwiftUI

struct ResultView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Fixed Top Filter Bar
            ResultHeader()
                .padding()
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                .zIndex(1)

            // Scrollable Content
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<10) { _ in
                        ResultCard()
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea()
        }
        .background(.gray.opacity(0.2))
    }
}




#Preview {
    ResultView()
}
