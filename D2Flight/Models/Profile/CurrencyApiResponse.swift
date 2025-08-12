import Foundation

// MARK: - Currency API Response Models
struct CurrencyApiResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [CurrencyApiModel]
}

struct CurrencyApiModel: Codable {
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

// MARK: - Extension to convert API model to existing CurrencyInfo model
extension CurrencyApiModel {
    func toCurrencyInfo() -> CurrencyInfo {
        return CurrencyInfo(
            code: self.code,
            symbol: self.symbol,
            thousands_separator: self.thousandsSeparator,
            decimal_separator: self.decimalSeparator,
            symbol_on_left: self.symbolOnLeft,
            space_between_amount_and_symbol: self.spaceBetweenAmountAndSymbol,
            decimal_digits: self.decimalDigits
        )
    }
}
