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
        
        @Published var deeplink: String? = nil
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
    
    func searchHotels() {
        guard !cityCode.isEmpty else {
            showError("Please select hotel location.")
            return
        }
        
        // Validate dates
        guard checkinDate < checkoutDate else {
            showError("Check-out date must be after check-in date.")
            return
        }
        
        startSearch()
    }
    
    private func startSearch() {
        isLoading = true
        errorMessage = nil
        deeplink = nil
        hasTimedOut = false
        
        startTimeoutTimer()
        
        let apiDateFormatter = DateFormatter()
        apiDateFormatter.dateFormat = "yyyy-MM-dd"
        
        let checkinString = apiDateFormatter.string(from: checkinDate)
        let checkoutString = apiDateFormatter.string(from: checkoutDate)
        
        print("🏨 Creating HotelRequest with parameters:")
        print("   ✅ City Name: '\(cityName)'")        // "Malacca"
        print("   ✅ Country Name: '\(countryName)'")  // "Malaysia"
        print("   Check-in: \(checkinString)")
        print("   Check-out: \(checkoutString)")
        
        let request = HotelRequest(
            cityName: cityName,
            countryName: countryName,       // ✅ Move before checkin
            checkin: checkinString,
            checkout: checkoutString,
            rooms: rooms,
            adults: adults,
            children: children > 0 ? children : nil
        )
        
        HotelApi.shared.searchHotel(request: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleSearchResult(result)
            }
        }
    }
    
    private func handleSearchResult(_ result: Result<HotelResponse, Error>) {
        // Cancel timeout timer since we got a response
        cancelTimeoutTimer()
        
        isLoading = false
        
        switch result {
        case .success(let response):
            // Validate the deeplink
            guard SearchValidationHelper.validateDeeplink(response.deeplink) else {
                print("❌ Invalid deeplink received: \(response.deeplink)")
                showDeeplinkError()
                return
            }
            
            self.deeplink = response.deeplink
            self.errorMessage = nil
            
            print("✅ Hotel search successful!")
            print("   Deeplink: \(response.deeplink)")
            
            // Track successful hotel search
            UserManager.shared.trackHotelSearch()
            
        case .failure(let error):
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
    
    // MARK: - Timeout Management
    
    private func startTimeoutTimer() {
        cancelTimeoutTimer() // Cancel any existing timer
        
        searchTimeout = Timer.scheduledTimer(withTimeInterval: searchTimeoutDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleTimeout()
            }
        }
    }
    
    private func cancelTimeoutTimer() {
        searchTimeout?.invalidate()
        searchTimeout = nil
    }
    
    private func handleTimeout() {
        print("⏰ Hotel search timed out after \(searchTimeoutDuration) seconds")
        
        hasTimedOut = true
        isLoading = false
        showTimeoutError()
    }
    
    // MARK: - Helper Methods (unchanged)
    
    func getSearchParameters() -> HotelSearchParameters {
        return HotelSearchParameters(
            cityCode: cityCode,
            cityName: cityName,
            checkinDate: checkinDate,
            checkoutDate: checkoutDate,
            rooms: rooms,
            adults: adults,
            children: children
        )
    }
    
    func validateSearchParameters() -> Bool {
        guard !cityCode.isEmpty else {
            showError("Please select a hotel location")
            return false
        }
        
        guard checkinDate < checkoutDate else {
            showError("Check-out date must be after check-in date")
            return false
        }
        
        guard rooms > 0 else {
            showError("Please select at least 1 room")
            return false
        }
        
        guard adults > 0 else {
            showError("Please select at least 1 adult")
            return false
        }
        
        return true
    }
    
    func getNumberOfNights() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: checkinDate, to: checkoutDate)
        return max(1, components.day ?? 1)
    }
    
    func getFormattedDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        return "\(formatter.string(from: checkinDate)) - \(formatter.string(from: checkoutDate))"
    }
    
    func getFormattedGuestInfo() -> String {
        let totalGuests = adults + children
        let guestsText = "\(totalGuests) Guest\(totalGuests > 1 ? "s" : "")"
        let roomsText = "\(rooms) Room\(rooms > 1 ? "s" : "")"
        return "\(guestsText), \(roomsText)"
    }
    
    
    private func extractCountryNameFromCityName(_ cityName: String) -> String {
        // If cityName is just "Dubai", we need to get country from the full display name
        // This should be handled by passing it from HotelView instead
        return "United Arab Emirates" // Placeholder - should come from HotelView
    }
    
    // MARK: - Cleanup
    
    deinit {
        cancelTimeoutTimer()
    }
}
