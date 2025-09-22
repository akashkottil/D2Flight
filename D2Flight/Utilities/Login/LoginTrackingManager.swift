//
//  LoginTrackingManager.swift
//  D2Flight
//
//  Created by Akash Kottil on 22/09/25.
//


//
//  LoginTrackingManager.swift
//  D2Flight
//
//  Created for managing first-time user login flow and 15-day reminder system
//

import Foundation
import SwiftUI
import Combine

class LoginTrackingManager: ObservableObject {
    static let shared = LoginTrackingManager()
    
    // MARK: - Published Properties
    @Published var shouldShowLoginPrompt = false
    @Published var shouldShowInitialLogin = false
    
    // MARK: - UserDefaults Keys
    private struct Keys {
        static let hasLaunchedBefore = "LoginTrackingManager_hasLaunchedBefore"
        static let firstLaunchDate = "LoginTrackingManager_firstLaunchDate"
        static let lastLoginSkippedDate = "LoginTrackingManager_lastLoginSkippedDate"
        static let loginSkipCount = "LoginTrackingManager_loginSkipCount"
        static let userHasEverSignedIn = "LoginTrackingManager_userHasEverSignedIn"
    }
    
    private let userDefaults = UserDefaults.standard
    private let fifteenDaysInterval: TimeInterval = 15 * 24 * 60 * 60 // 15 days in seconds
    
    private init() {
        checkLoginRequirement()
    }
    
    // MARK: - Public Methods
    
    /// Check if login should be shown based on app state and user history
    func checkLoginRequirement() {
        let hasLaunchedBefore = userDefaults.bool(forKey: Keys.hasLaunchedBefore)
        let userHasEverSignedIn = userDefaults.bool(forKey: Keys.userHasEverSignedIn)
        
        print("🔐 LoginTrackingManager: Checking login requirements")
        print("   Has launched before: \(hasLaunchedBefore)")
        print("   User has ever signed in: \(userHasEverSignedIn)")
        
        if !hasLaunchedBefore {
            // First time user - show initial login
            handleFirstLaunch()
        } else if !userHasEverSignedIn {
            // User has launched before but never signed in - check 15-day rule
            checkFifteenDayRule()
        } else {
            // User has signed in before - no need to show login
            shouldShowLoginPrompt = false
            shouldShowInitialLogin = false
            print("   Result: User has signed in before - no login prompt needed")
        }
    }
    
    /// Call this when user successfully signs in
    func userDidSignIn() {
        print("🔐 LoginTrackingManager: User signed in successfully")
        userDefaults.set(true, forKey: Keys.userHasEverSignedIn)
        shouldShowLoginPrompt = false
        shouldShowInitialLogin = false
        
        // Clear skip tracking since user signed in
        userDefaults.removeObject(forKey: Keys.lastLoginSkippedDate)
        userDefaults.removeObject(forKey: Keys.loginSkipCount)
    }
    
    /// Call this when user skips/dismisses the login
    func userDidSkipLogin() {
        print("🔐 LoginTrackingManager: User skipped login")
        let currentDate = Date()
        userDefaults.set(currentDate, forKey: Keys.lastLoginSkippedDate)
        
        let currentSkipCount = userDefaults.integer(forKey: Keys.loginSkipCount)
        userDefaults.set(currentSkipCount + 1, forKey: Keys.loginSkipCount)
        
        shouldShowLoginPrompt = false
        shouldShowInitialLogin = false
        
        print("   Skip count: \(currentSkipCount + 1)")
        print("   Next reminder in 15 days: \(Calendar.current.date(byAdding: .day, value: 15, to: currentDate) ?? currentDate)")
    }
    
    /// Call this when user signs out
    func userDidSignOut() {
        print("🔐 LoginTrackingManager: User signed out")
        // Don't change userHasEverSignedIn - once they've signed in, we remember it
        // This prevents showing the initial login again after logout
    }
    
    /// Reset all tracking (useful for testing or complete app reset)
    func resetLoginTracking() {
        print("🔐 LoginTrackingManager: Resetting all login tracking")
        userDefaults.removeObject(forKey: Keys.hasLaunchedBefore)
        userDefaults.removeObject(forKey: Keys.firstLaunchDate)
        userDefaults.removeObject(forKey: Keys.lastLoginSkippedDate)
        userDefaults.removeObject(forKey: Keys.loginSkipCount)
        userDefaults.removeObject(forKey: Keys.userHasEverSignedIn)
        
        shouldShowLoginPrompt = false
        shouldShowInitialLogin = false
    }
    
    // MARK: - Private Methods
    
    private func handleFirstLaunch() {
        print("🔐 LoginTrackingManager: First launch detected")
        let currentDate = Date()
        
        userDefaults.set(true, forKey: Keys.hasLaunchedBefore)
        userDefaults.set(currentDate, forKey: Keys.firstLaunchDate)
        
        shouldShowInitialLogin = true
        shouldShowLoginPrompt = false
        
        print("   Result: Showing initial login for first-time user")
    }
    
    private func checkFifteenDayRule() {
        guard let lastSkippedDate = userDefaults.object(forKey: Keys.lastLoginSkippedDate) as? Date else {
            // Never skipped before, but launched before - show login
            print("🔐 LoginTrackingManager: User launched before but never interacted with login")
            shouldShowLoginPrompt = true
            shouldShowInitialLogin = false
            print("   Result: Showing login prompt")
            return
        }
        
        let daysSinceLastSkip = Calendar.current.dateComponents([.day], from: lastSkippedDate, to: Date()).day ?? 0
        let skipCount = userDefaults.integer(forKey: Keys.loginSkipCount)
        
        print("🔐 LoginTrackingManager: Checking 15-day rule")
        print("   Days since last skip: \(daysSinceLastSkip)")
        print("   Skip count: \(skipCount)")
        
        if daysSinceLastSkip >= 15 {
            shouldShowLoginPrompt = true
            shouldShowInitialLogin = false
            print("   Result: 15+ days passed - showing login prompt")
        } else {
            shouldShowLoginPrompt = false
            shouldShowInitialLogin = false
            print("   Result: Less than 15 days - no login prompt")
        }
    }
    
    // MARK: - Debug Helper Methods
    
    func getDebugInfo() -> [String: Any] {
        let hasLaunchedBefore = userDefaults.bool(forKey: Keys.hasLaunchedBefore)
        let firstLaunchDate = userDefaults.object(forKey: Keys.firstLaunchDate) as? Date
        let lastSkippedDate = userDefaults.object(forKey: Keys.lastLoginSkippedDate) as? Date
        let skipCount = userDefaults.integer(forKey: Keys.loginSkipCount)
        let userHasEverSignedIn = userDefaults.bool(forKey: Keys.userHasEverSignedIn)
        
        return [
            "hasLaunchedBefore": hasLaunchedBefore,
            "firstLaunchDate": firstLaunchDate?.description ?? "nil",
            "lastSkippedDate": lastSkippedDate?.description ?? "nil",
            "skipCount": skipCount,
            "userHasEverSignedIn": userHasEverSignedIn,
            "shouldShowLoginPrompt": shouldShowLoginPrompt,
            "shouldShowInitialLogin": shouldShowInitialLogin
        ]
    }
}