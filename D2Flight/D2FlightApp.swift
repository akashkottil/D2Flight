import SwiftUI
import GoogleSignIn
import FirebaseCore
import FirebaseAuth

@main
struct D2FlightApp: App {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    
    init() {
        setupUserTracking()
        setupFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .environmentObject(userManager)
                .environmentObject(authManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Track app becoming active
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
    
    private func setupUserTracking() {
        UserManager.shared.initializeUser()
    }
    
    private func setupFirebase() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("❌ Failed to load Firebase configuration")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        print("✅ Firebase and Google Sign-In configured successfully")
    }
}
