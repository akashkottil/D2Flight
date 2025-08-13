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
        static let language = "en-GB"
        static let appCode = "D1WF"
        static let fallbackUserId = "123" // Fallback if UserManager fails
        static let hotelProviderId = "0"
        static let rentalProviderId = "0"
        static let testAppCode = "TEST"
    }
    
    // MARK: - CSRF Tokens (should be moved to secure storage in production)
    struct CSRFTokens {
        static let hotel = "090QuftLMGgFvDzcpACrLkDlcjuaXJnSeMPG0fi752drUyjrgHR36YDpCXVlCJXJ"
        static let rental = "zx744wOlRDblepgD7fnZ8w8pdmGDQRW5wE41KoUrxjujQIvSZe7acO7CBBLlWOEF"
        static let profile = "g3X72prcldulQHlvGDpC4QS50jGaDZfFIfdAqOHBOn4d553ig2GKRabT46i33LcB"
    }
    
    // MARK: - Headers
    struct Headers {
        static let accept = "application/json"
        static let contentType = "application/json"
        static let htmlAccept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    }
    
    // MARK: - Helper Methods to Get Dynamic Values
    static func getCurrentCountryCode() -> String {
        return SettingsManager.shared.getSelectedCountryCode()
    }
    
    static func getCurrentCurrencyCode() -> String {
        return SettingsManager.shared.getSelectedCurrencyCode()
    }
    
    static func getAPIParameters() -> (country: String, currency: String, language: String) {
        let settingsParams = SettingsManager.shared.getAPIParameters()
        return (
            country: settingsParams.country,
            currency: settingsParams.currency,
            language: DefaultParams.language
        )
    }
    
    // MARK: - ✅ NEW: Dynamic User ID Helper
    static func getCurrentUserId() -> String {
        if let userId = UserManager.shared.userId {
            print("🔧 Using dynamic user ID: \(userId)")
            return String(userId)
        } else {
            print("⚠️ UserManager user ID not available, using fallback: \(DefaultParams.fallbackUserId)")
            return DefaultParams.fallbackUserId
        }
    }
    
    // MARK: - ✅ NEW: Complete API Parameters with User ID
    static func getCompleteAPIParameters() -> (country: String, currency: String, language: String, userId: String) {
        let basicParams = getAPIParameters()
        return (
            country: basicParams.country,
            currency: basicParams.currency,
            language: basicParams.language,
            userId: getCurrentUserId()
        )
    }
}
