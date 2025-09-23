import Foundation
import SwiftUI
import UIKit
import GoogleSignIn
import FirebaseAuth
import Combine
import AuthenticationServices
import CryptoKit

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let keychain = KeychainManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Nonce for Apple Sign In
    private var currentNonce: String?
    
    // MARK: - Init
    private override init() {
        super.init()
        setupAuthStateListener()
        loadStoredUser()
    }
    
    // MARK: - Google Sign In (unchanged)
    func signInWithGoogle() async {
        await performAuthentication {
            try await self.performGoogleSignIn()
        }
    }
    
    private func performGoogleSignIn() async throws -> User {
        // Get a presenting rootViewController safely in multi-scene apps
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            throw AuthError.configurationError
        }

        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
            GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
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
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidCredentials
        }
        let accessToken = result.user.accessToken.tokenString
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        let authResult = try await Auth.auth().signIn(with: credential)
        let fUser = authResult.user
        
        return User(
            id: fUser.uid,
            email: fUser.email ?? "",
            name: fUser.displayName ?? "User",
            profileImageURL: fUser.photoURL?.absoluteString,
            provider: .google, // left as-is per your request
            createdAt: Date(),
            lastLoginAt: Date()
        )
    }
    
    // MARK: - Apple Sign In (new)
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        // Generate nonce and build request
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)  // send SHA-256 hash to Apple
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - Sign out (unchanged)
    func signOut() {
        isLoading = true
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            clearStoredUser()
            currentUser = nil
            isAuthenticated = false
            print("✅ User signed out")
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
            print("❌ Sign out error: \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Delete account (unchanged interface)
    func deleteAccount() async {
        guard let firebaseUser = Auth.auth().currentUser else {
            errorMessage = "No authenticated user found"
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await firebaseUser.delete()
            GIDSignIn.sharedInstance.signOut()
            clearStoredUser()
            UserManager.shared.clearUserData()
            clearAllAppUserData()
            currentUser = nil
            isAuthenticated = false
            print("✅ Account deleted successfully")
        } catch let authError as NSError {
            handleDeleteAccountError(authError)
            print("❌ Account deletion failed: \(authError)")
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
            print("❌ Account deletion failed: \(error)")
        }
        isLoading = false
    }
    
    // MARK: - Auth state listener (kept as in your project)
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let fUser = firebaseUser {
                    // NOTE: If your project currently hard-codes .google here, I’m leaving it as-is.
                    // If you want automatic detection (apple.com/google.com), tell me to update it.
                    let user = User(
                        id: fUser.uid,
                        email: fUser.email ?? "",
                        name: fUser.displayName ?? "User",
                        profileImageURL: fUser.photoURL?.absoluteString,
                        provider: .google, // ← left untouched to avoid side-effects
                        createdAt: fUser.metadata.creationDate ?? Date(),
                        lastLoginAt: fUser.metadata.lastSignInDate ?? Date()
                    )
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    self?.storeUser(user)
                    self?.handleSuccessfulAuthentication()
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                    self?.clearStoredUser()
                }
            }
        }
    }
    
    private func handleSuccessfulAuthentication() {
        LoginTrackingManager.shared.userDidSignIn()
        print("🔐 Successful authentication tracked")
    }
    
    // MARK: - Common helpers (unchanged)
    private func performAuthentication(_ authAction: @escaping () async throws -> User) async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await authAction()
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func loadStoredUser() {
        // No-op: listener handles syncing
    }
    
    private func storeUser(_ user: User) {
        userDefaults.set(true, forKey: "D2Flight_IsLoggedIn")
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: "D2Flight_CurrentUser")
        }
    }
    
    private func clearStoredUser() {
        userDefaults.removeObject(forKey: "D2Flight_IsLoggedIn")
        userDefaults.removeObject(forKey: "D2Flight_CurrentUser")
        keychain.deleteAccessToken()
    }
    
    private func handleDeleteAccountError(_ error: NSError) {
        switch error.code {
        case AuthErrorCode.requiresRecentLogin.rawValue:
            errorMessage = "For security reasons, please sign in again."
            signOutSilently()
        case AuthErrorCode.networkError.rawValue:
            errorMessage = "Network error. Please try again."
        case AuthErrorCode.tooManyRequests.rawValue:
            errorMessage = "Too many requests. Please try later."
        case AuthErrorCode.userTokenExpired.rawValue:
            errorMessage = "Session expired. Please sign in again."
            signOutSilently()
        case AuthErrorCode.userNotFound.rawValue:
            errorMessage = "User not found."
            signOutSilently()
        case AuthErrorCode.userDisabled.rawValue:
            errorMessage = "This user is disabled."
            signOutSilently()
        case AuthErrorCode.operationNotAllowed.rawValue:
            errorMessage = "Operation not allowed."
        default:
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
        }
    }
    
    private func signOutSilently() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            clearStoredUser()
            currentUser = nil
            isAuthenticated = false
            print("✅ Silent sign out")
        } catch {
            print("❌ Silent sign out error: \(error)")
        }
    }
    
    private func clearAllAppUserData() {
        // NOTE: Removed RecentLocationsManager.shared.clearAllRecentLocations()
        // because the symbol doesn't exist in your project. If you have a
        // different cleanup entry point, tell me the exact method name and I’ll add it back.
        
        clearSearchPreferences()
        clearUserCache()
        print("🗑️ Cleared app user data")
    }
    
    private func clearSearchPreferences() {
        ["LastSearchOrigin","LastSearchDestination","LastSearchParameters","SavedSearches"].forEach {
            userDefaults.removeObject(forKey: $0)
        }
    }
    
    private func clearUserCache() {
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            try? FileManager.default.removeItem(at: cacheURL.appendingPathComponent("UserData"))
        }
    }
}

// MARK: - Apple Sign In delegates
extension AuthenticationManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            self.errorMessage = "Apple Sign In failed: Invalid credential"
            self.isLoading = false
            return
        }
        guard let nonce = currentNonce else {
            self.errorMessage = "Invalid state: no login request was sent."
            self.isLoading = false
            return
        }
        guard let tokenData = credential.identityToken,
              let idTokenString = String(data: tokenData, encoding: .utf8) else {
            self.errorMessage = "Unable to fetch identity token"
            self.isLoading = false
            return
        }
        
        // Build Firebase credential with raw nonce (Firebase verifies it against the token’s hash)
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )
        
        Task {
            do {
                let authResult = try await Auth.auth().signIn(with: firebaseCredential)
                print("🍎 Apple Sign In successful: \(authResult.user.email ?? "No email")")
            } catch {
                self.errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                print("Apple Sign In error: \(error)")
            }
            self.isLoading = false
        }
    }
    
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
        print("Apple Sign In error: \(error)")
        self.isLoading = false
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Key window for multi-scene apps
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            return window
        }
        return UIWindow()
    }
}

// MARK: - Apple nonce helpers
private extension AuthenticationManager {
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)")
            }
            for r in randoms where remaining > 0 {
                if r < charset.count {
                    result.append(charset[Int(r)])
                    remaining -= 1
                }
            }
        }
        return result
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
