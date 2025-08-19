//
//  APIConstants.swift
//  D2Flight
//
//  Created by Akash Kottil on 13/08/25.
//

import Foundation

// MARK: - Main API Constants (for flight/hotel/rental APIs)
struct APIConstants {
    // MARK: - Base URLs
    static let flightBaseURL = "https://staging.plane.lascade.com/api"
    static let hotelBaseURL = "https://staging.hotel.lascade.com"
    static let rentalBaseURL = "https://staging.car.lascade.com"
    
    // MARK: - Endpoints
    struct Endpoints {
        static let autocomplete = "/autocomplete"
        static let search = "/search/"
        static let poll = "/poll/"
        static let countries = "/countries/"
        static let currencies = "/currencies/"
        static let hotelDeeplink = "/deeplink/"
        static let rentalDeeplink = "/deeplink/"
    }
    
    // MARK: - Default Parameters
    struct DefaultParams {
        static let fallbackLanguage = "en-GB"  // ✅ UPDATED: Changed from language to fallbackLanguage
        static let appCode = "D1WF"
        static let fallbackUserId = "123" // Fallback if UserManager fails
        static let hotelProviderId = "0"
        static let rentalProviderId = "0"
        static let testAppCode = "TEST"
    }
    
    // MARK: - Headers
    struct Headers {
        static let accept = "application/json"
        static let contentType = "application/json"
        static let htmlAccept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    }
    
    // MARK: - ✅ NEW: Dynamic Language Helper
    static func getCurrentLanguageCode() -> String {
        return LocalizationManager.shared.apiLanguageCode
    }
    
    // MARK: - Helper Methods to Get Dynamic Values
    static func getCurrentCountryCode() -> String {
        return SettingsManager.shared.getSelectedCountryCode()
    }
    
    static func getCurrentCurrencyCode() -> String {
        return SettingsManager.shared.getSelectedCurrencyCode()
    }
    
    // MARK: - ✅ UPDATED: Include dynamic language in API parameters
    static func getAPIParameters() -> (country: String, currency: String, language: String) {
        let settingsParams = SettingsManager.shared.getAPIParameters()
        let currentLanguage = getCurrentLanguageCode()
        
        print("🌐 Getting API parameters:")
        print("   Country: \(settingsParams.country)")
        print("   Currency: \(settingsParams.currency)")
        print("   Language: \(currentLanguage)")
        
        return (
            country: settingsParams.country,
            currency: settingsParams.currency,
            language: currentLanguage  // ✅ Use dynamic language instead of hardcoded
        )
    }
    
    // MARK: - ✅ Dynamic User ID Helper
    static func getCurrentUserId() -> String {
        if let userId = UserManager.shared.userId {
            print("🔧 Using dynamic user ID: \(userId)")
            return String(userId)
        } else {
            print("⚠️ UserManager user ID not available, using fallback: \(DefaultParams.fallbackUserId)")
            return DefaultParams.fallbackUserId
        }
    }
    
    // MARK: - ✅ UPDATED: Complete API Parameters with User ID and Dynamic Language
    static func getCompleteAPIParameters() -> (country: String, currency: String, language: String, userId: String) {
        let basicParams = getAPIParameters()
        return (
            country: basicParams.country,
            currency: basicParams.currency,
            language: basicParams.language,  // ✅ Now includes dynamic language
            userId: getCurrentUserId()
        )
    }
    
    // MARK: - ✅ NEW: Helper to get language with fallback
    static func getLanguageWithFallback() -> String {
        let currentLanguage = getCurrentLanguageCode()
        
        // Validate that the language is not empty
        if currentLanguage.isEmpty {
            print("⚠️ Current language is empty, using fallback: \(DefaultParams.fallbackLanguage)")
            return DefaultParams.fallbackLanguage
        }
        
        return currentLanguage
    }
}
