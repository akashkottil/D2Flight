//
//
//
//import SwiftUI
//
//struct ResultView: View {
//    var body: some View {
//        VStack(spacing: 0) {
//            // Fixed Top Filter Bar
//            ResultHeader()
//                .padding()
//                .background(Color.white)
//                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
//                .zIndex(1)
//
//            // Scrollable Content
//            ScrollView {
//                VStack(spacing: 16) {
//                    ForEach(0..<10) { _ in
//                        ResultCard()
//                    }
//                }
//                .padding()
//            }
//            .scrollIndicators(.hidden)
//            .ignoresSafeArea()
//        }
//        .background(.gray.opacity(0.2))
//    }
//}
//
//
//
//
//#Preview {
//    ResultView()
//}

import SwiftUI

struct ResultView: View {
    @State private var isLoading = true
    @State private var hasLoadedOnce = false  // Track if initial loading is done
    
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
                    ForEach(0..<10, id: \.self) { _ in
                        if isLoading {
                            ShimmerResultCard()
                        } else {
                            ResultCard()
                        }
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea()
        }
        .navigationBarHidden(true)
        .background(.gray.opacity(0.2))
        .onAppear {
            // Only load once when the view first appears
            if !hasLoadedOnce {
                // Automatically switch to actual content after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                        hasLoadedOnce = true  // Mark as loaded
                    }
                }
            }
        }
    }
}

#Preview {
    ResultView()
}
