import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: String
    let providerName: String?
    let providerImageURL: String?
    @Environment(\.dismiss) private var dismiss
    
    
    // FIXED: Add stable identifier and loading state
    private let viewId = UUID()
    @State private var hasLoadingCompleted = false
    
    // UPDATED: Add providerImageURL parameter
    init(url: String, providerName: String? = nil, providerImageURL: String? = nil) {
        self.url = url
        self.providerName = providerName
        self.providerImageURL = providerImageURL
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        print("🌐 Creating SafariView for: \(url)")
        
        let containerVC = UIViewController()
        containerVC.view.backgroundColor = UIColor.systemBackground
        
        // Create Safari view controller first
        let finalURL: URL
        if let validURL = URL(string: url) {
            finalURL = validURL
        } else {
            print("⚠️ Invalid URL: \(url). Using fallback.")
            finalURL = URL(string: "https://google.com")!
        }
        
        let safariVC = SFSafariViewController.createConfiguredSafariVC(url: finalURL)
        safariVC.preferredControlTintColor = UIColor.systemOrange
        safariVC.delegate = context.coordinator
        
        // FIXED: Add Safari view as child immediately and make it visible
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
        
        // FIXED: Create loading view that covers Safari view initially
        let loadingView = createLottieLoadingView(context: context)
        containerVC.view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: containerVC.view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: containerVC.view.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: containerVC.view.trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: containerVC.view.bottomAnchor)
        ])
        
        // Store references for coordinator
        context.coordinator.loadingView = loadingView
        context.coordinator.safariViewController = safariVC
        context.coordinator.containerVC = containerVC
        context.coordinator.dismissAction = {
            dismiss()
        }
        context.coordinator.initialURL = url
        context.coordinator.providerName = providerName
        context.coordinator.viewId = viewId
        
        return containerVC
    }
    

    
    // Rest of the existing SafariView code remains unchanged...
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // FIXED: Only update if this is the same view instance
        guard context.coordinator.viewId == viewId else {
            print("🌐 Skipping update for different view instance")
            return
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    private func createLottieLoadingView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor(.white)
        
        // Create main content stack following Figma design
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        // "All flights" logo section (top)
        let allFlightsStack = UIStackView()
        allFlightsStack.axis = .horizontal
        allFlightsStack.spacing = 8
        allFlightsStack.alignment = .center
        
        let logoImageView = UIImageView(image: UIImage(named: "D2Flight"))
        logoImageView.tintColor = UIColor.white
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoImageView.widthAnchor.constraint(equalToConstant: 32),
            logoImageView.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        let allFlightsLabel = UILabel()
        allFlightsLabel.text = "All flights"
        allFlightsLabel.font = UIFont.systemFont(ofSize: 28, weight: .medium)
        allFlightsLabel.textColor = UIColor(named: "allflights")
        
        allFlightsStack.addArrangedSubview(logoImageView)
        allFlightsStack.addArrangedSubview(allFlightsLabel)
        
        // Lottie scroll animation (middle section) with vertical spacing
        let lottieContainer = UIView()
        lottieContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let lottieView = createLottieAnimationView()
        lottieView.translatesAutoresizingMaskIntoConstraints = false
        
        lottieContainer.addSubview(lottieView)
        
        NSLayoutConstraint.activate([
            lottieView.widthAnchor.constraint(equalToConstant: 60),
            lottieView.heightAnchor.constraint(equalToConstant: 62),
            lottieView.centerXAnchor.constraint(equalTo: lottieContainer.centerXAnchor),
            lottieView.centerYAnchor.constraint(equalTo: lottieContainer.centerYAnchor),
            lottieView.topAnchor.constraint(equalTo: lottieContainer.topAnchor, constant: 24),
            lottieView.bottomAnchor.constraint(equalTo: lottieContainer.bottomAnchor, constant: -24)
        ])
        
        // Partner section (image only - no name)
        let partnerStack = UIStackView()
        partnerStack.axis = .horizontal
        partnerStack.spacing = 8
        partnerStack.alignment = .center
        
        // Partner image - same size as All flights section
        let partnerImageView = UIImageView()
        partnerImageView.contentMode = .scaleAspectFit
        partnerImageView.layer.cornerRadius = 16
        partnerImageView.clipsToBounds = true
        partnerImageView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        partnerImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            partnerImageView.widthAnchor.constraint(equalToConstant: 120),
            partnerImageView.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        partnerStack.addArrangedSubview(partnerImageView)
        
        // Add sections to main stack
        mainStack.addArrangedSubview(allFlightsStack)
        mainStack.addArrangedSubview(lottieContainer)
        mainStack.addArrangedSubview(partnerStack)
        
        containerView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            mainStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -40),
            mainStack.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20)
        ])
        
        // Bottom text section
        let bottomStack = UIStackView()
        bottomStack.axis = .vertical
        bottomStack.spacing = 2
        bottomStack.alignment = .center
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        
        let foundDealLabel = UILabel()
        foundDealLabel.text = "Found a great deal".localized
        foundDealLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        foundDealLabel.textColor = UIColor.black
        foundDealLabel.textAlignment = .center
        foundDealLabel.numberOfLines = 0
        
        let displayName = providerName ?? extractDomainForDisplay(from: url)
        let onPartnerLabel = UILabel()
        onPartnerLabel.text = String(format: "on %@".localized, displayName)

        onPartnerLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        onPartnerLabel.textColor = UIColor.black
        onPartnerLabel.textAlignment = .center
        
        let takingYouLabel = UILabel()
        takingYouLabel.text = String(format: "Taking you to %@ website".localized, displayName)
        takingYouLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        takingYouLabel.textColor = UIColor.black.withAlphaComponent(0.7)
        takingYouLabel.textAlignment = .center
        
        bottomStack.addArrangedSubview(foundDealLabel)
        bottomStack.addArrangedSubview(onPartnerLabel)
        bottomStack.addArrangedSubview(takingYouLabel)
        
        containerView.addSubview(bottomStack)
        NSLayoutConstraint.activate([
            bottomStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bottomStack.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            bottomStack.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20),
            bottomStack.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20)
        ])
        
        // Store context for later domain updates (removed partnerNameLabel reference)
        context.coordinator.partnerImageView = partnerImageView
        context.coordinator.onPartnerLabel = onPartnerLabel
        context.coordinator.takingYouLabel = takingYouLabel
        
        // UPDATED: Set fallback image first
        partnerImageView.image = UIImage(systemName: "globe")
        partnerImageView.tintColor = UIColor.gray
        
        // UPDATED: Load provider images with proper priority
        loadProviderImage(into: partnerImageView, context: context)
        
        return containerView
    }
    
    private func extractDomainForDisplay(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return "Partner"
        }
        
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return domain.prefix(1).capitalized + domain.dropFirst()
    }
    
    private func createLottieAnimationView() -> UIView {
        return ScrollLottieAnimation.createScrollAnimationView()
    }
    
    // NEW: Proper image loading with API image as primary source
    private func loadProviderImage(into imageView: UIImageView, context: Context) {
        // Priority 1: Use API provider image if available
        if let apiImageURL = providerImageURL, !apiImageURL.isEmpty {
            print("🎯 Loading API provider image: \(apiImageURL)")
            context.coordinator.loadImageFromURL(apiImageURL, into: imageView) { success in
                if !success {
                    print("⚠️ API image failed, trying favicon fallback")
                    self.loadFaviconFallback(into: imageView, context: context)
                }
            }
        } else {
            // Priority 2: No API image available, use favicon
            print("📄 No API image, using favicon fallback")
            loadFaviconFallback(into: imageView, context: context)
        }
    }
    
    // NEW: Favicon fallback method
    private func loadFaviconFallback(into imageView: UIImageView, context: Context) {
        if let urlHost = URL(string: url)?.host {
            let faviconURL = "https://www.google.com/s2/favicons?domain=\(urlHost)&sz=32"
            print("🌐 Loading favicon: \(faviconURL)")
            context.coordinator.loadImageFromURL(faviconURL, into: imageView) { success in
                if !success {
                    print("❌ Both API image and favicon failed - keeping fallback globe icon")
                }
            }
        }
    }
    
    // MARK: - Enhanced Coordinator with Better State Management
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var loadingView: UIView?
        var safariViewController: SFSafariViewController?
        var containerVC: UIViewController?
        var dismissAction: (() -> Void)?
        var initialURL: String = ""
        var providerName: String?
        var viewId: UUID?
        
        // Labels to update with final domain
        var partnerNameLabel: UILabel?
        var partnerImageView: UIImageView?
        var onPartnerLabel: UILabel?
        var takingYouLabel: UILabel?
        
        // FIXED: Better state management
        private var hasStartedLoading = false
        private var hasCompletedInitialLoad = false
        private var hasRedirectedToFinalDomain = false
        private var loadingTimer: Timer?
        private var initialDomain: String = ""
        private var finalDomain: String = ""
        private var isLoadingViewHidden = false
        
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            print("🌐 Safari didCompleteInitialLoad: \(didLoadSuccessfully)")
            
            hasCompletedInitialLoad = true
            loadingTimer?.invalidate()
            
            if !didLoadSuccessfully {
                print("❌ Initial load failed - hiding loading view immediately")
                hideLoadingViewImmediately()
                return
            }
            
            // REMOVED: No longer hiding loading view here automatically
            // Only hide if we've already redirected to final domain
            if hasRedirectedToFinalDomain {
                print("✅ Already redirected - hiding loading view")
                hideLoadingView()
            } else {
                print("⏳ Waiting for domain redirect before hiding loading view")
            }
        }
        
        func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
            let urlString = URL.absoluteString
            print("🔄 Safari redirected to: \(urlString)")
            
            if initialDomain.isEmpty {
                initialDomain = extractDomain(from: urlString)
                print("📍 Initial domain stored: \(initialDomain)")
                return
            }
            
            let currentDomain = extractDomain(from: urlString)
            print("🔍 Current domain: \(currentDomain)")
            
            if currentDomain != initialDomain && !currentDomain.isEmpty && !hasRedirectedToFinalDomain {
                finalDomain = currentDomain
                hasRedirectedToFinalDomain = true
                
                print("✅ Redirected away from initial domain (\(initialDomain)) to final domain (\(finalDomain))")
                
                // Only update labels if we don't have a provider name
                if providerName == nil {
                    updateLabelsWithFinalDomain(currentDomain)
                }
                
                // MODIFIED: Hide loading view only after redirect is confirmed with additional delay
                print("⏰ Starting delay timer - will hide loading view in 2.5 seconds")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    print("⏰ Delay timer completed - now hiding loading view")
                    self.hideLoadingView()
                }
            }
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            print("✅ Safari view controller finished")
            loadingTimer?.invalidate()

        }
        
        private func extractDomain(from urlString: String) -> String {
            guard let url = URL(string: urlString),
                  let host = url.host else {
                return ""
            }
            
            let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            return domain
        }
        
        private func updateLabelsWithFinalDomain(_ domain: String) {
            guard providerName == nil else {
                print("🏷️ Provider name available, not updating with domain")
                return
            }
            
            let displayDomain = domain.prefix(1).capitalized + domain.dropFirst()
            
            DispatchQueue.main.async {
                self.partnerNameLabel?.text = displayDomain
                self.onPartnerLabel?.text = "on \(displayDomain)"
                self.takingYouLabel?.text = "Taking you to \(displayDomain) website"
                
                // Load provider favicon as image
                if let imageView = self.partnerImageView {
                    let faviconURL = "https://www.google.com/s2/favicons?domain=\(domain)&sz=32"
                    self.loadImageFromURL(faviconURL, into: imageView)
                }
                
                print("🏷️ Updated labels and image with final domain: \(displayDomain)")
            }
        }
        
        // FIXED: Immediate loading view hide for failures
        private func hideLoadingViewImmediately() {
            guard let loadingView = self.loadingView else {
                print("⚠️ Loading view is nil - cannot hide")
                return
            }
            
            guard !isLoadingViewHidden else {
                print("⚠️ Loading view already hidden")
                return
            }
            
            loadingTimer?.invalidate()
            isLoadingViewHidden = true
            print("🎬 Hiding loading view immediately")
            
            DispatchQueue.main.async {
                loadingView.isHidden = true
                loadingView.removeFromSuperview()
                print("✅ Loading view removed immediately - Safari view visible")
            }
        }
        
        // FIXED: Better loading view hide with animation
        private func hideLoadingView() {
            guard let loadingView = self.loadingView else {
                print("⚠️ Loading view is nil - cannot hide")
                return
            }
            
            guard !isLoadingViewHidden else {
                print("⚠️ Loading view already hidden")
                return
            }
            
            loadingTimer?.invalidate()
            isLoadingViewHidden = true
            print("🎬 Hiding loading view with animation")
            
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: {
                    loadingView.alpha = 0
                }) { completed in
                    if completed {
                        loadingView.isHidden = true
                        loadingView.removeFromSuperview()
                        print("✅ Loading view removed with animation - Safari view visible")
                    }
                }
            }
        }
        
        // UPDATED: Enhanced image loading with completion callback
        func loadImageFromURL(_ urlString: String, into imageView: UIImageView, completion: ((Bool) -> Void)? = nil) {
            guard let url = URL(string: urlString) else {
                completion?(false)
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else {
                    print("❌ Image loading failed for: \(urlString)")
                    DispatchQueue.main.async {
                        completion?(false)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    if let image = UIImage(data: data) {
                        print("✅ Image loaded successfully: \(urlString)")
                        imageView.image = image
                        imageView.tintColor = nil // Remove tint for actual images
                        completion?(true)
                    } else {
                        print("❌ Image data invalid for: \(urlString)")
                        completion?(false)
                    }
                }
            }.resume()
        }
    }
}

// MARK: - Notification Names Extension
extension Notification.Name {
    static let safariViewDidDismiss = Notification.Name("safariViewDidDismiss")
}

extension SFSafariViewController{
    static func createConfiguredSafariVC(url: URL) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false // Disable reader mode
        config.barCollapsingEnabled = true
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.preferredControlTintColor = UIColor.systemOrange
        safariVC.preferredBarTintColor = UIColor.systemBackground
        safariVC.dismissButtonStyle = .close
        return safariVC
      }
}
