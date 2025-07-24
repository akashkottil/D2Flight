import Foundation

// MARK: - Currency Model
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
    
    // Display name for the currency
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
        case "BGN": return "Bulgarian Lev"
        case "HRK": return "Croatian Kuna"
        case "UAH": return "Ukrainian Hryvnia"
        case "LYD": return "Libyan Dinar"
        case "DKK": return "Danish Krone"
        case "ISK": return "Icelandic Krona"
        case "AFN": return "Afghan Afghani"
        case "ALL": return "Albanian Lek"
        case "AMD": return "Armenian Dram"
        case "ANG": return "Netherlands Antillean Guilder"
        case "AOA": return "Angolan Kwanza"
        case "ARS": return "Argentine Peso"
        case "AWG": return "Aruban Florin"
        case "AZN": return "Azerbaijani Manat"
        case "BAM": return "Bosnia-Herzegovina Convertible Mark"
        case "BBD": return "Barbadian Dollar"
        case "BDT": return "Bangladeshi Taka"
        case "BIF": return "Burundian Franc"
        case "BMD": return "Bermudan Dollar"
        case "BND": return "Brunei Dollar"
        case "BOB": return "Bolivian Boliviano"
        case "BSD": return "Bahamian Dollar"
        case "BTN": return "Bhutanese Ngultrum"
        case "BWP": return "Botswanan Pula"
        case "BYN": return "Belarusian Ruble"
        case "BZD": return "Belize Dollar"
        case "CDF": return "Congolese Franc"
        case "CRC": return "Costa Rican Colón"
        case "CUC": return "Cuban Convertible Peso"
        case "CUP": return "Cuban Peso"
        case "CVE": return "Cape Verdean Escudo"
        case "DJF": return "Djiboutian Franc"
        case "DOP": return "Dominican Peso"
        case "ERN": return "Eritrean Nakfa"
        case "ETB": return "Ethiopian Birr"
        case "FJD": return "Fijian Dollar"
        case "FKP": return "Falkland Islands Pound"
        case "GEL": return "Georgian Lari"
        case "GHS": return "Ghanaian Cedi"
        case "GIP": return "Gibraltar Pound"
        case "GMD": return "Gambian Dalasi"
        case "GNF": return "Guinean Franc"
        case "GTQ": return "Guatemalan Quetzal"
        case "GYD": return "Guyanaese Dollar"
        case "HNL": return "Honduran Lempira"
        case "HTG": return "Haitian Gourde"
        case "IDR": return "Indonesian Rupiah"
        case "IRR": return "Iranian Rial"
        case "JMD": return "Jamaican Dollar"
        case "KES": return "Kenyan Shilling"
        case "KGS": return "Kyrgystani Som"
        case "KHR": return "Cambodian Riel"
        case "KMF": return "Comorian Franc"
        case "KPW": return "North Korean Won"
        case "KYD": return "Cayman Islands Dollar"
        case "KZT": return "Kazakhstani Tenge"
        case "LAK": return "Laotian Kip"
        case "LKR": return "Sri Lankan Rupee"
        case "LRD": return "Liberian Dollar"
        case "LSL": return "Lesotho Loti"
        case "MDL": return "Moldovan Leu"
        case "MGA": return "Malagasy Ariary"
        case "MKD": return "Macedonian Denar"
        case "MMK": return "Myanmar Kyat"
        case "MNT": return "Mongolian Tugrik"
        case "MOP": return "Macanese Pataca"
        case "MRU": return "Mauritanian Ouguiya"
        case "MUR": return "Mauritian Rupee"
        case "MVR": return "Maldivian Rufiyaa"
        case "MWK": return "Malawian Kwacha"
        case "MZN": return "Mozambican Metical"
        case "NAD": return "Namibian Dollar"
        case "NGN": return "Nigerian Naira"
        case "NIO": return "Nicaraguan Córdoba"
        case "NPR": return "Nepalese Rupee"
        case "PAB": return "Panamanian Balboa"
        case "PGK": return "Papua New Guinean Kina"
        case "PYG": return "Paraguayan Guarani"
        case "RSD": return "Serbian Dinar"
        case "RWF": return "Rwandan Franc"
        case "SBD": return "Solomon Islands Dollar"
        case "SCR": return "Seychellois Rupee"
        case "SDG": return "Sudanese Pound"
        case "SHP": return "Saint Helena Pound"
        case "SLE": return "Sierra Leonean Leone"
        case "SLL": return "Sierra Leonean Leone (Old)"
        case "SOS": return "Somali Shilling"
        case "SRD": return "Surinamese Dollar"
        case "SSP": return "South Sudanese Pound"
        case "STN": return "São Tomé and Príncipe Dobra"
        case "SVC": return "Salvadoran Colón"
        case "SYP": return "Syrian Pound"
        case "SZL": return "Swazi Lilangeni"
        case "TJS": return "Tajikistani Somoni"
        case "TMT": return "Turkmenistani Manat"
        case "TOP": return "Tongan Pa'anga"
        case "TTD": return "Trinidad and Tobago Dollar"
        case "TWD": return "Taiwan New Dollar"
        case "TZS": return "Tanzanian Shilling"
        case "UGX": return "Ugandan Shilling"
        case "UYU": return "Uruguayan Peso"
        case "UZS": return "Uzbekistan Som"
        case "VES": return "Venezuelan Bolívar"
        case "VND": return "Vietnamese Dong"
        case "VUV": return "Vanuatu Vatu"
        case "WST": return "Samoan Tala"
        case "XAF": return "CFA Franc BEAC"
        case "XCD": return "East Caribbean Dollar"
        case "XOF": return "CFA Franc BCEAO"
        case "XPF": return "CFP Franc"
        case "YER": return "Yemeni Rial"
        case "ZMW": return "Zambian Kwacha"
        case "ZWL": return "Zimbabwean Dollar"
        default: return code // Fallback to currency code
        }
    }
}

// MARK: - Currency Manager
class CurrencyManager: ObservableObject {
    @Published var currencies: [CurrencyInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    static let shared = CurrencyManager()
    
    private init() {
        loadCurrencies()
    }
    
    func loadCurrencies() {
        isLoading = true
        errorMessage = nil
        
        guard let url = Bundle.main.url(forResource: "currencyInfo", withExtension: "json") else {
            errorMessage = "Currency data file not found"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decodedCurrencies = try JSONDecoder().decode([CurrencyInfo].self, from: data)
            
            DispatchQueue.main.async {
                self.currencies = decodedCurrencies.sorted { $0.displayName < $1.displayName }
                self.isLoading = false
                print("📋 Loaded \(self.currencies.count) currencies")
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load currencies: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Failed to load currencies: \(error)")
            }
        }
    }
    
    func searchCurrencies(query: String) -> [CurrencyInfo] {
        guard !query.isEmpty else { return currencies }
        
        let lowercasedQuery = query.lowercased()
        return currencies.filter { currency in
            currency.code.lowercased().contains(lowercasedQuery) ||
            currency.displayName.lowercased().contains(lowercasedQuery) ||
            currency.symbol.lowercased().contains(lowercasedQuery)
        }
    }
}
