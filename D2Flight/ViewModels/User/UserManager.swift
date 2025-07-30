//
//  UserManager.swift
//  D2Flight
//
//  Created by Akash Kottil on 30/07/25.
//


import Foundation
import UIKit
import Combine

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var userId: Int? = nil
    @Published var currentSessionId: Int? = nil
    @Published var isUserCreated: Bool = false
    
    private let userApi = UserApi.shared
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults keys
    private let userIdKey = "D2Flight_UserID"
    private let deviceIdKey = "D2Flight_DeviceID"
    private let vendorIdKey = "D2Flight_VendorID"
    private let pseudoIdKey = "D2Flight_PseudoID"
    private let userCreatedKey = "D2Flight_UserCreated"
    private let installDateKey = "D2Flight_InstallDate"
    
    private init() {
        loadStoredUserData()
    }
    
    // MARK: - Public Methods
    
    /// Initialize user on app launch
    func initializeUser() {
        if isUserCreated, let storedUserId = userId {
            print("👤 User already exists with ID: \(storedUserId)")
            // Create initial session for app launch
            createSession(eventType: .appLaunch, vertical: .general)
        } else {
            print("👤 Creating new user...")
            createNewUser()
        }
    }
    
    /// Create a new session for user events
    func createSession(
        eventType: UserEventType,
        vertical: UserVertical = .general,
        tag: String? = nil,
        additionalData: [String: String]? = nil
    ) {
        guard let userId = userId else {
            print("⚠️ Cannot create session: User ID not available")
            return
        }
        
        let request = SessionCreationRequest(
            user_id: userId,
            type: "api",
            tag: tag ?? eventType.rawValue,
            route: "organic",
            vertical: vertical.rawValue,
            country_code: getCurrentCountryCode(),
            ad_id: additionalData?["ad_id"],
            adgroup_id: additionalData?["adgroup_id"],
            campaign_id: additionalData?["campaign_id"],
            campaign_group_id: additionalData?["campaign_group_id"],
            account_id: additionalData?["account_id"],
            ad_objective_name: additionalData?["ad_objective_name"],
            gclid: additionalData?["gclid"],
            fbclid: additionalData?["fbclid"],
            msclkid: additionalData?["msclkid"]
        )
        
        userApi.createSession(request: request) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.currentSessionId = response.user_session_id
                    print("✅ Session created for event: \(eventType.rawValue)")
                case .failure(let error):
                    print("❌ Failed to create session for event \(eventType.rawValue): \(error)")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createNewUser() {
        let deviceId = getOrCreateDeviceId()
        let vendorId = getOrCreateVendorId()
        let pseudoId = getOrCreatePseudoId()
        
        let request = UserCreationRequest(
            device_id: deviceId,
            device_id_type: "idfa",
            app: "d1_ios_sflight",
            vendor_id: vendorId,
            pseudo_id: pseudoId,
            email: nil,
            acquired_route: "organic",
            referrer_url: nil
        )
        
        userApi.createUser(request: request) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self?.handleUserCreationSuccess(response)
                case .failure(let error):
                    self?.handleUserCreationFailure(error)
                }
            }
        }
    }
    
    private func handleUserCreationSuccess(_ response: UserCreationResponse) {
        userId = response.user_id
        isUserCreated = true
        
        // Store in UserDefaults
        userDefaults.set(response.user_id, forKey: userIdKey)
        userDefaults.set(true, forKey: userCreatedKey)
        userDefaults.set(Date(), forKey: installDateKey)
        
        print("✅ User created and stored successfully with ID: \(response.user_id)")
        
        // Create initial session for app launch
        createSession(eventType: .appLaunch, vertical: .general)
    }
    
    private func handleUserCreationFailure(_ error: Error) {
        print("❌ User creation failed: \(error)")
        // You might want to retry logic here or handle gracefully
    }
    
    private func loadStoredUserData() {
        userId = userDefaults.object(forKey: userIdKey) as? Int
        isUserCreated = userDefaults.bool(forKey: userCreatedKey)
        
        if isUserCreated {
            print("📱 Loaded stored user data - ID: \(userId ?? -1)")
        }
    }
    
    // MARK: - Device ID Generation
    
    private func getOrCreateDeviceId() -> String {
        if let storedDeviceId = userDefaults.string(forKey: deviceIdKey) {
            return storedDeviceId
        }
        
        // Try to get IDFA (Identifier for Advertisers)
        // For now, we'll generate a random ID since Firebase is not configured
        let deviceId = generateRandomDeviceId()
        userDefaults.set(deviceId, forKey: deviceIdKey)
        
        print("📱 Generated new device ID: \(deviceId)")
        return deviceId
    }
    
    private func getOrCreateVendorId() -> String {
        if let storedVendorId = userDefaults.string(forKey: vendorIdKey) {
            return storedVendorId
        }
        
        // Use iOS Vendor Identifier or generate random
        let vendorId = UIDevice.current.identifierForVendor?.uuidString ?? generateRandomUUID()
        userDefaults.set(vendorId, forKey: vendorIdKey)
        
        print("🏭 Generated vendor ID: \(vendorId)")
        return vendorId
    }
    
    private func getOrCreatePseudoId() -> String {
        if let storedPseudoId = userDefaults.string(forKey: pseudoIdKey) {
            return storedPseudoId
        }
        
        let pseudoId = generateRandomPseudoId()
        userDefaults.set(pseudoId, forKey: pseudoIdKey)
        
        print("🎭 Generated pseudo ID: \(pseudoId)")
        return pseudoId
    }
    
    // MARK: - ID Generators
    
    private func generateRandomDeviceId() -> String {
        return String(format: "%d%d%d", 
                     Int.random(in: 1000000...9999999),
                     Int.random(in: 1000000...9999999),
                     Int.random(in: 100000...999999))
    }
    
    private func generateRandomUUID() -> String {
        return UUID().uuidString
    }
    
    private func generateRandomPseudoId() -> String {
        let chars = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<21).map { _ in chars.randomElement()! })
    }
    
    private func getCurrentCountryCode() -> String {
        return Locale.current.regionCode ?? "IN"
    }
    
    // MARK: - Utility Methods
    
    /// Check if user exists and is valid
    var isValidUser: Bool {
        return isUserCreated && userId != nil
    }
    
    /// Get install date
    var installDate: Date? {
        return userDefaults.object(forKey: installDateKey) as? Date
    }
    
    /// Clear all user data (for testing or logout)
    func clearUserData() {
        userDefaults.removeObject(forKey: userIdKey)
        userDefaults.removeObject(forKey: userCreatedKey)
        userDefaults.removeObject(forKey: installDateKey)
        // Keep device-related IDs as they should persist
        
        userId = nil
        currentSessionId = nil
        isUserCreated = false
        
        print("🗑️ User data cleared")
    }
}