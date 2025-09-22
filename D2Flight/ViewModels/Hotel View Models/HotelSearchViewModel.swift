import Foundation
import Combine

class HotelSearchViewModel: ObservableObject {
    @Published var cityCode: String = ""
    @Published var cityName: String = "" {
        didSet {
            // ✅ Reset state when city name changes
            if oldValue != cityName && !oldValue.isEmpty {
                print("🔄 City changed from '\(oldValue)' to '\(cityName)' - resetting state")
                resetSearchState()
            }
        }
    }
    @Published var countryName: String = "" {
        didSet {
            // ✅ Reset state when country changes
            if oldValue != countryName && !oldValue.isEmpty {
                print("🔄 Country changed from '\(oldValue)' to '\(countryName)' - resetting state")
                resetSearchState()
            }
        }
    }
    @Published var checkinDate: Date = Date()
    @Published var checkoutDate: Date = {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }()
    @Published var rooms: Int = 1
    @Published var adults: Int = 2
    @Published var children: Int = 0
    
    @Published var deeplink: String? = nil {
        didSet {
            print("🔔 HotelSearchViewModel.deeplink changed:")
            print("   From: '\(oldValue ?? "nil")'")
            print("   To: '\(deeplink ?? "nil")'")
            
            if let newDeeplink = deeplink, !newDeeplink.isEmpty {
                print("✅ Valid deeplink set - should trigger UI update")
            } else {
                print("❌ Deeplink set to nil/empty")
            }
        }
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasTimedOut: Bool = false
    
    private var searchTimeout: Timer?
    private let searchTimeoutDuration: TimeInterval = 30.0
    private var cancellables = Set<AnyCancellable>()
    
    
    private func resetSearchState() {
        deeplink = nil
        isLoading = false
        errorMessage = nil
        hasTimedOut = false
        
        // Cancel any ongoing search
        searchTimeout?.invalidate()
        searchTimeout = nil
        
        print("🔄 Search state reset - ready for new location search")
    }
    
    @MainActor
    func searchHotels() {
        // Flip loading immediately so UI can react
        isLoading = true
        errorMessage = nil
        deeplink = nil
        hasTimedOut = false

        // Validate quickly; if invalid, turn loading off and exit
        guard !cityCode.isEmpty else {
            showError("Please select hotel location.")
            isLoading = false
            return
        }
        guard !cityName.isEmpty, !countryName.isEmpty else {
            showError("Missing location information. Please select a valid location.")
            isLoading = false
            return
        }
        guard checkinDate < checkoutDate else {
            showError("Check-out date must be after check-in date.")
            isLoading = false
            return
        }

        // Defer actual search to next runloop so the loader can render
        DispatchQueue.main.async {
            self.startSearch()
        }
    }

    
    private func startSearch() {
        // state already set in searchHotels()
        startTimeoutTimer()
        
        let checkinString  = Self.apiFormatter.string(from: checkinDate)
        let checkoutString = Self.apiFormatter.string(from: checkoutDate)
        
        let request = HotelRequest(
            cityName: cityName,
            countryName: countryName,
            checkin: checkinString,
            checkout: checkoutString,
            rooms: rooms,
            adults: adults,
            children: children > 0 ? children : nil
        )
        
        HotelApi.shared.searchHotel(request: request) { [weak self] result in
            guard let self else { return }
            self.handleSearchResult(result) // already on main if your API returns on main; otherwise wrap in DispatchQueue.main.async
        }
    }

    // Cached date formatter
    private static let apiFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    
    private func handleSearchResult(_ result: Result<HotelResponse, Error>) {
        print("📋 HotelSearchViewModel.handleSearchResult() called")
        
        // Cancel timeout timer since we got a response
        cancelTimeoutTimer()
        
        print("📊 Setting isLoading to false...")
        isLoading = false
        print("   isLoading is now: \(isLoading)")
        
        switch result {
        case .success(let response):
            print("✅ API Success - received response:")
            print("   deeplink: '\(response.deeplink)'")
            print("   status: '\(response.status)'")
            print("   message: '\(response.message)'")
            
            // Validate the deeplink
            print("🔍 Validating deeplink...")
            let isValid = SearchValidationHelper.validateDeeplink(response.deeplink)
            print("   Validation result: \(isValid)")
            
            guard isValid else {
                print("❌ Invalid deeplink received: \(response.deeplink)")
                showDeeplinkError()
                return
            }
            
            print("🔗 About to set deeplink property...")
            print("   Current deeplink value: '\(self.deeplink ?? "nil")'")
            
            // CRITICAL: Ensure this is on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    print("❌ Self is nil in DispatchQueue.main.async")
                    return
                }
                
                print("🔗 Setting deeplink on main thread...")
                self.deeplink = response.deeplink
                self.errorMessage = nil
                
                print("📊 Final ViewModel state after setting deeplink:")
                print("   deeplink: '\(self.deeplink ?? "nil")'")
                print("   errorMessage: '\(self.errorMessage ?? "nil")'")
                print("   isLoading: \(self.isLoading)")
            }
            
            // Track successful hotel search
            UserManager.shared.trackHotelSearch()
            
        case .failure(let error):
            print("❌ API Failure: \(error.localizedDescription)")
            handleSearchError(error)
        }
    }
    
    private func handleSearchError(_ error: Error) {
        print("❌ Hotel search failed: \(error.localizedDescription)")
        
        self.deeplink = nil
        
        // Show appropriate warning based on error type
        if let hotelError = error as? HotelAPIError {
            handleHotelAPIError(hotelError)
        } else if error.isTimeoutError {
            showTimeoutError()
        } else if error.isActualNetworkError {
            showNetworkError()
        } else {
            // Check if it's a hostname error (server configuration issue)
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("hostname could not be found") ||
                errorMessage.contains("could not connect to the server") {
                showServerError()
            } else {
                showGenericError(error)
            }
        }
    }
    
    private func handleHotelAPIError(_ error: HotelAPIError) {
        switch error {
        case .timeout:
            showTimeoutError()
        case .networkError:
            showNetworkError()
        case .invalidDeeplink:
            showDeeplinkError()
        case .searchFailed:
            showSearchFailedError()
        case .clientError, .serverError, .apiError:
            showGenericError(error)
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimeoutTimer() {
        print("⏰ Starting timeout timer (\(searchTimeoutDuration) seconds)")
        searchTimeout?.invalidate()
        searchTimeout = Timer.scheduledTimer(withTimeInterval: searchTimeoutDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleTimeout()
            }
        }
    }
    
    private func cancelTimeoutTimer() {
        print("⏰ Canceling timeout timer")
        searchTimeout?.invalidate()
        searchTimeout = nil
    }
    
    private func handleTimeout() {
        print("⏰ Hotel search timeout occurred")
        hasTimedOut = true
        isLoading = false
        showTimeoutError()
    }
    
    // MARK: - Error Display Methods
    
    private func showError(_ message: String) {
        errorMessage = message
        // Don't show warning for simple validation errors, just update errorMessage
    }
    
    private func showTimeoutError() {
        errorMessage = "Hotel search timed out. Please try again."
        WarningManager.shared.showTimeoutError()
    }
    
    private func showNetworkError() {
        errorMessage = "Network connection issue. Please check your internet and try again."
        WarningManager.shared.showWarning(type: .noInternet)
    }
    
    private func showDeeplinkError() {
        errorMessage = "Unable to load hotel search results. Please try again."
        WarningManager.shared.showDeeplinkError(for: .hotel)
    }
    
    private func showSearchFailedError() {
        errorMessage = "Hotel search failed. Please try different dates or location."
        WarningManager.shared.showDeeplinkError(for: .hotel)
    }
    
    private func showGenericError(_ error: Error) {
        errorMessage = error.localizedDescription
        WarningManager.shared.showDeeplinkError(for: .hotel, error: error)
    }
    
    private func showServerError() {
        errorMessage = "Hotel service is temporarily unavailable. Please try again later."
        WarningManager.shared.showDeeplinkError(for: .hotel)
    }
    
    // MARK: - Debug Methods
    
    func testSetDeeplink() {
        print("🧪 Testing deeplink assignment...")
        DispatchQueue.main.async { [weak self] in
            self?.deeplink = "https://www.google.com"
            print("✅ Test deeplink set")
        }
    }
    
    func printDebugInfo() {
        print("🔍 HotelSearchViewModel Debug Info:")
        print("   cityCode: '\(cityCode)'")
        print("   cityName: '\(cityName)'")
        print("   countryName: '\(countryName)'")
        print("   checkinDate: \(checkinDate)")
        print("   checkoutDate: \(checkoutDate)")
        print("   rooms: \(rooms)")
        print("   adults: \(adults)")
        print("   children: \(children)")
        print("   deeplink: '\(deeplink ?? "nil")'")
        print("   isLoading: \(isLoading)")
        print("   errorMessage: '\(errorMessage ?? "nil")'")
        print("   hasTimedOut: \(hasTimedOut)")
    }
}
