import SwiftUI

// MARK: - Hot Reload Overlay View
struct HotReloadOverlayView: View {
    @State private var isVisible = false
    @State private var progress: Double = 0.0
    @State private var currentStep = 0
    @State private var isComplete = false
    
    private let steps = [
        "Updating language...",
        "Refreshing interface...",
        "Applying changes...",
        "Almost done..."
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // Reload card
            VStack(spacing: 24) {
                // App icon or logo
                Image("AboutLogo") // Use your app logo
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .scaleEffect(isVisible ? 1.2 : 1.0) // Pulsing between normal and larger size
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isVisible
                    )

                
                VStack(spacing: 8) {
                    Text("language.changed.restart.required".localized)
                        .font(CustomFont.font(.large, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    
                    Text(currentStep < steps.count ? steps[currentStep] : "Complete!")
                        .font(CustomFont.font(.medium))
                        .foregroundColor(.white.opacity(0.8))
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
                
                // Progress indicator
                VStack(spacing: 12) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color("Violet")))
                        .frame(width: 200)
                    
                    Text("\(Int(progress * 100))%")
                        .font(CustomFont.font(.small))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                if isComplete {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Language updated successfully!")
                            .font(CustomFont.font(.medium))
                            .foregroundColor(.green)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.9))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
            
            startProgressAnimation()
        }
    }
    
    private func startProgressAnimation() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation(.linear(duration: 0.05)) {
                progress = min(progress + 0.025, 1.0) // Clamp to maximum of 1.0
            }
            
            // Update steps
            let newStep = Int(progress * Double(steps.count))
            if newStep != currentStep && newStep < steps.count {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = newStep
                }
            }
            
            if progress >= 1.0 {
                timer.invalidate()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isComplete = true
                }
                
                // Auto dismiss after completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AppDidHotReloadForLanguageChange"),
                        object: nil
                    )
                }
            }
        }
    }
}

// MARK: - Hot Reload Modifier
struct HotReloadOverlayModifier: ViewModifier {
    @State private var showReloadOverlay = false
    @StateObject private var localizationManager = LocalizationManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if showReloadOverlay {
                        HotReloadOverlayView()
                            .zIndex(999)
                    }
                }
            )
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppWillHotReloadForLanguageChange"))) { _ in
                showReloadOverlay = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppDidHotReloadForLanguageChange"))) { _ in
                withAnimation(.easeInOut(duration: 1.5)) {
                    showReloadOverlay = false
                }
            }
            // 🌐 IMPORTANT: This ensures UI updates when language changes
            .environment(\.locale, Locale(identifier: localizationManager.currentLanguage))
    }
}

extension View {
    func withHotReloadOverlay() -> some View {
        modifier(HotReloadOverlayModifier())
    }
}
