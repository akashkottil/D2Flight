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
                    settingsManager.handleLanguageSelection(selectedLanguage, for: country) {
                        // Dismiss the view after selection
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        )
        .onAppear {
            // Set default selection if none exists
            if settingsManager.selectedCountry == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let defaultCountry = countryManager.countries.first(where: { $0.countryCode.lowercased() == "in" }) {
                        settingsManager.setSelectedCountryDirectly(defaultCountry)
                    }
                }
            }
        }
    }
    
    // MARK: - Handle Country Selection
    private func handleCountrySelection(_ country: CountryInfo) {
        print("🌍 Country tapped: \(country.countryName) (\(country.countryCode))")
        
        settingsManager.setSelectedCountryWithLanguageCheck(country) { countryName, currentLang, suggestedLang in
            // Show language alert
            selectedCountryForAlert = country
            alertCurrentLanguage = currentLang
            alertSuggestedLanguage = suggestedLang
            showLanguageAlert = true
        } onDirectUpdate: {
            // No language change needed, dismiss immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    Country()
}
