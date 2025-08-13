import Foundation

// MARK: - Country API Response Models
struct CountryApiResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [CountryApiModel]
}

struct CountryApiModel: Codable {
    let name: String
    let code: String
    let currency: CountryCurrency
    let flag: String
    let domain: String
    let supportedLanguages: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case code
        case currency
        case flag
        case domain
        case supportedLanguages = "supported_languages"
    }
}

struct CountryCurrency: Codable {
    let code: String
    let symbol: String
    let thousandsSeparator: String
    let decimalSeparator: String
    let symbolOnLeft: Bool
    let spaceBetweenAmountAndSymbol: Bool
    let decimalDigits: Int
    
    enum CodingKeys: String, CodingKey {
        case code
        case symbol
        case thousandsSeparator = "thousands_separator"
        case decimalSeparator = "decimal_separator"
        case symbolOnLeft = "symbol_on_left"
        case spaceBetweenAmountAndSymbol = "space_between_amount_and_symbol"
        case decimalDigits = "decimal_digits"
    }
}

// MARK: - Extension to convert API model to existing CountryInfo model
extension CountryApiModel {
    func toCountryInfo() -> CountryInfo {
        return CountryInfo(
            countryName: self.name,
            countryCode: self.code,
            fullDomainName: self.domain,
            currencyCode: self.currency.code,
            supportedLanguages: self.supportedLanguages ?? [],
            defaultDomain: self.domain,
            currency: getCurrencyName(for: self.currency.code),
            abbreviation: self.currency.code,
            symbol: self.currency.symbol
        )
    }
    
    private func getCurrencyName(for code: String) -> String {
        switch code {
        case "USD": return "United States Dollar"
        case "EUR": return "Euro Member Countries"
        case "GBP": return "United Kingdom Pound"
        case "JPY": return "Japan Yen"
        case "CAD": return "Canada Dollar"
        case "AUD": return "Australia Dollar"
        case "CHF": return "Switzerland Franc"
        case "CNY": return "China Yuan Renminbi"
        case "INR": return "India Rupee"
        case "AED": return "Dirham"
        case "AFN": return "Afghan Afghani"
        case "ALL": return "Albanian Lek"
        case "AMD": return "Armenian Dram"
        case "ANG": return "Netherlands Antillean Guilder"
        case "AOA": return "Angolan Kwanza"
        default: return "\(code) Currency"
        }
    }
}
