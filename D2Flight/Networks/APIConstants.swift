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
        static let fallbackLanguage = "en-GB"  // Fallback if LocalizationManager fails
        static let appCode = "D1WF"
        static let fallbackUserId = "123" // Fallback if UserManager fails
        static let hotelProviderId = "0"
        static let rentalProviderId = "0"
        static let testAppCode = "D1WF"
    }
    
    // MARK: - Headers
    struct Headers {
        static let accept = "application/json"
        static let contentType = "application/json"
        static let htmlAccept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    }
    
    // MARK: - ✅ SAFE: Dynamic Language Helper with Fallback
    static func getCurrentLanguageCode() -> String {
        let localizationManager = LocalizationManager.shared
        
        // Try to get the API language code, with fallback
        let currentLang = localizationManager.currentLanguage
        return mapLanguageToAPIFormat(currentLang)
    }
    
    // MARK: - ✅ NEW: Manual Language Mapping (Safe Alternative)
    private static func mapLanguageToAPIFormat(_ language: String) -> String {
        switch language {
        case "en":
            return "en-GB"
        case "ar":
            return "ar-SA"
        case "de":
            return "de-DE"
        case "es":
            return "es-ES"
        case "fr":
            return "fr-FR"
        case "hi":
            return "hi-IN"
        case "it":
            return "it-IT"
        case "ja":
            return "ja-JP"
        case "ko":
            return "ko-KR"
        case "pt":
            return "pt-BR"
        case "ru":
            return "ru-RU"
        case "zh", "zh-Hans":
            return "zh-CN"
        case "th":
            return "th-TH"
        case "tr":
            return "tr-TR"
        case "vi":
            return "vi-VN"
        case "id":
            return "id-ID"
        case "ms":
            return "ms-MY"
        case "nl":
            return "nl-NL"
        case "sv":
            return "sv-SE"
        case "da":
            return "da-DK"
        case "no", "nb":
            return "no-NO"
        case "fi":
            return "fi-FI"
        case "pl":
            return "pl-PL"
        case "cs":
            return "cs-CZ"
        case "hu":
            return "hu-HU"
        case "ro":
            return "ro-RO"
        case "bg":
            return "bg-BG"
        case "hr":
            return "hr-HR"
        case "sk":
            return "sk-SK"
        case "sl":
            return "sl-SI"
        case "et":
            return "et-EE"
        case "lv":
            return "lv-LV"
        case "lt":
            return "lt-LT"
        case "el":
            return "el-GR"
        case "he":
            return "he-IL"
        case "uk":
            return "uk-UA"
        case "ca":
            return "ca-ES"
        default:
            // For any unrecognized language, check if it already contains a region code
            if language.contains("-") {
                return language
            } else {
                // Default fallback to English GB
                print("⚠️ Unknown language '\(language)', falling back to en-GB")
                return DefaultParams.fallbackLanguage
            }
        }
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
