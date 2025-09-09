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
    let urlString: String

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                // 1) Show Safari immediately (prevents white flash)
                SafariWebViewWrapperForFlight(
                    urlString: urlString,
                    onInitialPaint: { isLoading = false },
                    onLoadFailed: handleWebViewError
                )
                .transition(.opacity)

                // 2) Fullscreen loader overlay (RESULT style)
                if isLoading {
                    AnimatedResultLoader(

                        isVisible: Binding(
                            get: { isLoading },
                            set: { newVal in if !newVal { isLoading = false } }
                        )
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text(alertMessage)
        }
    }

    private func handleWebViewError(_ error: Error) {
        alertTitle = "Unable to Load"
        alertMessage = "The booking page could not be loaded. Please try again."
        showAlert = true
        // You can also send a global warning/toast here if you have one
        // WarningManager.shared.showDeeplinkError(for: .flight, error: error)
    }
}

// MARK: - Safari wrapper (flight variant)
// Mirrors HotelSearchWebView's wrapper but calls onInitialPaint to hide the loader
struct SafariWebViewWrapperForFlight: UIViewControllerRepresentable {
    let urlString: String
    let onInitialPaint: (() -> Void)?
    let onLoadFailed: ((Error) -> Void)?

    init(urlString: String,
         onInitialPaint: (() -> Void)? = nil,
         onLoadFailed: ((Error) -> Void)? = nil) {
        self.urlString = urlString
        self.onInitialPaint = onInitialPaint
        self.onLoadFailed = onLoadFailed
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        guard let url = URL(string: urlString) else {
            let error = URLError(.badURL)
            onLoadFailed?(error)
            return SFSafariViewController(url: URL(string: "about:blank")!)
        }

        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true

        let safari = SFSafariViewController(url: url, configuration: config)
        safari.delegate = context.coordinator

        // Optional appearance (match your hotel config)
        safari.preferredControlTintColor = .label
        safari.preferredBarTintColor = .systemBackground
        safari.dismissButtonStyle = .close

        // Failsafe: hide loader if Safari didn't call back quickly
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            context.coordinator.hideLoaderIfStillVisible()
        }

        return safari
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        private let parent: SafariWebViewWrapperForFlight
        private var didHideOnce = false

        init(_ parent: SafariWebViewWrapperForFlight) { self.parent = parent }

        func safariViewController(_ controller: SFSafariViewController,
                                  didCompleteInitialLoad didLoadSuccessfully: Bool) {
            if didLoadSuccessfully {
                hideLoaderIfStillVisible()
            } else {
                parent.onLoadFailed?(URLError(.cannotLoadFromNetwork))
            }
        }

        func safariViewController(_ controller: SFSafariViewController,
                                  initialLoadDidRedirectTo url: URL) {
            // Small delay so landing page has painted before removing the loader
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.hideLoaderIfStillVisible()
            }
        }

        func hideLoaderIfStillVisible() {
            guard !didHideOnce else { return }
            didHideOnce = true
            parent.onInitialPaint?()
        }
    }
}
