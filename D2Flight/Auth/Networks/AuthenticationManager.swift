import Foundation
import SwiftUI
import GoogleSignIn
import FirebaseAuth
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // UserDefaults Keys
    private enum Keys {
        static let isLoggedIn = "D2Flight_IsLoggedIn"
        static let currentUser = "D2Flight_CurrentUser"
    }
    
    private init() {
        setupAuthStateListener()
        loadStoredUser()
    }
    
    // MARK: - Public Methods
    
    func signInWithGoogle() async {
        await performAuthentication {
            try await self.performGoogleSignIn()
        }
    }
    
    func signInWithFacebook() async {
        await performAuthentication {
            // Facebook implementation can be added here
            throw AuthError.configurationError
        }
    }
    
    func signOut() {
        isLoading = true
        
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Sign out from Google
            GIDSignIn.sharedInstance.signOut()
            
            // Clear stored data
            clearStoredUser()
            
            // Update state
            currentUser = nil
            isAuthenticated = false
            
            print("✅ User signed out successfully")
        } catch {
            print("❌ Sign out error: \(error)")
        }
        
        isLoading = false
    }
    
    func deleteAccount() async {
        guard let firebaseUser = Auth.auth().currentUser else {
            errorMessage = "No authenticated user found"
            return
        }
        
        isLoading = true
        errorMessage = nil // Clear previous errors
        
        do {
            // Step 1: Delete Firebase account
            try await firebaseUser.delete()
            
            // Step 2: Sign out from Google
            GIDSignIn.sharedInstance.signOut()
            
            // Step 3: Clear all local data
            clearStoredUser()
            
            // Step 4: Clear UserManager data (analytics/tracking data)
            UserManager.shared.clearUserData()
            
            // Step 5: Clear any other relevant app data
            clearAllAppUserData()
            
            // Step 6: Update authentication state
            currentUser = nil
            isAuthenticated = false
            
            print("✅ Account deleted successfully")
            
        } catch let authError as NSError {
            // Handle specific Firebase Auth errors
            handleDeleteAccountError(authError)
            print("❌ Account deletion failed: \(authError)")
        } catch {
            // Handle other errors
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
            print("❌ Account deletion failed: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    
                    let user = User(
                        id: firebaseUser.uid,
                        email: firebaseUser.email ?? "",
                        name: firebaseUser.displayName ?? "User",
                        profileImageURL: firebaseUser.photoURL?.absoluteString,
                        provider: .google, // You can determine this based on provider data
                        createdAt: firebaseUser.metadata.creationDate ?? Date(),
                        lastLoginAt: firebaseUser.metadata.lastSignInDate ?? Date()
                    )
                    
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    self?.storeUser(user)
                } else {
                    // User is signed out
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                    self?.clearStoredUser()
                }
            }
        }
    }
    
    private func performAuthentication(_ authAction: @escaping () async throws -> User) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authAction()
            print("✅ Authentication successful: \(user.email)")
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            print("❌ Authentication failed: \(error.localizedDescription)")
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            print("❌ Authentication failed: \(error)")
        }
        
        isLoading = false
    }
    
    private func performGoogleSignIn() async throws -> User {
        // ✅ FIXED: Get the root view controller properly
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw AuthError.configurationError
        }
        
        // Sign in with Google
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                if let error = error {
                    let nsError = error as NSError
                    if nsError.code == GIDSignInError.canceled.rawValue {
                        continuation.resume(throwing: AuthError.userCancelled)
                    } else {
                        continuation.resume(throwing: AuthError.unknownError(error.localizedDescription))
                    }
                } else if let result = result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: AuthError.invalidCredentials)
                }
            }
        }
        
        // Get Google ID token and access token
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidCredentials
        }
        
        let accessToken = result.user.accessToken.tokenString
        
        // Create Firebase credential
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        // Sign in to Firebase
        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user
        
        // Create User object
        let user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            name: firebaseUser.displayName ?? "User",
            profileImageURL: firebaseUser.photoURL?.absoluteString,
            provider: .google,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        
        return user
    }
    
    private func loadStoredUser() {
        // Firebase Auth State Listener will handle this automatically
        // This method can be used for additional local storage if needed
    }
    
    private func storeUser(_ user: User) {
        userDefaults.set(true, forKey: Keys.isLoggedIn)
        
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: Keys.currentUser)
        }
    }
    
    private func clearStoredUser() {
        userDefaults.removeObject(forKey: Keys.isLoggedIn)
        userDefaults.removeObject(forKey: Keys.currentUser)
        keychain.deleteAccessToken()
    }
    
    // MARK: - Private Helper Methods for Account Deletion
    
    private func handleDeleteAccountError(_ error: NSError) {
        // Firebase Auth error codes
        switch error.code {
        case AuthErrorCode.requiresRecentLogin.rawValue:
            errorMessage = "For security reasons, please sign in again before deleting your account."
            // Sign out user since re-authentication is required
            signOutSilently()
        case AuthErrorCode.networkError.rawValue:
            errorMessage = "Network connection error. Please check your internet connection and try again."
        case AuthErrorCode.tooManyRequests.rawValue:
            errorMessage = "Too many requests. Please try again later."
        case AuthErrorCode.userTokenExpired.rawValue:
            errorMessage = "Your session has expired. Please sign in again and try deleting your account."
            // Sign out user since session expired
            signOutSilently()
        case AuthErrorCode.userNotFound.rawValue:
            errorMessage = "User account not found."
            // Sign out user since account doesn't exist
            signOutSilently()
        case AuthErrorCode.userDisabled.rawValue:
            errorMessage = "This user account has been disabled."
            // Sign out user since account is disabled
            signOutSilently()
        case AuthErrorCode.operationNotAllowed.rawValue:
            errorMessage = "Account deletion is not allowed."
        default:
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
        }
    }
    
    // Silent sign out without loading state (used for error scenarios)
    private func signOutSilently() {
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Sign out from Google
            GIDSignIn.sharedInstance.signOut()
            
            // Clear stored data
            clearStoredUser()
            
            // Update state
            currentUser = nil
            isAuthenticated = false
            
            print("✅ User signed out silently due to auth error")
        } catch {
            print("❌ Silent sign out error: \(error)")
        }
    }
    
    private func clearAllAppUserData() {
        // Clear any other app-specific user data
        // This can include:
        
        // Clear recent locations
        RecentLocationsManager.shared.clearAllRecentLocations()
        
        // Clear any cached search data or preferences
        clearSearchPreferences()
        
        // Clear any other user-specific cached data
        clearUserCache()
        
        print("🗑️ All app user data cleared")
    }
    
    private func clearSearchPreferences() {
        // Clear search-related preferences
        let searchKeys = [
            "LastSearchOrigin",
            "LastSearchDestination",
            "LastSearchParameters",
            "SavedSearches"
        ]
        
        for key in searchKeys {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    private func clearUserCache() {
        // Clear any cached user data, images, etc.
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let userCacheURL = cacheURL.appendingPathComponent("UserData")
            try? FileManager.default.removeItem(at: userCacheURL)
        }
    }
}

// MARK: - RecentLocationsManager Extension
extension RecentLocationsManager {
    func clearAllRecentLocations() {
        // Clear recent locations from UserDefaults
        if let bundleId = Bundle.main.bundleIdentifier {
            let recentLocationsKey = "\(bundleId).RecentLocations"
            let recentSearchPairsKey = "\(bundleId).RecentSearchPairs"
            
            UserDefaults.standard.removeObject(forKey: recentLocationsKey)
            UserDefaults.standard.removeObject(forKey: recentSearchPairsKey)
        }
        
        // Clear in-memory data if applicable
        // If you have published properties like @Published var recentLocations: [RecentLocation] = []
        // Reset them here:
        // DispatchQueue.main.async {
        //     self.recentLocations = []
        //     self.recentSearchPairs = []
        // }
        
        print("🗑️ Recent locations cleared")
    }
}
