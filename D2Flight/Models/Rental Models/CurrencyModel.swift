import Foundation

// MARK: - Currency Model (Updated with Codable)
struct CurrencyInfo: Codable, Identifiable {
    var id = UUID()
    let code: String
    let symbol: String
    let thousands_separator: String
    let decimal_separator: String
    let symbol_on_left: Bool
    let space_between_amount_and_symbol: Bool
    let decimal_digits: Int
    
    enum CodingKeys: String, CodingKey {
        case code, symbol, thousands_separator, decimal_separator, symbol_on_left, space_between_amount_and_symbol, decimal_digits
    }
    
    // Custom init to ensure UUID is generated
    init(code: String, symbol: String, thousands_separator: String, decimal_separator: String, symbol_on_left: Bool, space_between_amount_and_symbol: Bool, decimal_digits: Int) {
        self.id = UUID()
        self.code = code
        self.symbol = symbol
        self.thousands_separator = thousands_separator
        self.decimal_separator = decimal_separator
        self.symbol_on_left = symbol_on_left
        self.space_between_amount_and_symbol = space_between_amount_and_symbol
        self.decimal_digits = decimal_digits
    }
    
    // Custom decoder to generate UUID if not present
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.code = try container.decode(String.self, forKey: .code)
        self.symbol = try container.decode(String.self, forKey: .symbol)
        self.thousands_separator = try container.decode(String.self, forKey: .thousands_separator)
        self.decimal_separator = try container.decode(String.self, forKey: .decimal_separator)
        self.symbol_on_left = try container.decode(Bool.self, forKey: .symbol_on_left)
        self.space_between_amount_and_symbol = try container.decode(Bool.self, forKey: .space_between_amount_and_symbol)
        self.decimal_digits = try container.decode(Int.self, forKey: .decimal_digits)
    }
    
    // Custom encoder to exclude UUID from encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(symbol, forKey: .symbol)
        try container.encode(thousands_separator, forKey: .thousands_separator)
        try container.encode(decimal_separator, forKey: .decimal_separator)
        try container.encode(symbol_on_left, forKey: .symbol_on_left)
        try container.encode(space_between_amount_and_symbol, forKey: .space_between_amount_and_symbol)
        try container.encode(decimal_digits, forKey: .decimal_digits)
    }
    
    // Display name for the currency (keeping the original large switch statement)
    var displayName: String {
        switch code {
        case "USD": return "US Dollar"
        case "EUR": return "Euro"
        case "GBP": return "British Pound"
        case "JPY": return "Japanese Yen"
        case "CAD": return "Canadian Dollar"
        case "AUD": return "Australian Dollar"
        case "CHF": return "Swiss Franc"
        case "CNY": return "Chinese Yuan"
        case "SEK": return "Swedish Krona"
        case "NZD": return "New Zealand Dollar"
        case "MXN": return "Mexican Peso"
        case "SGD": return "Singapore Dollar"
        case "HKD": return "Hong Kong Dollar"
        case "NOK": return "Norwegian Krone"
        case "TRY": return "Turkish Lira"
        case "RUB": return "Russian Ruble"
        case "INR": return "Indian Rupee"
        case "BRL": return "Brazilian Real"
        case "ZAR": return "South African Rand"
        case "KRW": return "South Korean Won"
        case "THB": return "Thai Baht"
        case "PLN": return "Polish Zloty"
        case "CZK": return "Czech Koruna"
        case "HUF": return "Hungarian Forint"
        case "ILS": return "Israeli Shekel"
        case "CLP": return "Chilean Peso"
        case "PHP": return "Philippine Peso"
        case "AED": return "UAE Dirham"
        case "COP": return "Colombian Peso"
        case "SAR": return "Saudi Riyal"
        case "MYR": return "Malaysian Ringgit"
        case "RON": return "Romanian Leu"
        case "PEN": return "Peruvian Sol"
        case "EGP": return "Egyptian Pound"
        case "QAR": return "Qatari Riyal"
        case "KWD": return "Kuwaiti Dinar"
        case "BHD": return "Bahraini Dinar"
        case "OMR": return "Omani Rial"
        case "JOD": return "Jordanian Dinar"
        case "LBP": return "Lebanese Pound"
        case "TND": return "Tunisian Dinar"
        case "DZD": return "Algerian Dinar"
        case "MAD": return "Moroccan Dirham"
        case "PKR": return "Pakistani Rupee"
        default: return code // Fallback to currency code
        }
    }
}
