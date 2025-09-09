import SwiftUI
import SafariServices


// MARK: - Tiny bridge so SwiftUI loader can tell UIKit to hide
final class LoaderState: ObservableObject {
    @Published var isVisible: Bool = true
    var onHide: (() -> Void)?
}

enum LoaderStyle {
    case hotel
    case result
}

struct SafariView: UIViewControllerRepresentable {
    let url: String
    let providerName: String?
    let providerImageURL: String?

    // NEW: decide which full-screen loader to show
    var loaderStyle: LoaderStyle = .hotel

    @Environment(\.dismiss) private var dismiss
    private let viewId = UUID()

    init(url: String, providerName: String? = nil, providerImageURL: String? = nil, loaderStyle: LoaderStyle = .hotel) {
        self.url = url
        self.providerName = providerName
        self.providerImageURL = providerImageURL
        self.loaderStyle = loaderStyle
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let containerVC = UIViewController()
        containerVC.view.backgroundColor = UIColor.systemBackground
        context.coordinator.containerVC = containerVC

        let finalURL = URL(string: url) ?? URL(string: "https://google.com")!
        let safariVC = SFSafariViewController(url: finalURL)
        safariVC.dismissButtonStyle = .close        // optional, common default
        safariVC.preferredControlTintColor = .systemBlue
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

        // --- SwiftUI LOADER overlay (now style-aware) ---
        let loadingView = createLoaderOverlay(context: context)
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

        context.coordinator.initialDomain = URL(string: url)?
            .host?
            .replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression) ?? ""

        context.coordinator.loadingTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak coordinator = context.coordinator] _ in
            coordinator?.hideLoadingView()
        }

        return containerVC
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard context.coordinator.viewId == viewId else { return }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Create SwiftUI overlay (Hotel or Result loader)
    private func createLoaderOverlay(context: Context) -> UIView {
        let state = LoaderState()
        state.isVisible = true
        context.coordinator.loaderState = state

        // when SwiftUI loader hides, remove overlay in UIKit
        state.onHide = { [weak coordinator = context.coordinator] in
            coordinator?.hideLoadingView()
        }

        // Choose the loader
        let root: AnyView = {
            let bind = Binding<Bool>(
                get: { state.isVisible },
                set: { newValue in
                    state.isVisible = newValue
                    if newValue == false { state.onHide?() }
                }
            )
            switch loaderStyle {
            case .hotel:
                return AnyView(AnimatedHotelLoader(isVisible: bind))
            case .result:
                return AnyView(AnimatedResultLoader(isVisible: bind))
            }
        }()

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
        context.coordinator.hostingController = host          // now type-erased
        return container
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        // UI refs
        var loadingView: UIView?
        var hostingController: UIHostingController<AnyView>?  // <— generalized
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

        func safariViewController(_ controller: SFSafariViewController,
                                  didCompleteInitialLoad didLoadSuccessfully: Bool) {
            hasCompletedInitialLoad = true
            loadingTimer?.invalidate()
            guard didLoadSuccessfully else { hideLoadingViewImmediately(); return }
            if hasRedirectedToFinalDomain {
                hideLoadingView()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.hideLoadingView() }
            }
        }

        func safariViewController(_ controller: SFSafariViewController,
                                  initialLoadDidRedirectTo url: URL) {
            let currentDomain = extractDomain(from: url.absoluteString)
            if !currentDomain.isEmpty,
               currentDomain != initialDomain,
               !hasRedirectedToFinalDomain {
                finalDomain = currentDomain
                hasRedirectedToFinalDomain = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.hideLoadingView() }
            }
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            loadingTimer?.invalidate()
        }

        private func extractDomain(from urlString: String) -> String {
            guard let url = URL(string: urlString), let host = url.host else { return "" }
            return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        }

        fileprivate func hideLoadingViewImmediately() {
            guard let loadingView, !isLoadingViewHidden else { return }
            loadingTimer?.invalidate()
            isLoadingViewHidden = true
            DispatchQueue.main.async {
                loadingView.isHidden = true
                loadingView.removeFromSuperview()
                self.hostingController?.willMove(toParent: nil)
                self.hostingController?.view.removeFromSuperview()
                self.hostingController?.removeFromParent()
            }
        }

        fileprivate func hideLoadingView() {
            guard let loadingView, !isLoadingViewHidden else { return }
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
                }
            }
        }
    }
}
