//
//  HotelRequest.swift
//  D2Flight
//
//  Created by Akash Kottil on 28/07/25.
//

import Foundation

// MARK: - Hotel Request Models
struct HotelRequest {
    let country: String          // ✅ User's app country (IN)
    let userId: String           // ✅ App user ID (123)
    let cityName: String         // ✅ From autocomplete (mumbai)
    let countryName: String      // ✅ From autocomplete (INDIA)
    let checkin: String          // ✅ User selected (2025-09-15)
    let checkout: String         // ✅ User selected (2025-09-16)
    let rooms: Int               // ✅ User input (1)
    let adults: Int              // ✅ User input (1)
    let children: Int?           // ✅ Optional user input
    let id: String               // ✅ Hotel provider ID (0)
    
    init(
        cityName: String,            // ✅ "mumbai" from autocomplete
        countryName: String,         // ✅ "INDIA" from autocomplete
        checkin: String,
        checkout: String,
        rooms: Int,
        adults: Int,
        children: Int? = nil,
        country: String? = nil,      // ✅ User's app country
        userId: String? = nil,       // ✅ App user ID
        id: String = APIConstants.DefaultParams.hotelProviderId
    ) {
        let apiParams = APIConstants.getAPIParameters()
        
        self.country = country ?? apiParams.country         // ✅ "IN"
        self.userId = userId ?? APIConstants.getCurrentUserId()  // ✅ "123"
        self.cityName = cityName.lowercased()               // ✅ "mumbai" (lowercase)
        self.countryName = countryName.uppercased()         // ✅ "INDIA" (uppercase)
        self.checkin = checkin
        self.checkout = checkout
        self.rooms = rooms
        self.adults = adults
        self.children = children
        self.id = id
        
        print("🏨 HotelRequest created (matching curl format):")
        print("   ✅ country: \(self.country)")              // IN
        print("   ✅ user_id: \(self.userId)")               // 123
        print("   ✅ city_name: \(self.cityName)")           // mumbai
        print("   ✅ country_name: \(self.countryName)")     // INDIA
        print("   ✅ checkin: \(self.checkin)")              // 2025-09-15
        print("   ✅ checkout: \(self.checkout)")            // 2025-09-16
        print("   ✅ rooms: \(self.rooms)")                  // 1
        print("   ✅ adults: \(self.adults)")                // 1
    }
}

// MARK: - Hotel Response Models
struct HotelResponse: Codable {
    let deeplink: String
    let status: String?
    let message: String?
}

// MARK: - Hotel Search Parameters
struct HotelSearchParameters {
    let cityCode: String
    let cityName: String
    let checkinDate: Date
    let checkoutDate: Date
    let rooms: Int
    let adults: Int
    let children: Int
    
    // Computed properties for formatted display
    var formattedCheckinDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        return formatter.string(from: checkinDate)
    }
    
    var formattedCheckoutDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        return formatter.string(from: checkoutDate)
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        return "\(formatter.string(from: checkinDate)) - \(formatter.string(from: checkoutDate))"
    }
    
    var accommodationDisplayText: String {
        let totalGuests = adults + children
        let guestsText = "\(totalGuests) Guest\(totalGuests > 1 ? "s" : "")"
        let roomsText = "\(rooms) Room\(rooms > 1 ? "s" : "")"
        return "\(guestsText), \(roomsText)"
    }
    
    var locationDisplayText: String {
        return cityName
    }
    
    // API format dates
    var apiCheckinDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: checkinDate)
    }
    
    var apiCheckoutDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: checkoutDate)
    }
    
    var numberOfNights: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: checkinDate, to: checkoutDate)
        return max(1, components.day ?? 1)
    }
    
    // Initialize with default values
    init(
        cityCode: String = "",
        cityName: String = "",
        checkinDate: Date = Date(),
        checkoutDate: Date = {
            let calendar = Calendar.current
            return calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        }(),
        rooms: Int = 1,
        adults: Int = 2,
        children: Int = 0
    ) {
        self.cityCode = cityCode
        self.cityName = cityName
        self.checkinDate = checkinDate
        self.checkoutDate = checkoutDate
        self.rooms = rooms
        self.adults = adults
        self.children = children
    }
}
