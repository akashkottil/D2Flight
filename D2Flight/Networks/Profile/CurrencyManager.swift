import Foundation

// MARK: - Currency Manager
class CurrencyManager: ObservableObject {
    @Published var currencies: [CurrencyInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedCurrency: CurrencyInfo? {
        didSet {
            if let selected = selectedCurrency {
                print("💰 Currency selected: \(selected.displayName) (\(selected.code))")
                saveSelectedCurrency(selected)
            }
        }
    }
    
    static let shared = CurrencyManager()
    
    private let currencyApi = CurrencyApi.shared
    private let selectedCurrencyKey = "selectedCurrency"
    
    private init() {
        loadSelectedCurrency()
        loadCurrencies()
    }
    
    func loadCurrencies() {
        isLoading = true
        errorMessage = nil
        
        currencyApi.fetchAllCurrencies { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let apiCurrencies):
                    // Convert API models to existing CurrencyInfo models
                    let currencyInfos = apiCurrencies.map { $0.toCurrencyInfo() }
                    self?.currencies = currencyInfos.sorted { $0.displayName < $1.displayName }
                    self?.isLoading = false
                    self?.errorMessage = nil
                    print("💰 Loaded \(currencyInfos.count) currencies from API")
                    
                    // 🆕 POST NOTIFICATION THAT CURRENCIES ARE LOADED
                    NotificationCenter.default.post(name: NSNotification.Name("CurrenciesDidLoad"), object: nil)
                    
                    // Set default selection if none exists (remove this if using SettingsManager)
                    // if self?.selectedCurrency == nil {
                    //     self?.setDefaultCurrency()
                    // }
                    
                case .failure(let error):
                    self?.errorMessage = "Failed to load currencies: \(error.localizedDescription)"
                    self?.isLoading = false
                    print("❌ Failed to load currencies from API: \(error)")
                }
            }
        }
    }
    
    private func setDefaultCurrency() {
        // Try to set USD as default, fallback to INR, then first available
        if let defaultCurrency = currencies.first(where: { $0.code == "USD" }) {
            selectedCurrency = defaultCurrency
        } else if let inrCurrency = currencies.first(where: { $0.code == "INR" }) {
            selectedCurrency = inrCurrency
        } else if let firstCurrency = currencies.first {
            selectedCurrency = firstCurrency
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
    
    // Get currency by code
    func getCurrency(by code: String) -> CurrencyInfo? {
        return currencies.first { $0.code.lowercased() == code.lowercased() }
    }
    
    // Get popular currencies
    func getPopularCurrencies() -> [CurrencyInfo] {
        let popularCodes = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "KRW"]
        return popularCodes.compactMap { code in
            currencies.first { $0.code == code }
        }
    }
    
    // MARK: - Persistence
    private func saveSelectedCurrency(_ currency: CurrencyInfo) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(currency)
            UserDefaults.standard.set(data, forKey: selectedCurrencyKey)
            print("💾 Saved selected currency: \(currency.displayName)")
        } catch {
            print("❌ Failed to save selected currency: \(error)")
        }
    }
    
    private func loadSelectedCurrency() {
        guard let data = UserDefaults.standard.data(forKey: selectedCurrencyKey) else {
            print("📱 No saved currency found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            selectedCurrency = try decoder.decode(CurrencyInfo.self, from: data)
            if let currency = selectedCurrency {
                print("📱 Loaded saved currency: \(currency.displayName)")
            }
        } catch {
            print("❌ Failed to load saved currency: \(error)")
        }
    }
    
    // Public method to update selected currency
    func selectCurrency(_ currency: CurrencyInfo) {
        selectedCurrency = currency
    }
    
    // Clear selection
    func clearSelection() {
        selectedCurrency = nil
        UserDefaults.standard.removeObject(forKey: selectedCurrencyKey)
        print("🗑️ Cleared currency selection")
    }
}
