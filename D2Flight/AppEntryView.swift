import SwiftUI

struct AppEntryView: View {
    @State private var showSplash = true
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var loginTrackingManager = LoginTrackingManager.shared
    @EnvironmentObject var authManager: AuthenticationManager
    
    // State for controlling login presentation
    @State private var showLoginView = false

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreen()
                    .transition(.opacity)
            } else {
                RootTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.6), value: showSplash)
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView(isLoggedIn: .constant(false))
                .environmentObject(authManager)
                .onAppear {
                    // Track that login view was presented
                    print("🔐 Login view presented")
                }
                .onDisappear {
                    // Handle login view dismissal
                    handleLoginViewDismissal()
                }
        }
        .onAppear {
            handleAppLaunch()
        }
        .onReceive(loginTrackingManager.$shouldShowInitialLogin) { shouldShow in
            if shouldShow && !authManager.isAuthenticated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { // After splash screen
                    showLoginView = true
                }
            }
        }
        .onReceive(loginTrackingManager.$shouldShowLoginPrompt) { shouldShow in
            if shouldShow && !authManager.isAuthenticated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { // After splash screen
                    showLoginView = true
                }
            }
        }
        .onReceive(authManager.$isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                // User signed in successfully
                loginTrackingManager.userDidSignIn()
                showLoginView = false
            }
        }
        .withHotReloadOverlay() // 🆕 Add hot reload overlay support
        // 🌐 IMPORTANT: Update environment locale when language changes
        .environment(\.locale, Locale(identifier: localizationManager.currentLanguage))
        // Force UI refresh when language changes
        .id(localizationManager.currentLanguage)
    }
    
    // MARK: - Private Methods
    
    private func handleAppLaunch() {
        // Handle splash screen timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            showSplash = false
        }
        
        // Check login requirements after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            loginTrackingManager.checkLoginRequirement()
        }
    }
    
    private func handleLoginViewDismissal() {
        // This is called when the login view is dismissed
        // If user is not authenticated, they either skipped or failed to sign in
        if !authManager.isAuthenticated {
            loginTrackingManager.userDidSkipLogin()
            print("🔐 User dismissed login view without signing in")
        }
    }
}
