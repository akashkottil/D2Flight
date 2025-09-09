import SwiftUI
import SafariServices

// MARK: - Enhanced Hotel Search Web View with Better Error Handling
struct HotelSearchWebView: View {
    @ObservedObject var hotelSearchVM: HotelSearchViewModel
    
    // ✅ NEW: Track location changes
        @State private var lastSearchedCity: String = ""
        @State private var lastSearchedCountry: String = ""
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                if let deeplink = hotelSearchVM.deeplink {
                    // Show Safari when URL is ready
                    SafariWebViewWrapper(
                        urlString: deeplink,
                        onLoadFailed: handleWebViewError
                    )
                    .transition(.opacity)
                } else if hotelSearchVM.isLoading {
                    // Show loading state with timeout indicator
                    AnimatedHotelLoader(
                        autoHide: false, // <- keep visible while VM is loading
                        isVisible: Binding(
                            get: { hotelSearchVM.isLoading },
                            set: { newValue in
                                // when loader asks to hide (e.g., user navigates), stop loading
                                if !newValue { hotelSearchVM.isLoading = false }
                            }
                        )
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                } else if let error = hotelSearchVM.errorMessage {
                    // Show error state with retry option
                    ErrorStateView(
                        title: "Hotel Search Failed",
                        message: error,
                        primaryButtonTitle: "Try Again",
                        secondaryButtonTitle: "Cancel",
                        onPrimaryAction: {
                            hotelSearchVM.searchHotels()
                        },
                        onSecondaryAction: {
                            dismiss()
                        }
                    )
                } else {
                    // Initial state - should start search immediately
                    InitialLoadingView()
                        .onAppear {
                            // Auto-start search if not already loading and no deeplink
                            if !hotelSearchVM.isLoading && hotelSearchVM.deeplink == nil {
                                hotelSearchVM.searchHotels()
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
        alertMessage = "The hotel search page could not be loaded. Please try again."
        showingAlert = true
        
        // Also show the universal warning
        WarningManager.shared.showDeeplinkError(for: .hotel, error: error)
    }
    
    private func startSearchIfNeeded() {
            let currentCity = hotelSearchVM.cityName
            let currentCountry = hotelSearchVM.countryName
            
            // Only search if location actually changed or it's the first search
            if currentCity != lastSearchedCity || currentCountry != lastSearchedCountry {
                print("🔍 Location changed - starting new search:")
                print("   Previous: \(lastSearchedCity), \(lastSearchedCountry)")
                print("   Current: \(currentCity), \(currentCountry)")
                
                lastSearchedCity = currentCity
                lastSearchedCountry = currentCountry
                
                // Start new search
                hotelSearchVM.searchHotels()
            } else {
                print("📍 Same location - skipping search")
            }
        }
    }



// MARK: - Enhanced Safari Web View Wrapper with Error Handling
struct SafariWebViewWrapper: UIViewControllerRepresentable {
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
        let parent: SafariWebViewWrapper
        
        init(_ parent: SafariWebViewWrapper) {
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

// MARK: - Loading State View with Timeout Handling
struct LoadingStateView: View {
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
struct ErrorStateView: View {
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
struct InitialLoadingView: View {
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
