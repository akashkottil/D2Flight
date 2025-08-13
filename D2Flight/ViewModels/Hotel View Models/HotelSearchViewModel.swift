import Foundation
import Combine

class HotelSearchViewModel: ObservableObject {
    @Published var cityCode: String = ""
    @Published var cityName: String = ""
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
    
    private var cancellables = Set<AnyCancellable>()
    
    func searchHotels() {
        guard !cityCode.isEmpty else {
            errorMessage = "Please select hotel location."
            return
        }
        
        // Validate dates
        guard checkinDate < checkoutDate else {
            errorMessage = "Check-out date must be after check-in date."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let apiDateFormatter = DateFormatter()
        apiDateFormatter.dateFormat = "yyyy-MM-dd"
        
        let checkinString = apiDateFormatter.string(from: checkinDate)
        let checkoutString = apiDateFormatter.string(from: checkoutDate)
        
        // ✅ UPDATED: Use dynamic parameters (country, currency, and user ID will be auto-selected)
        let request = HotelRequest(
            cityName: cityCode, // Using IATA code as city name for API
            checkin: checkinString,
            checkout: checkoutString,
            rooms: rooms,
            adults: adults,
            children: children > 0 ? children : nil
            // Dynamic country, currency, and user ID will be automatically set from APIConstants
        )
        
        print("🏨 Starting hotel search with request:")
        print("   City: \(cityName) (\(cityCode))")
        print("   Check-in: \(checkinString)")
        print("   Check-out: \(checkoutString)")
        print("   Rooms: \(rooms)")
        print("   Adults: \(adults)")
        print("   Children: \(children)")
        print("   🔧 Using dynamic country: \(request.country)")
        print("   🔧 Using dynamic user ID: \(request.userId)")
        
        HotelApi.shared.searchHotel(request: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    self?.deeplink = response.deeplink
                    
                    print("✅ Hotel search successful!")
                    print("   Deeplink: \(response.deeplink)")
                    
                    // ✅ ADDED: Track successful hotel search
                    UserManager.shared.trackHotelSearch()
                    
                case .failure(let error):
                    self?.errorMessage = "Search failed: \(error.localizedDescription)"
                    self?.deeplink = nil
                    
                    print("❌ Hotel search failed:")
                    print("   Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Helper method to get search parameters
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
    
    // Helper method to validate search parameters
    func validateSearchParameters() -> Bool {
        guard !cityCode.isEmpty else {
            errorMessage = "Please select a hotel location"
            return false
        }
        
        guard checkinDate < checkoutDate else {
            errorMessage = "Check-out date must be after check-in date"
            return false
        }
        
        guard rooms > 0 else {
            errorMessage = "Please select at least 1 room"
            return false
        }
        
        guard adults > 0 else {
            errorMessage = "Please select at least 1 adult"
            return false
        }
        
        return true
    }
    
    // Helper method to calculate nights
    func getNumberOfNights() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: checkinDate, to: checkoutDate)
        return max(1, components.day ?? 1)
    }
    
    // Helper method to format date range
    func getFormattedDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        return "\(formatter.string(from: checkinDate)) - \(formatter.string(from: checkoutDate))"
    }
    
    // Helper method to format guest information
    func getFormattedGuestInfo() -> String {
        let totalGuests = adults + children
        let guestsText = "\(totalGuests) Guest\(totalGuests > 1 ? "s" : "")"
        let roomsText = "\(rooms) Room\(rooms > 1 ? "s" : "")"
        return "\(guestsText), \(roomsText)"
    }
}
