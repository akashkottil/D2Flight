import Foundation
import SwiftUI

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String = "en" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_language")
            print("🌐 Language changed to: \(currentLanguage)")
        }
    }
    
    private let userDefaults = UserDefaults.standard
    
    // Mapping of country codes to language codes
    private let countryToLanguageMap: [String: String] = [
        // English-speaking countries
        "US": "en", "GB": "en",  "AU": "en", "NZ": "en", "IE": "en", "ZA": "en",
        
        // Arabic countries
        "SA": "ar", "AE": "ar", "EG": "ar", "JO": "ar", "LB": "ar", "SY": "ar", "IQ": "ar", "YE": "ar", "OM": "ar", "QA": "ar", "KW": "ar", "BH": "ar",
        
        // Spanish countries
        "ES": "es", "MX": "es", "AR": "es", "CO": "es", "PE": "es", "VE": "es", "CL": "es", "EC": "es", "BO": "es", "PY": "es", "UY": "es", "GT": "es", "HN": "es", "SV": "es", "NI": "es", "CR": "es", "PA": "es", "DO": "es", "CU": "es", "PR": "es",
        
        // German countries
        "DE": "de", "AT": "de",  "LI": "de",
        
        // French countries
        "FR": "fr", "BE": "fr", "MC": "fr", "LU": "fr", "CH": "fr",
        
        // Italian countries
        "IT": "it", "SM": "it", "VA": "it",
        
        // Portuguese countries
        "PT": "pt", "BR": "pt", "AO": "pt", "MZ": "pt", "CV": "pt", "GW": "pt", "ST": "pt", "TL": "pt",
        
        // Russian countries
        "RU": "ru", "BY": "ru", "KZ": "ru", "KG": "ru", "TJ": "ru",
        
        // Chinese countries
        "CN": "zh-Hans", "TW": "zh-Hans", "HK": "zh-Hans", "MO": "zh-Hans", "SG": "zh-Hans",
        
        // Japanese
        "JP": "ja",
        
        // Korean
        "KR": "ko",
        
        // Other European languages
        "NL": "nl", "PL": "pl", "CZ": "cs", "SK": "cs", "HU": "he", "RO": "ro", "BG": "ru", "HR": "cs", "SI": "cs", "EE": "fi", "LV": "ru", "LT": "pl",
        
        // Nordic countries
        "NO": "nb", "SE": "sv", "DK": "da", "FI": "fi", "IS": "da",
        
        // Other languages
        "TR": "tr", "GR": "el", "IL": "he", "IN": "en", // India uses English by default
        "TH": "th", "VN": "vi", "ID": "id", "MY": "ms", "PH": "en",
        "UA": "uk", "CA": "en" // Canada defaults to English
    ]
    
    // Available languages in your app (based on your .lproj folders)
    private let availableLanguages: Set<String> = [
        "en", "ar", "ca", "cs", "da", "de", "el", "es", "fi", "fr", "he",
        "id", "it", "ja", "ko", "ms", "nb", "nl", "pl", "pt", "ro",
        "ru", "sv", "th", "tr", "uk", "vi", "zh-Hans"
    ]
    
    private init() {
        loadStoredLanguage()
    }
    
    // MARK: - Public Methods
    
    /// Update language based on selected country
    func updateLanguageForCountry(_ countryCode: String) {
        let newLanguage = getLanguageForCountry(countryCode)
        if newLanguage != currentLanguage {
            currentLanguage = newLanguage
            print("🌍 Country '\(countryCode)' → Language '\(newLanguage)'")
        }
    }
    
    /// Get localized string for current language
    func localizedString(for key: String) -> String {
        return localizedString(for: key, language: currentLanguage)
    }
    
    /// Get localized string for specific language
    func localizedString(for key: String, language: String) -> String {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to English if language not found
            return localizedStringFallback(for: key)
        }
        
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
        
        // If localization returns the key itself, try fallback
        if localizedString == key {
            return localizedStringFallback(for: key)
        }
        
        return localizedString
    }
    
    /// Get language code for country
    func getLanguageForCountry(_ countryCode: String) -> String {
        let upperCountryCode = countryCode.uppercased()
        let suggestedLanguage = countryToLanguageMap[upperCountryCode] ?? "en"
        
        // Check if the suggested language is available in our app
        if availableLanguages.contains(suggestedLanguage) {
            return suggestedLanguage
        }
        
        // Fallback to English if suggested language is not available
        return "en"
    }
    
    /// Get current language display name
    func getCurrentLanguageDisplayName() -> String {
        return getLanguageDisplayName(for: currentLanguage)
    }
    
    /// Get language display name
    func getLanguageDisplayName(for languageCode: String) -> String {
        let locale = Locale(identifier: languageCode)
        return locale.localizedString(forLanguageCode: languageCode)?.capitalized ?? languageCode.uppercased()
    }
    
    // MARK: - Private Methods
    
    private func loadStoredLanguage() {
        if let storedLanguage = userDefaults.string(forKey: "app_language"),
           availableLanguages.contains(storedLanguage) {
            currentLanguage = storedLanguage
            print("📱 Loaded stored language: \(storedLanguage)")
        } else {
            // Use system language as default if available
            let systemLanguage = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
            currentLanguage = availableLanguages.contains(String(systemLanguage)) ? String(systemLanguage) : "en"
            print("📱 Using default language: \(currentLanguage)")
        }
    }
    
    private func localizedStringFallback(for key: String) -> String {
        // Try English as fallback
        guard let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return key // Return key if even English is not found
        }
        
        let fallbackString = NSLocalizedString(key, bundle: bundle, comment: "")
        return fallbackString == key ? key : fallbackString
    }
}

// MARK: - String Extension for Easy Localization
extension String {
    /// Get localized version of this string
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    /// Get localized version with parameters
    func localized(with arguments: CVarArg...) -> String {
        let localizedString = LocalizationManager.shared.localizedString(for: self)
        return String(format: localizedString, arguments: arguments)
    }
}

// MARK: - SwiftUI Text Extension
extension Text {
    /// Create Text with localized string
    init(localized key: String) {
        self.init(LocalizationManager.shared.localizedString(for: key))
    }
    
    /// Create Text with localized string and parameters
    init(localized key: String, arguments: CVarArg...) {
        let localizedString = LocalizationManager.shared.localizedString(for: key)
        self.init(String(format: localizedString, arguments: arguments))
    }
}
