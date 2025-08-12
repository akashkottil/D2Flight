import Foundation

// MARK: - Country Model (Updated with Codable)
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
    
    // Custom init to ensure UUID is generated
    init(countryName: String, countryCode: String, fullDomainName: String, currencyCode: String, supportedLanguages: [String], defaultDomain: String?, currency: String, abbreviation: String, symbol: String) {
        self.id = UUID()
        self.countryName = countryName
        self.countryCode = countryCode
        self.fullDomainName = fullDomainName
        self.currencyCode = currencyCode
        self.supportedLanguages = supportedLanguages
        self.defaultDomain = defaultDomain
        self.currency = currency
        self.abbreviation = abbreviation
        self.symbol = symbol
    }
    
    // Custom decoder to generate UUID if not present
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.countryName = try container.decode(String.self, forKey: .countryName)
        self.countryCode = try container.decode(String.self, forKey: .countryCode)
        self.fullDomainName = try container.decode(String.self, forKey: .fullDomainName)
        self.currencyCode = try container.decode(String.self, forKey: .currencyCode)
        self.supportedLanguages = try container.decode([String].self, forKey: .supportedLanguages)
        self.defaultDomain = try container.decodeIfPresent(String.self, forKey: .defaultDomain)
        self.currency = try container.decode(String.self, forKey: .currency)
        self.abbreviation = try container.decode(String.self, forKey: .abbreviation)
        self.symbol = try container.decode(String.self, forKey: .symbol)
    }
    
    // Custom encoder to exclude UUID from encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(countryName, forKey: .countryName)
        try container.encode(countryCode, forKey: .countryCode)
        try container.encode(fullDomainName, forKey: .fullDomainName)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(supportedLanguages, forKey: .supportedLanguages)
        try container.encodeIfPresent(defaultDomain, forKey: .defaultDomain)
        try container.encode(currency, forKey: .currency)
        try container.encode(abbreviation, forKey: .abbreviation)
        try container.encode(symbol, forKey: .symbol)
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
