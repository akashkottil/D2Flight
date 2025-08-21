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
    
    // MARK: - ✅ FIXED: Language Management
    func getCurrentLanguageCode() -> String {
        let localizationManager = LocalizationManager.shared
        let currentLang = localizationManager.currentLanguage
        return mapLanguageToAPIFormat(currentLang)
    }
    
    // MARK: - ✅ SAFE: Manual Language Mapping (Same as APIConstants)
    private func mapLanguageToAPIFormat(_ language: String) -> String {
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
            if language.contains("-") {
                return language
            } else {
                print("⚠️ Unknown language '\(language)', falling back to en-GB")
                return "en-GB"
            }
        }
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
