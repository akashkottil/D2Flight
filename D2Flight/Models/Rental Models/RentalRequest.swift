import Foundation

// MARK: - Rental Request Models
struct RentalRequest {
    let countryCode: String
    let appCode: String
    let pickUp: String
    let dropOff: String?
    let pickUpDate: String // Format: "YYYY-MM-DDTHH:MM"
    let dropOffDate: String // Format: "YYYY-MM-DDTHH:MM"
    let currencyCode: String
    let languageCode: String
    let userId: String
    let id: String // rental provider ID
    
    init(
        pickUp: String,
        dropOff: String? = nil,
        pickUpDate: String,
        dropOffDate: String,
        // Dynamic parameters with fallback to API constants
        countryCode: String? = nil,
        currencyCode: String? = nil,
        languageCode: String? = nil,
        appCode: String = APIConstants.DefaultParams.testAppCode,
        userId: String = APIConstants.DefaultParams.userId,
        id: String = APIConstants.DefaultParams.rentalProviderId
    ) {
        // Get dynamic values from settings if not provided
        let apiParams = APIConstants.getAPIParameters()
        
        self.countryCode = countryCode ?? apiParams.country
        self.currencyCode = currencyCode ?? apiParams.currency
        self.languageCode = languageCode ?? apiParams.language
        self.appCode = appCode
        self.pickUp = pickUp
        self.dropOff = dropOff
        self.pickUpDate = pickUpDate
        self.dropOffDate = dropOffDate
        self.userId = userId
        self.id = id
        
        print("🚗 RentalRequest created with dynamic values:")
        print("   Country Code: \(self.countryCode)")
        print("   Currency Code: \(self.currencyCode)")
        print("   Language Code: \(self.languageCode)")
    }
}

// MARK: - Rental Response Models
struct RentalResponse: Codable {
    let deeplink: String
    let status: String?
    let message: String?
}

// MARK: - Rental Parameters for Search
struct RentalSearchParameters {
    let pickUpLocationCode: String
    let dropOffLocationCode: String?
    let pickUpLocationName: String
    let dropOffLocationName: String?
    let isSameDropOff: Bool
    let pickUpDate: Date
    let pickUpTime: Date
    let dropOffDate: Date
    let dropOffTime: Date
    
    // Computed properties for formatted display
    var formattedPickUpDateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E dd MMM, HH:mm"
        return dateFormatter.string(from: combineDateAndTime(date: pickUpDate, time: pickUpTime))
    }
    
    var formattedDropOffDateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E dd MMM, HH:mm"
        return dateFormatter.string(from: combineDateAndTime(date: dropOffDate, time: dropOffTime))
    }
    
    var formattedDateRange: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E dd MMM"
        
        if isSameDropOff {
            return "\(dateFormatter.string(from: pickUpDate)) - \(dateFormatter.string(from: dropOffDate))"
        } else {
            return "\(dateFormatter.string(from: pickUpDate)) - \(dateFormatter.string(from: dropOffDate))"
        }
    }
    
    var routeDisplayText: String {
        if isSameDropOff {
            return pickUpLocationName
        } else {
            return "\(pickUpLocationName) to \(dropOffLocationName ?? "")"
        }
    }
    
    // Helper function to combine date and time
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
    
    // API format dates
    var apiPickUpDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return dateFormatter.string(from: combineDateAndTime(date: pickUpDate, time: pickUpTime))
    }
    
    var apiDropOffDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return dateFormatter.string(from: combineDateAndTime(date: dropOffDate, time: dropOffTime))
    }
    
    // Initialize with default values
    init(
        pickUpLocationCode: String = "",
        dropOffLocationCode: String? = nil,
        pickUpLocationName: String = "",
        dropOffLocationName: String? = nil,
        isSameDropOff: Bool = true,
        pickUpDate: Date = Date(),
        pickUpTime: Date = {
            let calendar = Calendar.current
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        }(),
        dropOffDate: Date = {
            let calendar = Calendar.current
            return calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        }(),
        dropOffTime: Date = {
            let calendar = Calendar.current
            return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
        }()
    ) {
        self.pickUpLocationCode = pickUpLocationCode
        self.dropOffLocationCode = dropOffLocationCode
        self.pickUpLocationName = pickUpLocationName
        self.dropOffLocationName = dropOffLocationName
        self.isSameDropOff = isSameDropOff
        self.pickUpDate = pickUpDate
        self.pickUpTime = pickUpTime
        self.dropOffDate = dropOffDate
        self.dropOffTime = dropOffTime
    }
}
