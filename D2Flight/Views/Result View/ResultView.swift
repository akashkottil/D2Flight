////
////
////
////import SwiftUI
////
////struct ResultView: View {
////    var body: some View {
////        VStack(spacing: 0) {
////            // Fixed Top Filter Bar
////            ResultHeader()
////                .padding()
////                .background(Color.white)
////                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
////                .zIndex(1)
////
////            // Scrollable Content
////            ScrollView {
////                VStack(spacing: 16) {
////                    ForEach(0..<10) { _ in
////                        ResultCard()
////                    }
////                }
////                .padding()
////            }
////            .scrollIndicators(.hidden)
////            .ignoresSafeArea()
////        }
////        .background(.gray.opacity(0.2))
////    }
////}
////
////
////
////
////#Preview {
////    ResultView()
////}
//
//import SwiftUI
//
//struct ResultView: View {
//    @State private var isLoading = true
//    @State private var hasLoadedOnce = false  // Track if initial loading is done
//    
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
//                    ForEach(0..<10, id: \.self) { _ in
//                        if isLoading {
//                            ShimmerResultCard()
//                        } else {
//                            ResultCard()
//                        }
//                    }
//                }
//                .padding()
//            }
//            .scrollIndicators(.hidden)
//            .ignoresSafeArea()
//        }
//        .navigationBarHidden(true)
//        .background(.gray.opacity(0.2))
//        .onAppear {
//            // Only load once when the view first appears
//            if !hasLoadedOnce {
//                // Automatically switch to actual content after 1.5 seconds
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                    withAnimation(.easeInOut(duration: 0.3)) {
//                        isLoading = false
//                        hasLoadedOnce = true  // Mark as loaded
//                    }
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    ResultView()
//}


import SwiftUI

struct ResultView: View {
    let searchId: String?
    @State private var isLoading = true
    @State private var hasLoadedOnce = false
    @State private var navigateToDetails = false
    
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
                    ForEach(0..<10, id: \.self) { index in
                        if isLoading {
                            ShimmerResultCard()
                        } else {
                            Button(action: {
                                // Navigate to ResultDetails if we have a search_id
                                if let searchId = searchId, !searchId.isEmpty {
                                    print("🎯 Navigating to ResultDetails with Search ID: \(searchId)")
                                    navigateToDetails = true
                                } else {
                                    print("⚠️ No search ID available for details")
                                }
                            }) {
                                ResultCard()
                            }
                            .buttonStyle(PlainButtonStyle())
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
            print("📱 ResultView appeared")
            if let searchId = searchId {
                print("   Search ID: \(searchId)")
            } else {
                print("   No Search ID provided")
            }
            
            // Only load once when the view first appears
            if !hasLoadedOnce {
                // Automatically switch to actual content after 1.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                        hasLoadedOnce = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $navigateToDetails) {
            if let searchId = searchId {
                ResultDetails(searchId: searchId)
            } else {
                EmptyResultDetailsView()
            }
        }
    }
}

// Fallback view when no search ID is available
struct EmptyResultDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("No Search ID Available")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            Text("Unable to fetch flight details without a valid search ID")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                dismiss()
            }) {
                Text("Go Back")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ResultView(searchId: "sample-search-id")
}
