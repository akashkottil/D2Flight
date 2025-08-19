import Foundation
import SwiftUI

// MARK: - SettingsManager Extension for Localization Integration
extension SettingsManager {
    
    // MARK: - Country Management with Language Update
    func setSelectedCountryWithLanguage(_ country: CountryInfo) {
        // Use the main setSelectedCountry method to ensure proper storage
        setSelectedCountry(country)
        
        // 🌐 UPDATE LANGUAGE BASED ON COUNTRY
        LocalizationManager.shared.updateLanguageForCountry(country.countryCode)
        
        print("🌍 Country updated to: \(country.countryName) (\(country.countryCode))")
        print("🌐 Language updated to: \(LocalizationManager.shared.currentLanguage)")
    }
    
    // Override the original method to include language update
    func updateSelectedCountry(_ country: CountryInfo) {
        setSelectedCountryWithLanguage(country)
    }
}
