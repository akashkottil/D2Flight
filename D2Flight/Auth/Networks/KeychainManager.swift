//
//  KeychainManager.swift
//  D2Flight
//
//  Created by Akash Kottil on 05/08/25.
//


import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.flightads.app.keychain"
    
    private init() {}
    
    func storeAccessToken(_ token: String) {
        store(key: "access_token", value: token)
    }
    
    func getAccessToken() -> String? {
        return retrieve(key: "access_token")
    }
    
    func deleteAccessToken() {
        delete(key: "access_token")
    }
    
    private func store(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}