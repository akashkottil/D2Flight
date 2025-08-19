//
//  LocalizationManager+API.swift
//  D2Flight
//
//  Extension to provide API-compatible language codes
//

import Foundation

extension LocalizationManager {
    
    // MARK: - API Language Code Mapping
    /// Returns the current language in a format suitable for API calls
    var apiLanguageCode: String {
        // Map iOS locale identifiers to API-expected format
        switch currentLanguage {
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
        case "zh":
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
        case "no":
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
        default:
            // For any unrecognized language, check if it already contains a region code
            if currentLanguage.contains("-") {
                return currentLanguage
            } else {
                // Default fallback to English GB
                print("⚠️ Unknown language '\(currentLanguage)', falling back to en-GB")
                return "en-GB"
            }
        }
    }
    
    // MARK: - Debug Helper
    func logCurrentLanguageForAPI() {
        print("🌐 LocalizationManager Language Info:")
        print("   Current Language: \(currentLanguage)")
        print("   API Language Code: \(apiLanguageCode)")
    }
    
    // MARK: - Validation Helper
    func validateAPILanguageCode() -> Bool {
        let apiCode = apiLanguageCode
        // Basic validation - should contain a hyphen and be at least 5 characters
        return apiCode.contains("-") && apiCode.count >= 5
    }
}
