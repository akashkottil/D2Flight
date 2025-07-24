import Foundation

// MARK: - Country Model
struct CountryInfo: Codable, Identifiable {
    var id = UUID()
    let countryName: String
    let countryCode: String
    let fullDomainName: String
    let currencyCode: String
    let supportedLanguages: [String]
    let defaultDomain: String?
    let currency: String
    let abbreviation: String
    let symbol: String
    
    enum CodingKeys: String, CodingKey {
        case countryName, countryCode, fullDomainName, currencyCode, supportedLanguages, defaultDomain, currency, abbreviation, symbol
    }
    
    // Display name for UI (using countryName directly)
    var displayName: String {
        return countryName
    }
    
    // Formatted supported languages
    var formattedLanguages: String {
        return supportedLanguages.joined(separator: ", ")
    }
    
    // Currency display with symbol
    var currencyDisplay: String {
        return "\(currency) (\(abbreviation))"
    }
}

// MARK: - Country Manager
class CountryManager: ObservableObject {
    @Published var countries: [CountryInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    static let shared = CountryManager()
    
    private init() {
        loadCountries()
    }
    
    func loadCountries() {
        isLoading = true
        errorMessage = nil
        
        guard let url = Bundle.main.url(forResource: "kayak_countries", withExtension: "json") else {
            errorMessage = "Country data file not found"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decodedCountries = try JSONDecoder().decode([CountryInfo].self, from: data)
            
            DispatchQueue.main.async {
                self.countries = decodedCountries.sorted { $0.countryName < $1.countryName }
                self.isLoading = false
                print("🌍 Loaded \(self.countries.count) countries")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load countries: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Failed to load countries: \(error)")
            }
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
    
    // Get popular countries (you can customize this based on your needs)
    func getPopularCountries() -> [CountryInfo] {
        let popularCodes = ["us", "gb", "ca", "au", "de", "fr", "jp", "in", "br", "mx"]
        return popularCodes.compactMap { code in
            countries.first { $0.countryCode.lowercased() == code }
        }
    }
}
