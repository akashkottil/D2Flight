import SwiftUI

struct AppEntryView: View {
    @State private var showSplash = true
    @StateObject private var localizationManager = LocalizationManager.shared

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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                showSplash = false
            }
        }
        .withHotReloadOverlay() // 🆕 Add hot reload overlay support
        // 🌐 IMPORTANT: Update environment locale when language changes
        .environment(\.locale, Locale(identifier: localizationManager.currentLanguage))
        // Force UI refresh when language changes
        .id(localizationManager.currentLanguage)
    }
}
