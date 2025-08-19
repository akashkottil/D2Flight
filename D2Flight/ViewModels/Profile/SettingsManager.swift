import Foundation
import SwiftUI

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var selectedCountry: CountryInfo?
    @Published var selectedCurrency: CurrencyInfo?
    
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults Keys
    private enum Keys {
        static let selectedCountryCode = "D2Flight_SelectedCountryCode"
        static let selectedCurrencyCode = "D2Flight_SelectedCurrencyCode"
    }
    
    // Store the codes until data is loaded
    private var storedCountryCode: String?
    private var storedCurrencyCode: String?
    private var hasRestoredFromStorage = false
    
    private init() {
        loadStoredCodes()
        observeDataLoading()
    }
    
    // MARK: - Country Management
    func setSelectedCountry(_ country: CountryInfo) {
        selectedCountry = country
        userDefaults.set(country.countryCode, forKey: Keys.selectedCountryCode)
        print("🌍 Country updated to: \(country.countryName) (\(country.countryCode))")
    }
    
    func getSelectedCountryCode() -> String {
        return selectedCountry?.countryCode ?? storedCountryCode ?? "IN"
    }
    
    func getSelectedCountryName() -> String {
        return selectedCountry?.countryName ?? "India"
    }
    
    // MARK: - Currency Management
    func setSelectedCurrency(_ currency: CurrencyInfo) {
        selectedCurrency = currency
        userDefaults.set(currency.code, forKey: Keys.selectedCurrencyCode)
        print("💰 Currency updated to: \(currency.displayName) (\(currency.code))")
    }
    
    func getSelectedCurrencyCode() -> String {
        return selectedCurrency?.code ?? storedCurrencyCode ?? "INR"
    }
    
    func getSelectedCurrencySymbol() -> String {
        return selectedCurrency?.symbol ?? "₹"
    }
    
    // MARK: - ✅ NEW: Language Management
    func getCurrentLanguageCode() -> String {
        return LocalizationManager.shared.apiLanguageCode
    }
    
    // MARK: - Load Stored Codes (not objects)
    private func loadStoredCodes() {
        storedCountryCode = userDefaults.string(forKey: Keys.selectedCountryCode)
        storedCurrencyCode = userDefaults.string(forKey: Keys.selectedCurrencyCode)
        
        print("📱 Loaded stored codes - Country: \(storedCountryCode ?? "none"), Currency: \(storedCurrencyCode ?? "none")")
    }
    
    // MARK: - Observe Data Loading
    private func observeDataLoading() {
        // Observe country manager changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(countriesDidLoad),
            name: NSNotification.Name("CountriesDidLoad"),
            object: nil
        )
        
        // Observe currency manager changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(currenciesDidLoad),
            name: NSNotification.Name("CurrenciesDidLoad"),
            object: nil
        )
    }
    
    @objc private func countriesDidLoad() {
        restoreCountrySelection()
    }
    
    @objc private func currenciesDidLoad() {
        restoreCurrencySelection()
    }
    
    // MARK: - Restore Selections After Data Loads
    private func restoreCountrySelection() {
        guard let storedCode = storedCountryCode,
              selectedCountry == nil else { return }
        
        if let country = CountryManager.shared.countries.first(where: {
            $0.countryCode.lowercased() == storedCode.lowercased()
        }) {
            DispatchQueue.main.async {
                self.selectedCountry = country
                print("✅ Restored country selection: \(country.countryName)")
            }
        } else {
            setDefaultCountry()
        }
    }
    
    private func restoreCurrencySelection() {
        guard let storedCode = storedCurrencyCode,
              selectedCurrency == nil else { return }
        
        if let currency = CurrencyManager.shared.currencies.first(where: {
            $0.code == storedCode
        }) {
            DispatchQueue.main.async {
                self.selectedCurrency = currency
                print("✅ Restored currency selection: \(currency.displayName)")
            }
        } else {
            setDefaultCurrency()
        }
    }
    
    // MARK: - Set Defaults
    private func setDefaultCountry() {
        if let defaultCountry = CountryManager.shared.countries.first(where: {
            $0.countryCode.lowercased() == "in"
        }) {
            DispatchQueue.main.async {
                self.selectedCountry = defaultCountry
                print("🌍 Set default country: India")
            }
        }
    }
    
    private func setDefaultCurrency() {
        if let defaultCurrency = CurrencyManager.shared.currencies.first(where: {
            $0.code == "INR"
        }) {
            DispatchQueue.main.async {
                self.selectedCurrency = defaultCurrency
                print("💰 Set default currency: INR")
            }
        }
    }
    
    // MARK: - ✅ UPDATED: Helper Methods for API Calls (Now includes language)
    func getAPIParameters() -> (country: String, currency: String, language: String) {
        let currentLanguage = getCurrentLanguageCode()
        
        return (
            country: getSelectedCountryCode(),
            currency: getSelectedCurrencyCode(),
            language: currentLanguage
        )
    }
    
    // MARK: - ✅ NEW: Complete API Parameters with Language
    func getCompleteAPIParameters() -> (country: String, currency: String, language: String) {
        let params = getAPIParameters()
        
        print("🔧 SettingsManager API Parameters:")
        print("   Country: \(params.country)")
        print("   Currency: \(params.currency)")
        print("   Language: \(params.language)")
        
        return params
    }
    
    // MARK: - ✅ NEW: Language change notification method (for country selection)
    func setSelectedCountryDirectly(_ country: CountryInfo) {
        setSelectedCountry(country)
    }
    
    func setSelectedCountryWithLanguageCheck(
        _ country: CountryInfo,
        onLanguageAlert: @escaping (String, String, String) -> Void,
        onDirectUpdate: @escaping () -> Void
    ) {
        // Check if country has specific language preferences
        let currentLanguage = LocalizationManager.shared.currentLanguage
        let suggestedLanguages = country.supportedLanguages
        
        // If the country has supported languages and current language is not supported
        if !suggestedLanguages.isEmpty,
           !suggestedLanguages.contains(currentLanguage),
           let firstSupportedLanguage = suggestedLanguages.first {
            
            // Show language selection alert
            let currentLanguageName = getLanguageDisplayName(for: currentLanguage)
            let suggestedLanguageName = getLanguageDisplayName(for: firstSupportedLanguage)
            
            onLanguageAlert(country.countryName, currentLanguageName, suggestedLanguageName)
        } else {
            // Direct update without language change
            setSelectedCountry(country)
            onDirectUpdate()
        }
    }
    
    func handleLanguageSelection(
        _ selectedLanguage: String,
        for country: CountryInfo,
        completion: @escaping () -> Void
    ) {
        // Update country
        setSelectedCountry(country)
        
        // Update language if needed
        if selectedLanguage != LocalizationManager.shared.currentLanguage {
            if let newLanguageCode = getLanguageCode(for: selectedLanguage) {
                LocalizationManager.shared.changeLanguage(to: newLanguageCode)
                print("🌐 Language changed to: \(selectedLanguage) (\(newLanguageCode))")
            }
        }
        
        completion()
    }
    
    // MARK: - Helper methods for language display names
    private func getLanguageDisplayName(for code: String) -> String {
        switch code {
        case "en": return "English"
        case "ar": return "العربية"
        case "de": return "Deutsch"
        case "es": return "Español"
        case "fr": return "Français"
        case "hi": return "हिन्दी"
        case "it": return "Italiano"
        case "ja": return "日本語"
        case "ko": return "한국어"
        case "pt": return "Português"
        case "ru": return "Русский"
        case "zh": return "中文"
        case "th": return "ไทย"
        case "tr": return "Türkçe"
        case "vi": return "Tiếng Việt"
        case "id": return "Bahasa Indonesia"
        case "ms": return "Bahasa Melayu"
        case "nl": return "Nederlands"
        case "sv": return "Svenska"
        case "da": return "Dansk"
        case "no": return "Norsk"
        case "fi": return "Suomi"
        case "pl": return "Polski"
        case "cs": return "Čeština"
        case "hu": return "Magyar"
        case "ro": return "Română"
        default: return code.capitalized
        }
    }
    
    private func getLanguageCode(for displayName: String) -> String? {
        switch displayName {
        case "English": return "en"
        case "العربية": return "ar"
        case "Deutsch": return "de"
        case "Español": return "es"
        case "Français": return "fr"
        case "हिन्दी": return "hi"
        case "Italiano": return "it"
        case "日本語": return "ja"
        case "한국어": return "ko"
        case "Português": return "pt"
        case "Русский": return "ru"
        case "中文": return "zh"
        case "ไทย": return "th"
        case "Türkçe": return "tr"
        case "Tiếng Việt": return "vi"
        case "Bahasa Indonesia": return "id"
        case "Bahasa Melayu": return "ms"
        case "Nederlands": return "nl"
        case "Svenska": return "sv"
        case "Dansk": return "da"
        case "Norsk": return "no"
        case "Suomi": return "fi"
        case "Polski": return "pl"
        case "Čeština": return "cs"
        case "Magyar": return "hu"
        case "Română": return "ro"
        default: return nil
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
