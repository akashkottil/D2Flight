import SwiftUI

struct Country: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var countryManager = CountryManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var searchText: String = ""
    
    // Language alert state
    @State private var showLanguageAlert = false
    @State private var selectedCountryForAlert: CountryInfo?
    @State private var alertCurrentLanguage = ""
    @State private var alertSuggestedLanguage = ""
    
    // Filtered countries based on search with selected country at top
    private var filteredCountries: [CountryInfo] {
        let baseCountries: [CountryInfo]
        
        if searchText.isEmpty {
            baseCountries = countryManager.countries
        } else {
            baseCountries = countryManager.searchCountries(query: searchText)
        }
        
        // If no search text, order with selected country at top
        if searchText.isEmpty, let selectedCountry = settingsManager.selectedCountry {
            // Remove selected country from the list first
            let otherCountries = baseCountries.filter { $0.countryCode != selectedCountry.countryCode }
            
            // Find the selected country in the list
            if let selectedCountryInList = baseCountries.first(where: { $0.countryCode == selectedCountry.countryCode }) {
                // Put selected country first, then other countries
                return [selectedCountryInList] + otherCountries
            }
        }
        
        // For search results or when no selected country, return as is
        return baseCountries
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("BlackArrow")
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    Text("select.country".localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.trailing, 44)
                    Spacer()
                }
                .padding(.vertical)
                
                Divider()
                
                // Search Bar
                HStack(spacing: 20) {
                    Image("search")
                        .frame(width: 14,height: 14)
                    
                    TextField("search.country".localized, text: $searchText)
                        .font(CustomFont.font(.medium))
                        .foregroundColor(.primary)
                    
                    // Clear button
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(.gray.opacity(0.2))
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.top)
                
                // Content Area
                if countryManager.isLoading {
                    // Loading State
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("loading.countries".localized)
                            .font(CustomFont.font(.regular))
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                    
                } else if let errorMessage = countryManager.errorMessage {
                    // Error State
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("error.loading.countries".localized)
                            .font(CustomFont.font(.medium, weight: .semibold))
                        
                        Text(errorMessage)
                            .font(CustomFont.font(.regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button("try.again".localized) {
                            countryManager.loadCountries()
                        }
                        .foregroundColor(.blue)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                    
                } else if filteredCountries.isEmpty {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("no.countries.found".localized)
                            .font(CustomFont.font(.medium, weight: .semibold))
                        
                        Text("try.searching.with.a.different.keyword".localized)
                            .font(CustomFont.font(.regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                    
                } else {
                    // Country List
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(Array(filteredCountries.enumerated()), id: \.element.id) { index, country in
                                HStack(spacing: 20) {
                                    // Selection Radio Button
                                    ZStack {
                                        if settingsManager.selectedCountry?.countryCode == country.countryCode {
                                            Circle()
                                                .stroke(Color("Violet"), lineWidth: 6)
                                                .frame(width: 20, height: 20)
                                            
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 16, height: 16)
                                        } else {
                                            Circle()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(country.countryName)
                                                .foregroundColor(.primary)
                                                .font(CustomFont.font(.medium))
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Text(country.countryCode.uppercased())
                                        .font(CustomFont.font(.medium))
                                        .foregroundColor(.red)
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    handleCountrySelection(country)
                                }
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
        .languageSelectionAlert(
            isPresented: $showLanguageAlert,
            countryName: selectedCountryForAlert?.countryName ?? "",
            currentLanguage: alertCurrentLanguage,
            suggestedLanguage: alertSuggestedLanguage,
            onLanguageSelected: { selectedLanguage in
                if let country = selectedCountryForAlert {
                    handleLanguageSelectionResult(selectedLanguage, for: country)
                }
            }
        )
        .onAppear {
            // Set default selection if none exists
            if settingsManager.selectedCountry == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    setDefaultCountrySelection()
                }
            }
        }
    }
    
    // MARK: - ✅ FIXED: Handle Country Selection
    private func handleCountrySelection(_ country: CountryInfo) {
        print("🌍 Country tapped: \(country.countryName) (\(country.countryCode))")
        
        // Check if language should change based on country
        let currentLanguage = LocalizationManager.shared.currentLanguage
        let suggestedLanguage = LocalizationManager.shared.getLanguageForCountry(country.countryCode)
        
        // Check if suggested language is different from current
        if suggestedLanguage != currentLanguage {
            print("🌐 Language difference detected:")
            print("   Current: \(currentLanguage)")
            print("   Suggested for \(country.countryName): \(suggestedLanguage)")
            
            // Show language selection alert
            selectedCountryForAlert = country
            alertCurrentLanguage = getLanguageDisplayName(currentLanguage)
            alertSuggestedLanguage = getLanguageDisplayName(suggestedLanguage)
            showLanguageAlert = true
        } else {
            // Same language, update directly
            settingsManager.setSelectedCountry(country)
            dismissView()
        }
    }
    
    // MARK: - ✅ NEW: Handle Language Selection Result
    private func handleLanguageSelectionResult(_ selectedLanguageDisplayName: String, for country: CountryInfo) {
        // Always update the country first
        settingsManager.setSelectedCountry(country)
        
        let currentLanguage = LocalizationManager.shared.currentLanguage
        let selectedLanguageCode = getLanguageCode(for: selectedLanguageDisplayName)
        
        // If user selected a different language, update it
        if let newLanguageCode = selectedLanguageCode, newLanguageCode != currentLanguage {
            print("🔄 Language change requested: \(currentLanguage) → \(newLanguageCode)")
            
            // Update language
            LocalizationManager.shared.currentLanguage = newLanguageCode
            
            // Show reload notification and hot reload UI
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                hotReloadApp {
                    dismissView()
                }
            }
        } else {
            print("🌐 Staying in current language: \(currentLanguage)")
            dismissView()
        }
    }
    
    // MARK: - ✅ NEW: Hot Reload App
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
    
    // MARK: - ✅ NEW: Set Default Country Selection
    private func setDefaultCountrySelection() {
        if let defaultCountry = countryManager.countries.first(where: { $0.countryCode.lowercased() == "in" }) {
            settingsManager.setSelectedCountry(defaultCountry)
        }
    }
    
    // MARK: - ✅ NEW: Dismiss View Helper
    private func dismissView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    // MARK: - ✅ NEW: Helper methods for language display names
    private func getLanguageDisplayName(_ code: String) -> String {
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
        case "zh", "zh-Hans": return "中文"
        case "th": return "ไทย"
        case "tr": return "Türkçe"
        case "vi": return "Tiếng Việt"
        case "id": return "Bahasa Indonesia"
        case "ms": return "Bahasa Melayu"
        case "nl": return "Nederlands"
        case "sv": return "Svenska"
        case "da": return "Dansk"
        case "no", "nb": return "Norsk"
        case "fi": return "Suomi"
        case "pl": return "Polski"
        case "cs": return "Čeština"
        case "hu": return "Magyar"
        case "ro": return "Română"
        case "bg": return "Български"
        case "hr": return "Hrvatski"
        case "sk": return "Slovenčina"
        case "sl": return "Slovenščina"
        case "et": return "Eesti"
        case "lv": return "Latviešu"
        case "lt": return "Lietuvių"
        case "el": return "Ελληνικά"
        case "he": return "עברית"
        case "uk": return "Українська"
        case "ca": return "Català"
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
        case "Български": return "bg"
        case "Hrvatski": return "hr"
        case "Slovenčina": return "sk"
        case "Slovenščina": return "sl"
        case "Eesti": return "et"
        case "Latviešu": return "lv"
        case "Lietuvių": return "lt"
        case "Ελληνικά": return "el"
        case "עברית": return "he"
        case "Українська": return "uk"
        case "Català": return "ca"
        default: return nil
        }
    }
}

#Preview {
    Country()
}
