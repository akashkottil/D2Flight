import SwiftUI
import SafariServices

// MARK: - Tiny bridge so SwiftUI loader can tell UIKit to hide
final class LoaderState: ObservableObject {
    @Published var isVisible: Bool = true
    var onHide: (() -> Void)?
}

struct SafariView: UIViewControllerRepresentable {
    let url: String
    let providerName: String?
    let providerImageURL: String?
    @Environment(\.dismiss) private var dismiss

    // Stable identifier so updates don't trample other instances
    private let viewId = UUID()

    init(url: String, providerName: String? = nil, providerImageURL: String? = nil) {
        self.url = url
        self.providerName = providerName
        self.providerImageURL = providerImageURL
    }

    func makeUIViewController(context: Context) -> UIViewController {
        print("🌐 Creating SafariView for: \(url)")

        let containerVC = UIViewController()
        containerVC.view.backgroundColor = UIColor.systemBackground
        context.coordinator.containerVC = containerVC

        // Resolve final URL (with safe fallback)
        let finalURL: URL = URL(string: url) ?? URL(string: "https://google.com")!

        // Create & embed Safari VC
        let safariVC = SFSafariViewController.createConfiguredSafariVC(url: finalURL)
        safariVC.delegate = context.coordinator
        containerVC.addChild(safariVC)
        containerVC.view.addSubview(safariVC.view)
        safariVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            safariVC.view.topAnchor.constraint(equalTo: containerVC.view.topAnchor),
            safariVC.view.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor),
            safariVC.view.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor),
            safariVC.view.bottomAnchor.constraint(equalTo: containerVC.view.bottomAnchor)
        ])
        safariVC.didMove(toParent: containerVC)

        // --- 🔹 SwiftUI HOTEL LOADER overlay ---
        let loadingView = createHotelLoaderOverlay(context: context)
        containerVC.view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: containerVC.view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: containerVC.view.bottomAnchor)
        ])

        // Wire coordinator state
        context.coordinator.loadingView = loadingView
        context.coordinator.safariViewController = safariVC
        context.coordinator.dismissAction = { dismiss() }
        context.coordinator.initialURL = url
        context.coordinator.providerName = providerName
        context.coordinator.viewId = viewId

        // Track original domain for cross-domain redirect detection
        context.coordinator.initialDomain = URL(string: url)?
            .host?
            .replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression) ?? ""

        // Failsafe so loader never hangs
        context.coordinator.loadingTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak coordinator = context.coordinator] _ in
            print("⏰ Loading timeout reached - hiding loading view (failsafe)")
            coordinator?.hideLoadingView()
        }

        return containerVC
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard context.coordinator.viewId == viewId else {
            print("🌐 Skipping update for different view instance")
            return
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Create SwiftUI overlay (AnimatedHotelLoader)
    private func createHotelLoaderOverlay(context: Context) -> UIView {
        let state = LoaderState()
        state.isVisible = true
        context.coordinator.loaderState = state

        // When the SwiftUI loader finishes (sets isVisible = false), hide overlay
        state.onHide = { [weak coordinator = context.coordinator] in
            coordinator?.hideLoadingView()
        }

        // If you want to pass a specific image asset for the hotel icon, set hotelAssetName here.
        let root = AnimatedHotelLoader(
            hotelAssetName: "HotelIcon", // ⬅️ your asset; or leave to use SF Symbol fallback
            isVisible: Binding(
                get: { state.isVisible },
                set: { newValue in
                    state.isVisible = newValue
                    if newValue == false { state.onHide?() }
                }
            )
        )

        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear

        let container = UIView()
        container.backgroundColor = .clear

        if let parent = context.coordinator.containerVC {
            parent.addChild(host)
        }
        container.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: container.topAnchor),
            host.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        host.didMove(toParent: context.coordinator.containerVC)

        context.coordinator.loadingView = container
        context.coordinator.hostingController = host
        return container
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        // UI refs
        var loadingView: UIView?
        var hostingController: UIHostingController<AnimatedHotelLoader>?
        var safariViewController: SFSafariViewController?
        var containerVC: UIViewController?
        var dismissAction: (() -> Void)?
        var loaderState: LoaderState?

        // Inputs
        var initialURL: String = ""
        var providerName: String?
        var viewId: UUID?

        // State
        fileprivate var initialDomain: String = ""
        private var finalDomain: String = ""
        private var hasRedirectedToFinalDomain = false
        private var hasCompletedInitialLoad = false
        fileprivate var loadingTimer: Timer?
        private var isLoadingViewHidden = false

        // MARK: SFSafariViewControllerDelegate
        func safariViewController(_ controller: SFSafariViewController,
                                  didCompleteInitialLoad didLoadSuccessfully: Bool) {
            print("🌐 Safari didCompleteInitialLoad: \(didLoadSuccessfully)")
            hasCompletedInitialLoad = true
            loadingTimer?.invalidate()

            guard didLoadSuccessfully else {
                print("❌ Initial load failed - hiding loading view immediately")
                hideLoadingViewImmediately()
                return
            }

            if hasRedirectedToFinalDomain {
                hideLoadingView()
            } else {
                // Even without cross-domain redirect, hide shortly after first paint
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.hideLoadingView()
                }
            }
        }

        func safariViewController(_ controller: SFSafariViewController,
                                  initialLoadDidRedirectTo URL: URL) {
            let currentDomain = extractDomain(from: URL.absoluteString)
            print("🔄 Redirect: \(currentDomain) (initial: \(initialDomain))")
            if !currentDomain.isEmpty,
               currentDomain != initialDomain,
               !hasRedirectedToFinalDomain {
                finalDomain = currentDomain
                hasRedirectedToFinalDomain = true
                // Small delay so landing page paints before revealing it
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.hideLoadingView()
                }
            }
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            print("✅ Safari dismissed")
            loadingTimer?.invalidate()
        }

        // MARK: Helpers
        private func extractDomain(from urlString: String) -> String {
            guard let url = URL(string: urlString), let host = url.host else { return "" }
            return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        }

        // Immediate hide (failures)
        fileprivate func hideLoadingViewImmediately() {
            guard let loadingView = self.loadingView, !isLoadingViewHidden else { return }
            loadingTimer?.invalidate()
            isLoadingViewHidden = true
            DispatchQueue.main.async {
                loadingView.isHidden = true
                loadingView.removeFromSuperview()
                self.hostingController?.willMove(toParent: nil)
                self.hostingController?.view.removeFromSuperview()
                self.hostingController?.removeFromParent()
                print("✅ Loader removed immediately")
            }
        }

        // Animated hide (success)
        fileprivate func hideLoadingView() {
            guard let loadingView = self.loadingView, !isLoadingViewHidden else { return }
            loadingTimer?.invalidate()
            isLoadingViewHidden = true
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: {
                    loadingView.alpha = 0
                }) { _ in
                    loadingView.isHidden = true
                    loadingView.removeFromSuperview()
                    self.hostingController?.willMove(toParent: nil)
                    self.hostingController?.view.removeFromSuperview()
                    self.hostingController?.removeFromParent()
                    print("✅ Loader removed with fade")
                }
            }
        }
    }
}

// MARK: - Notification name (kept if you rely on it elsewhere)
extension Notification.Name {
    static let safariViewDidDismiss = Notification.Name("safariViewDidDismiss")
}

// MARK: - SFSafariViewController config
extension SFSafariViewController {
    static func createConfiguredSafariVC(url: URL) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.preferredControlTintColor = UIColor.systemOrange
        safariVC.preferredBarTintColor = UIColor.systemBackground
        safariVC.dismissButtonStyle = .close
        return safariVC
    }
}
