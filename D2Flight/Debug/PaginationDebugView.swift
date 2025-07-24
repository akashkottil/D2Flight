import SwiftUI

struct PaginationDebugView: View {
    @ObservedObject var viewModel: ResultViewModel
    @State private var showDebugInfo = false
    
    var body: some View {
        #if DEBUG
        VStack {
            if showDebugInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debug Info")
                        .font(CustomFont.font(.small, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Results: \(viewModel.flightResults.count)/\(viewModel.totalResultsCount)")
                        .font(CustomFont.font(.tiny))
                        .foregroundColor(.white)
                    
                    Text("HasMore: \(viewModel.hasMoreResults ? "Yes" : "No")")
                        .font(CustomFont.font(.tiny))
                        .foregroundColor(.white)
                    
                    Text("Loading: \(viewModel.isLoading ? "Initial" : viewModel.isLoadingMore ? "More" : "None")")
                        .font(CustomFont.font(.tiny))
                        .foregroundColor(.white)
                    
                    // Show cache status
                    if let pollResponse = viewModel.pollResponse {
                        Text("Cache: \(pollResponse.cache ? "Complete" : "Building")")
                            .font(CustomFont.font(.tiny))
                            .foregroundColor(pollResponse.cache ? .green : .yellow)
                    }
                    
                    // Show poll count
                    Text("API Calls: \(viewModel.totalPollCount)")
                        .font(CustomFont.font(.tiny))
                        .foregroundColor(.white)
                }
                .padding(8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .scale))
            }
            
            // Toggle button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDebugInfo.toggle()
                }
            }) {
                Image(systemName: "info.circle")
                    .font(CustomFont.font(.medium))
                    .foregroundColor(.gray)
                    .opacity(0.6)
            }
            .padding(.top, 8)
        }
        #endif
    }
}

// MARK: - Extension to add debug view to ResultView
extension View {
    func debugPagination(viewModel: ResultViewModel) -> some View {
        ZStack {
            self
            
            #if DEBUG
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    PaginationDebugView(viewModel: viewModel)
                        .padding(.trailing, 16)
                        .padding(.bottom, 100) // Above tab bar
                }
            }
            #endif
        }
    }
}
