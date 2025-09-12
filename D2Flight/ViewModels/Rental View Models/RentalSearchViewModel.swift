import Foundation
import Combine

class RentalSearchViewModel: ObservableObject {
    @Published var pickUpIATACode: String = ""
    @Published var dropOffIATACode: String = ""
    @Published var pickUpDate: Date = Date()
    @Published var pickUpTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    @Published var dropOffDate: Date = {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    }()
    @Published var dropOffTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    @Published var isSameDropOff: Bool = true
    
    @Published var deeplink: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // NEW: Add timeout tracking
    @Published var hasTimedOut: Bool = false
    private var searchTimeout: Timer?
    private let searchTimeoutDuration: TimeInterval = 30.0 // 30 seconds timeout
    
    private var cancellables = Set<AnyCancellable>()
    
    func searchRentals() {
        isLoading = true
        guard !pickUpIATACode.isEmpty else {
            showError("Please select pick-up location.")
            return
        }
        
        // For different drop-off, ensure drop-off location is selected
        if !isSameDropOff && dropOffIATACode.isEmpty {
            showError("Please select drop-off location.")
            return
        }
        
        // ✅ NEW: Validate time difference before making API call
        let combinedPickUpDateTime = combineDateAndTime(date: pickUpDate, time: pickUpTime)
        let combinedDropOffDateTime = combineDateAndTime(date: dropOffDate, time: dropOffTime)
        
        let minimumRentalDuration: TimeInterval = 3600 // 1 hour
        let timeDifference = combinedDropOffDateTime.timeIntervalSince(combinedPickUpDateTime)
        
        if timeDifference < minimumRentalDuration {
            showError("Drop-off must be at least one hour after pick-up. Please adjust the dates and/or times for your search.")
            return
        }
        
        startSearch()
    }
    
    private func startSearch() {
        isLoading = true
        errorMessage = nil
        deeplink = nil
        hasTimedOut = false
        
        // Start timeout timer
        startTimeoutTimer()
        
        let combinedPickUpDateTime = combineDateAndTime(date: pickUpDate, time: pickUpTime)
        let combinedDropOffDateTime = combineDateAndTime(date: dropOffDate, time: dropOffTime)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        
        let pickUpDateString = dateFormatter.string(from: combinedPickUpDateTime)
        let dropOffDateString = dateFormatter.string(from: combinedDropOffDateTime)
        
        // Use dynamic parameters (country, currency, language, and user ID will be auto-selected)
        let request = RentalRequest(
            pickUp: pickUpIATACode,
            dropOff: isSameDropOff ? nil : dropOffIATACode,
            pickUpDate: pickUpDateString,
            dropOffDate: dropOffDateString
        )
        
        print("🚗 Starting rental search with request:")
        print("   Same Drop-off: \(isSameDropOff)")
        print("   Pick-up: \(pickUpIATACode)")
        if !isSameDropOff {
            print("   Drop-off: \(dropOffIATACode)")
        }
        print("   Pick-up Date/Time: \(pickUpDateString)")
        print("   Drop-off Date/Time: \(dropOffDateString)")
        print("   🔧 Using dynamic country: \(request.countryCode)")
        print("   🔧 Using dynamic currency: \(request.currencyCode)")
        print("   🔧 Using dynamic language: \(request.languageCode)")
        print("   🔧 Using dynamic user ID: \(request.userId)")
        
        RentalApi.shared.searchRental(request: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleSearchResult(result)
            }
        }
    }
    
    private func handleSearchResult(_ result: Result<RentalResponse, Error>) {
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
            
            print("✅ Rental search successful!")
            print("   Deeplink: \(response.deeplink)")
            
            // Track successful rental search
            UserManager.shared.trackRentalSearch()
            
        case .failure(let error):
            handleSearchError(error)
        }
    }
    
    private func handleSearchError(_ error: Error) {
        print("❌ Rental search failed: \(error.localizedDescription)")
        
        self.deeplink = nil
        
        // Show appropriate warning based on error type
        if let rentalError = error as? RentalAPIError {
            handleRentalAPIError(rentalError)
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
    
    private func handleRentalAPIError(_ error: RentalAPIError) {
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
        errorMessage = "Car rental search timed out. Please try again."
        WarningManager.shared.showTimeoutError()
    }
    
    private func showNetworkError() {
        errorMessage = "Network connection issue. Please check your internet and try again."
        WarningManager.shared.showWarning(type: .noInternet)
    }
    
    private func showDeeplinkError() {
        errorMessage = "Unable to load car rental search results. Please try again."
        WarningManager.shared.showDeeplinkError(for: .rental)
    }
    
    private func showSearchFailedError() {
        errorMessage = "Car rental search failed. Please try different dates or location."
        WarningManager.shared.showDeeplinkError(for: .rental)
    }
    
    private func showGenericError(_ error: Error) {
        errorMessage = error.localizedDescription
        WarningManager.shared.showDeeplinkError(for: .rental, error: error)
    }
    
    private func showServerError() {
        errorMessage = "Car rental service is temporarily unavailable. Please try again later."
        WarningManager.shared.showDeeplinkError(for: .rental)
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
        print("⏰ Rental search timed out after \(searchTimeoutDuration) seconds")
        
        hasTimedOut = true
        isLoading = false
        showTimeoutError()
    }
    
    // MARK: - Helper Methods (unchanged)
    
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        return calendar.date(from: combinedComponents) ?? date
    }
    
    // MARK: - Cleanup
    
    deinit {
        cancelTimeoutTimer()
    }
}
