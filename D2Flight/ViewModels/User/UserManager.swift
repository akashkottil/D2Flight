//
//  UserManager.swift
//  D2Flight
//
//  Created by Akash Kottil on 30/07/25.
//

import Foundation
import UIKit
import Combine
import AdSupport  // ✅ NEW: Added import for IDFA support

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
    private let deviceIdTypeKey = "D2Flight_DeviceIDType"  // ✅ NEW: Store device ID type
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
            createSession(eventType: .appLaunch, vertical: .flight)
        } else {
            print("👤 Creating new user...")
            createNewUser()
        }
    }
    
    /// Create a new session for user events
    func createSession(
        eventType: UserEventType,
        vertical: UserVertical = .flight,
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
            route: "unknown",
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
        let (deviceId, deviceIdType) = getOrCreateDeviceId()
        let vendorId = getOrCreateVendorId()
        let pseudoId = getOrCreatePseudoId()
        
        let request = UserCreationRequest(
            device_id: deviceId,
            device_id_type: deviceIdType,
            app: "d1_ios_flight",
            vendor_id: vendorId,
            pseudo_id: pseudoId,
            email: nil,
            acquired_route: "unknown",
            referrer_url: nil
        )
        
        #if DEBUG
        print("👤 User Creation Parameters:")
        print("   Device ID: \(deviceId)")
        print("   Device ID Type: \(deviceIdType)")
        print("   App: \(request.app)")
        print("   Vendor ID: \(vendorId)")
        print("   Pseudo ID: \(pseudoId)")
        print("   Acquired Route: \(request.acquired_route)")
        #endif
        
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
        createSession(eventType: .appLaunch, vertical: .flight)
    }
    
    private func handleUserCreationFailure(_ error: Error) {
        print("❌ User creation failed: \(error)")
        // You might want to retry logic here or handle gracefully
    }
    
    private func loadStoredUserData() {
        userId = userDefaults.object(forKey: userIdKey) as? Int
        isUserCreated = userDefaults.bool(forKey: userCreatedKey)
        
        // ✅ UPDATED: Load device ID type for debugging/reference
        let deviceIdType = userDefaults.string(forKey: deviceIdTypeKey) ?? "unknown"
        
        if isUserCreated {
            print("📱 Loaded stored user data - ID: \(userId ?? -1), Device Type: \(deviceIdType)")
        }
    }
    
    // MARK: - Device ID Generation with Fallback
    
    // ✅ COMPLETELY UPDATED: New method with IDFA fallback to UUID
    private func getOrCreateDeviceId() -> (deviceId: String, deviceIdType: String) {
        // Check if we already have stored values
        if let storedDeviceId = userDefaults.string(forKey: deviceIdKey),
           let storedDeviceIdType = userDefaults.string(forKey: deviceIdTypeKey) {
            print("📱 Using stored device ID: \(storedDeviceId) (type: \(storedDeviceIdType))")
            return (storedDeviceId, storedDeviceIdType)
        }
        
        // Collect device ID with fallback logic (following reference code pattern)
        var deviceId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        var deviceIdType = "idfa"
        
        // Check if IDFA is unavailable (all zeros means no tracking permission)
        if deviceId == "00000000-0000-0000-0000-000000000000" {
            deviceIdType = "uuid"
            deviceId = UUID().uuidString
            print("📱 IDFA unavailable, using UUID fallback")
        } else {
            print("📱 IDFA available and valid")
        }
        
        // Store both values for future use
        userDefaults.set(deviceId, forKey: deviceIdKey)
        userDefaults.set(deviceIdType, forKey: deviceIdTypeKey)
        
        print("📱 Generated device ID: \(deviceId) (type: \(deviceIdType))")
        return (deviceId, deviceIdType)
    }
    
    private func getOrCreateVendorId() -> String {
        if let storedVendorId = userDefaults.string(forKey: vendorIdKey) {
            return storedVendorId
        }
        
        // Use iOS Vendor Identifier or generate random UUID
        let vendorId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
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
    
    // ✅ REMOVED: generateRandomDeviceId() method - no longer needed
    
    private func generateRandomPseudoId() -> String {
        let chars = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<21).map { _ in chars.randomElement()! })
    }
    
    private func getCurrentCountryCode() -> String {
        if #available(iOS 16.0, *) {
            return Locale.current.region?.identifier ?? "IN"
        } else {
            return Locale.current.regionCode ?? "IN"
        }
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
        userDefaults.removeObject(forKey: deviceIdTypeKey)  // ✅ NEW: Clear device ID type
        // Keep device-related IDs as they should persist across app sessions
        
        userId = nil
        currentSessionId = nil
        isUserCreated = false
        
        print("🗑️ User data cleared")
    }
}
