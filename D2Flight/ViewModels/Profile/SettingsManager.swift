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
    
    // MARK: - Helper Methods for API Calls
    func getAPIParameters() -> (country: String, currency: String) {
        return (
            country: getSelectedCountryCode(),
            currency: getSelectedCurrencyCode()
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
