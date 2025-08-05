//
//  AuthenticationManager.swift
//  D2Flight
//
//  Created by Akash Kottil on 05/08/25.
//


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
        guard let firebaseUser = Auth.auth().currentUser else { return }
        
        isLoading = true
        
        do {
            // Delete Firebase account
            try await firebaseUser.delete()
            
            // Clear local data
            clearStoredUser()
            
            // Update state
            currentUser = nil
            isAuthenticated = false
            
            print("✅ Account deleted successfully")
        } catch {
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
        guard let presentingViewController = await UIApplication.shared.windows.first?.rootViewController else {
            throw AuthError.configurationError
        }
        
        // Sign in with Google
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
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
        guard let idToken = result.user.idToken?.tokenString,
              let accessToken = result.user.accessToken.tokenString else {
            throw AuthError.invalidCredentials
        }
        
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
}

// MARK: - UIApplication Extension
extension UIApplication {
    var windows: [UIWindow] {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
    }
}
