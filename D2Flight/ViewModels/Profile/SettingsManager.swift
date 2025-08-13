//
//  SettingsManager.swift
//  D2Flight
//
//  Created by Akash Kottil on 13/08/25.
//


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
    
    private init() {
        loadStoredSettings()
    }
    
    // MARK: - Country Management
    func setSelectedCountry(_ country: CountryInfo) {
        selectedCountry = country
        userDefaults.set(country.countryCode, forKey: Keys.selectedCountryCode)
        print("🌍 Country updated to: \(country.countryName) (\(country.countryCode))")
    }
    
    func getSelectedCountryCode() -> String {
        return selectedCountry?.countryCode ?? "IN" // Default to India
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
        return selectedCurrency?.code ?? "INR" // Default to Indian Rupee
    }
    
    func getSelectedCurrencySymbol() -> String {
        return selectedCurrency?.symbol ?? "₹"
    }
    
    // MARK: - Load Stored Settings
    private func loadStoredSettings() {
        // Load stored country
        if let storedCountryCode = userDefaults.string(forKey: Keys.selectedCountryCode) {
            // Find country from CountryManager
            if let country = CountryManager.shared.countries.first(where: { $0.countryCode.lowercased() == storedCountryCode.lowercased() }) {
                selectedCountry = country
            }
        }
        
        // Load stored currency
        if let storedCurrencyCode = userDefaults.string(forKey: Keys.selectedCurrencyCode) {
            // Find currency from CurrencyManager
            if let currency = CurrencyManager.shared.currencies.first(where: { $0.code == storedCurrencyCode }) {
                selectedCurrency = currency
            }
        }
        
        // Set defaults if nothing is stored
        setDefaultsIfNeeded()
    }
    
    private func setDefaultsIfNeeded() {
        // Set default country if none selected
        if selectedCountry == nil {
            if let defaultCountry = CountryManager.shared.countries.first(where: { $0.countryCode.lowercased() == "in" }) {
                selectedCountry = defaultCountry
            }
        }
        
        // Set default currency if none selected
        if selectedCurrency == nil {
            if let defaultCurrency = CurrencyManager.shared.currencies.first(where: { $0.code == "INR" }) {
                selectedCurrency = defaultCurrency
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
}