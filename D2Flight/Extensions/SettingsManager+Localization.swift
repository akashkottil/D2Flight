import Foundation
import SwiftUI

// MARK: - SettingsManager Extension for Localization Integration
extension SettingsManager {
    
    // MARK: - Country Management with Language Update and Alert
    func setSelectedCountryWithLanguageCheck(
        _ country: CountryInfo,
        showLanguageAlert: @escaping (String, String, String) -> Void,
        onDirectUpdate: (() -> Void)? = nil
    ) {
        let currentLanguage = LocalizationManager.shared.currentLanguage
        let suggestedLanguage = LocalizationManager.shared.getLanguageForCountry(country.countryCode)
        
        // Check if suggested language is different from current
        if suggestedLanguage != currentLanguage {
            print("🌐 Language difference detected:")
            print("   Current: \(currentLanguage)")
            print("   Suggested for \(country.countryName): \(suggestedLanguage)")
            
            // Show language selection alert
            showLanguageAlert(country.countryName, currentLanguage, suggestedLanguage)
        } else {
            // Same language, update directly
            setSelectedCountryDirectly(country)
            onDirectUpdate?()
        }
    }
    
    // MARK: - Direct Country Update (without language check)
    func setSelectedCountryDirectly(_ country: CountryInfo) {
        setSelectedCountry(country)
        print("🌍 Country updated directly to: \(country.countryName) (\(country.countryCode))")
    }
    
    // MARK: - Handle Language Selection from Alert
    func handleLanguageSelection(
        _ selectedLanguage: String,
        for country: CountryInfo,
        completion: @escaping () -> Void
    ) {
        // Always update the country first
        setSelectedCountry(country)
        
        let currentLanguage = LocalizationManager.shared.currentLanguage
        
        // If user selected a different language, update and hot reload
        if selectedLanguage != currentLanguage {
            print("🔄 Language change requested: \(currentLanguage) → \(selectedLanguage)")
            
            // Update language
            LocalizationManager.shared.currentLanguage = selectedLanguage
            
            // Show reload notification and hot reload UI
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.hotReloadApp {
                    completion()
                }
            }
        } else {
            print("🌐 Staying in current language: \(currentLanguage)")
            completion()
        }
    }
    
    // MARK: - Hot Reload App (Better than restart)
    private func hotReloadApp(completion: @escaping () -> Void) {
        print("🔄 Hot reloading app for language change...")
        
        // Post notification for UI reload
        NotificationCenter.default.post(
            name: NSNotification.Name("AppWillHotReloadForLanguageChange"),
            object: nil
        )
        
        // Allow time for the reload animation, then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NotificationCenter.default.post(
                name: NSNotification.Name("AppDidHotReloadForLanguageChange"),
                object: nil
            )
            completion()
        }
    }
    
    // MARK: - Legacy method (kept for compatibility)
    func setSelectedCountryWithLanguage(_ country: CountryInfo) {
        setSelectedCountry(country)
        LocalizationManager.shared.updateLanguageForCountry(country.countryCode)
        
        print("🌍 Country updated to: \(country.countryName) (\(country.countryCode))")
        print("🌐 Language updated to: \(LocalizationManager.shared.currentLanguage)")
    }
    
    // Override the original method to include language update
    func updateSelectedCountry(_ country: CountryInfo) {
        setSelectedCountryWithLanguage(country)
    }
}
