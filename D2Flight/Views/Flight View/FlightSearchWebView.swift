//
//  FlightSearchWebView.swift
//  D2Flight
//
//  Created by Akash Kottil on 09/09/25.
//

import SwiftUI
import SafariServices

// MARK: - Flight Search Web View (mirrors HotelSearchWebView)
struct FlightSearchWebView: View {
    let url: URL
    var requiredRedirects: Int = 2   // how many redirects before we hide the loader

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                // Show Safari immediately (prevents white flash)
                SafariWebViewWrapperForFlight(
                    url: url,
                    requiredRedirects: requiredRedirects,
                    onInitialPaint: { isLoading = false },
                    onLoadFailed: handleWebViewError
                )
                .transaction { $0.disablesAnimations = true }
                    .animation(nil, value: isLoading)   // no layout/position animation when loader toggles
                    .animation(nil, value: requiredRedirects)
                .transition(.opacity)

                // Fullscreen loader overlay (RESULT style)
                if isLoading {
                    AnimatedResultLoader(
                        isVisible: Binding(
                            get: { isLoading },
                            set: { newVal in if !newVal { isLoading = false } }
                        ),
                        autoHideAfter: nil // parent (wrapper) decides when to hide
                    )
                    .ignoresSafeArea()
                            .transition(.opacity)
                }
            }
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text(alertMessage)
        }
    }

    private func handleWebViewError(_ error: Error) {
        print("🔗 FlightSearchWebView error occurred:")
        print("   Error: \(error)")
        print("   Original URL: '\(url.absoluteString)'")

        if let urlError = error as? URLError {
            switch urlError.code {
            case .badURL, .unsupportedURL:
                alertTitle = "Invalid Link"
                alertMessage = "This booking link is not valid. Please try a different provider."
                showAlert = true

            case .timedOut:
                // Our failsafe decided nothing progressed → genuine issue
                alertTitle = "Connection Timeout"
                alertMessage = "The booking site is taking too long to respond. Please try again."
                showAlert = true

            case .cannotLoadFromNetwork:
                // Transient & often false negative from SFSafariVC. Ignore if still loading.
                if !isLoading {
                    // If we were already visible, show a non-blocking toast if you want:
                    // WarningManager.shared.showInfoToast("Connection was interrupted, retrying…")
                }
                return

            default:
                // Be conservative—don’t spam modals for transient issues
                return
            }
        } else {
            // Unknown error: avoid modal unless you really need it
            return
        }


        showAlert = true
        // Global warning for consistency with the rest of the app
        WarningManager.shared.showDeeplinkError(for: .flight, error: error)
    }
}

// MARK: - Safari wrapper (flight variant) with redirect counting
struct SafariWebViewWrapperForFlight: UIViewControllerRepresentable {
    let url: URL
    let requiredRedirects: Int
    let onInitialPaint: (() -> Void)?
    let onLoadFailed: ((Error) -> Void)?

    init(url: URL,
         requiredRedirects: Int = 2,
         onInitialPaint: (() -> Void)? = nil,
         onLoadFailed: ((Error) -> Void)? = nil) {
        self.url = url
        self.requiredRedirects = max(0, requiredRedirects)
        self.onInitialPaint = onInitialPaint
        self.onLoadFailed = onLoadFailed
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        print("🔗 SafariWebViewWrapperForFlight DEBUG:")
        print("   Input URL: '\(url.absoluteString)'")

        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            print("❌ SAFARI CRASH CAUSE: Unsupported or missing scheme for URL: '\(url)'")
            onLoadFailed?(URLError(.unsupportedURL))
            return SFSafariViewController(url: URL(string: "https://example.com")!)
        }

        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = false

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.delegate = context.coordinator

        // Optional appearance
        safari.preferredControlTintColor = .label
        safari.preferredBarTintColor = .systemBackground
        safari.dismissButtonStyle = .close

        // Failsafe: if callbacks don’t arrive, hide after 12s so user isn’t stuck
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
            context.coordinator.hideLoaderIfStillVisible()
        }

        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        private let parent: SafariWebViewWrapperForFlight
        private var didHideOnce = false
        private var redirectCount = 0

        init(_ parent: SafariWebViewWrapperForFlight) { self.parent = parent }

        func safariViewController(_ controller: SFSafariViewController,
                                  initialLoadDidRedirectTo url: URL) {
            redirectCount += 1
            print("↪️ Redirect #\(redirectCount) to \(url.absoluteString)")
            if redirectCount >= parent.requiredRedirects {
                // Tiny delay so the final page paints before removing loader
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.hideLoaderIfStillVisible()
                }
            }
        }

        func safariViewController(_ controller: SFSafariViewController,
                                  didCompleteInitialLoad didLoadSuccessfully: Bool) {
            if didLoadSuccessfully {
                // Only hide automatically if the required redirect threshold is 0
                // or we already reached it via initialLoadDidRedirectTo.
                if parent.requiredRedirects == 0 || redirectCount >= parent.requiredRedirects {
                    hideLoaderIfStillVisible()
                }
            } else {
                parent.onLoadFailed?(URLError(.cannotLoadFromNetwork))
            }
        }

        func hideLoaderIfStillVisible() {
            guard !didHideOnce else { return }
            didHideOnce = true
            parent.onInitialPaint?()
        }
    }
}
