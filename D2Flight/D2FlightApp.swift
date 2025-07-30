import SwiftUI

@main
struct D2FlightApp: App {
    @StateObject private var userManager = UserManager.shared
    
    init() {
        // Initialize user management on app launch
        setupUserTracking()
    }
    
    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .environmentObject(userManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Track app becoming active
                    UserManager.shared.createSession(eventType: .appLaunch, vertical: .flight)
                }
        }
    }
    
    private func setupUserTracking() {
        // Initialize user on app launch
        UserManager.shared.initializeUser()
    }
}
