import SwiftUI
import SafariServices

// MARK: - Rental WebView with Enhanced Error Handling
struct RentalWebView: View {
    @ObservedObject var rentalSearchVM: RentalSearchViewModel
    
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                if let deeplink = rentalSearchVM.deeplink {
                    // Show SafariWebView when URL is ready
                    RentalSafariWebViewWrapper(
                        urlString: deeplink,
                        onLoadFailed: handleWebViewError
                    )
                    .transition(.opacity)
                }else if rentalSearchVM.isLoading {
                    // Show AnimatedRentalLoader while the rental search is loading
                    AnimatedRentalLoader(hotelAssetName: "RentalIcon", isVisible: $rentalSearchVM.isLoading)
                        .ignoresSafeArea()
                        .transition(.opacity) // This adds a fade-in effect
                } else if let error = rentalSearchVM.errorMessage {
                    // Show error state with retry option
                    RentalErrorStateView(
                        title: "Rental Search Failed",
                        message: error,
                        primaryButtonTitle: "Try Again",
                        secondaryButtonTitle: "Cancel",
                        onPrimaryAction: {
                            rentalSearchVM.searchRentals()
                        },
                        onSecondaryAction: {
                            dismiss()
                        }
                    )
                } else {
                    // Initial state - start search immediately if no deeplink or loading
                    RentalInitialLoadingView()
                        .onAppear {
                            // Auto-start search if not already loading and no deeplink
                            if !rentalSearchVM.isLoading && rentalSearchVM.deeplink == nil {
                                rentalSearchVM.isLoading = true // Start showing loader
                                rentalSearchVM.searchRentals()
                            }
                        }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleWebViewError(_ error: Error) {
        alertTitle = "Unable to Load"
        alertMessage = "The rental search page could not be loaded. Please try again."
        showingAlert = true
        
        // Show a warning using a shared manager
        WarningManager.shared.showDeeplinkError(for: .rental, error: error)
    }
    
}


// MARK: - Safari WebView Wrapper for Rental Search
struct RentalSafariWebViewWrapper: UIViewControllerRepresentable {
    let urlString: String
    let onLoadFailed: ((Error) -> Void)?
    
    init(urlString: String, onLoadFailed: ((Error) -> Void)? = nil) {
        self.urlString = urlString
        self.onLoadFailed = onLoadFailed
    }
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        guard let url = URL(string: urlString) else {
            // Handle invalid URL
            let error = URLError(.badURL)
            onLoadFailed?(error)
            return SFSafariViewController(url: URL(string: "about:blank")!)
        }
        
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.delegate = context.coordinator
        
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: RentalSafariWebViewWrapper
        
        init(_ parent: RentalSafariWebViewWrapper) {
            self.parent = parent
        }
        
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            if !didLoadSuccessfully {
                let error = URLError(.cannotLoadFromNetwork)
                parent.onLoadFailed?(error)
            }
        }
    }
}


// MARK: - Loading State View
struct RentalLoadingStateView: View {
    let title: String
    let subtitle: String
    let hasTimedOut: Bool
    let onRetry: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            if hasTimedOut {
                // Timeout state
                VStack(spacing: 16) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Search Timed Out")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("The search is taking longer than expected. Please try again.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
            } else {
                // Normal loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("Violet")))
                    
                    Text(title)
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Action buttons (shown on timeout or after some time)
            if hasTimedOut {
                HStack(spacing: 16) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    
                    Button("Try Again") {
                        onRetry()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color("Violet"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}


// MARK: - Error State View
struct RentalErrorStateView: View {
    let title: String
    let message: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 12) {
                Button(primaryButtonTitle) {
                    onPrimaryAction()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color("Violet"))
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button(secondaryButtonTitle) {
                    onSecondaryAction()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}


// MARK: - Initial Loading View
struct RentalInitialLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: Color("Violet")))
            
            Text("Preparing search...")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
