import Foundation

// MARK: - Country Manager
class CountryManager: ObservableObject {
    @Published var countries: [CountryInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedCountry: CountryInfo? {
        didSet {
            if let selected = selectedCountry {
                print("🌍 Country selected: \(selected.countryName) (\(selected.countryCode))")
                saveSelectedCountry(selected)
            }
        }
    }
    
    static let shared = CountryManager()
    
    private let countryApi = CountryApi.shared
    private let selectedCountryKey = "selectedCountry"
    
    private init() {
        loadSelectedCountry()
        loadCountries()
    }
    
    func loadCountries() {
        isLoading = true
        errorMessage = nil
        
        countryApi.fetchAllCountries { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let apiCountries):
                    // Convert API models to existing CountryInfo models
                    let countryInfos = apiCountries.map { $0.toCountryInfo() }
                    self?.countries = countryInfos.sorted { $0.countryName < $1.countryName }
                    self?.isLoading = false
                    self?.errorMessage = nil
                    print("🌍 Loaded \(countryInfos.count) countries from API")
                    
                    // 🆕 POST NOTIFICATION THAT COUNTRIES ARE LOADED
                    NotificationCenter.default.post(name: NSNotification.Name("CountriesDidLoad"), object: nil)
                    
                    // Set default selection if none exists (remove this if using SettingsManager)
                    // if self?.selectedCountry == nil {
                    //     self?.setDefaultCountry()
                    // }
                    
                case .failure(let error):
                    self?.errorMessage = "Failed to load countries: \(error.localizedDescription)"
                    self?.isLoading = false
                    print("❌ Failed to load countries from API: \(error)")
                }
            }
        }
    }
    
    private func setDefaultCountry() {
        // Try to set United States as default, fallback to India, then first available
        if let defaultCountry = countries.first(where: { $0.countryCode.lowercased() == "us" }) {
            selectedCountry = defaultCountry
        } else if let indiaCountry = countries.first(where: { $0.countryCode.lowercased() == "in" }) {
            selectedCountry = indiaCountry
        } else if let firstCountry = countries.first {
            selectedCountry = firstCountry
        }
    }
    
    func searchCountries(query: String) -> [CountryInfo] {
        guard !query.isEmpty else { return countries }
        
        let lowercasedQuery = query.lowercased()
        return countries.filter { country in
            country.countryName.lowercased().contains(lowercasedQuery) ||
            country.countryCode.lowercased().contains(lowercasedQuery) ||
            country.currency.lowercased().contains(lowercasedQuery) ||
            country.abbreviation.lowercased().contains(lowercasedQuery) ||
            country.supportedLanguages.joined(separator: " ").lowercased().contains(lowercasedQuery)
        }
    }
    
    // Get country by country code
    func getCountry(by countryCode: String) -> CountryInfo? {
        return countries.first { $0.countryCode.lowercased() == countryCode.lowercased() }
    }
    
    // Get countries by currency
    func getCountries(byCurrency currencyCode: String) -> [CountryInfo] {
        return countries.filter { $0.currencyCode.lowercased() == currencyCode.lowercased() }
    }
    
    // Get popular countries
    func getPopularCountries() -> [CountryInfo] {
        let popularCodes = ["us", "gb", "ca", "au", "de", "fr", "jp", "in", "br", "mx"]
        return popularCodes.compactMap { code in
            countries.first { $0.countryCode.lowercased() == code }
        }
    }
    
    // MARK: - Persistence
    private func saveSelectedCountry(_ country: CountryInfo) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(country)
            UserDefaults.standard.set(data, forKey: selectedCountryKey)
            print("💾 Saved selected country: \(country.countryName)")
        } catch {
            print("❌ Failed to save selected country: \(error)")
        }
    }
    
    private func loadSelectedCountry() {
        guard let data = UserDefaults.standard.data(forKey: selectedCountryKey) else {
            print("📱 No saved country found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            selectedCountry = try decoder.decode(CountryInfo.self, from: data)
            if let country = selectedCountry {
                print("📱 Loaded saved country: \(country.countryName)")
            }
        } catch {
            print("❌ Failed to load saved country: \(error)")
        }
    }
    
    // Public method to update selected country
    func selectCountry(_ country: CountryInfo) {
        selectedCountry = country
    }
    
    // Clear selection
    func clearSelection() {
        selectedCountry = nil
        UserDefaults.standard.removeObject(forKey: selectedCountryKey)
        print("🗑️ Cleared country selection")
    }
}
