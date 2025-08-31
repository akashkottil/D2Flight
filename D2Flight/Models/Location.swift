import Foundation

// MARK: - Location Response Models
struct LocationResponse: Codable {
    let data: [Location]
    let language: String?  // ✅ FIXED: Made optional to handle null values
    
    // Custom initializer to provide fallback language
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode data array
        self.data = try container.decode([Location].self, forKey: .data)
        
        // Try to decode language, with fallback
        if let language = try? container.decodeIfPresent(String.self, forKey: .language) {
            self.language = language
        } else {
            // Fallback to current app language if API doesn't return it
            self.language = LocalizationManager.shared.currentLanguage
            print("⚠️ API returned null language, using app language: \(self.language ?? "unknown")")
        }
    }
    
    // Manual initializer for testing
    init(data: [Location], language: String?) {
        self.data = data
        self.language = language
    }
    
    enum CodingKeys: String, CodingKey {
        case data, language
    }
}

struct Location: Codable, Identifiable {
    let id = UUID()
    let iataCode: String
    let airportName: String
    let type: String
    let displayName: String
    let cityName: String
    let countryName: String
    let countryCode: String
    let imageUrl: String
    let coordinates: Coordinates
    
    enum CodingKeys: String, CodingKey {
        case iataCode, airportName, type, displayName, cityName, countryName, countryCode, imageUrl, coordinates
    }
}

// ✅ FIXED: Coordinates model to handle both String and Number formats
struct Coordinates: Codable {
    let latitude: String
    let longitude: String
    
    // Custom initializer to handle different data types
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode latitude as String first, then as numbers
        if let latString = try? container.decode(String.self, forKey: .latitude) {
            self.latitude = latString
        } else if let latDouble = try? container.decode(Double.self, forKey: .latitude) {
            self.latitude = String(latDouble)
        } else if let latFloat = try? container.decode(Float.self, forKey: .latitude) {
            self.latitude = String(latFloat)
        } else {
            // Fallback to "0" if all fail
            print("⚠️ Failed to decode latitude, using default value")
            self.latitude = "0"
        }
        
        // Try to decode longitude as String first, then as numbers
        if let lonString = try? container.decode(String.self, forKey: .longitude) {
            self.longitude = lonString
        } else if let lonDouble = try? container.decode(Double.self, forKey: .longitude) {
            self.longitude = String(lonDouble)
        } else if let lonFloat = try? container.decode(Float.self, forKey: .longitude) {
            self.longitude = String(lonFloat)
        } else {
            // Fallback to "0" if all fail
            print("⚠️ Failed to decode longitude, using default value")
            self.longitude = "0"
        }
    }
    
    // Custom encoding to always encode as strings
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
    
    // Convenience initializer for manual creation
    init(latitude: String, longitude: String) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // Helper computed properties for numeric values
    var latitudeDouble: Double {
        return Double(latitude) ?? 0.0
    }
    
    var longitudeDouble: Double {
        return Double(longitude) ?? 0.0
    }
}


// MARK: - Service-Specific Location Models

// ✅ Rental Location Response (different structure)
struct RentalLocationResponse: Codable {
    let data: [RentalLocation]
    let language: String?
}

struct RentalLocation: Codable, Identifiable {
    let id = UUID()
    let name: String                    // "Dubai (DXB)"
    let displayName: String             // "Dubai, Dubai, United Arab Emirates"
    let type: String                    // "airport"
    let coordinates: Coordinates
    
    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case type
        case coordinates
    }
    
    // Convert to standard Location for UI compatibility
    func toLocation() -> Location {
        // Extract IATA code from name if available
        let iataCode = extractIATACode(from: name)
        
        return Location(
            iataCode: iataCode,
            airportName: name,
            type: type,
            displayName: displayName,
            cityName: extractCityName(from: displayName),
            countryName: extractCountryName(from: displayName),
            countryCode: "", // Not provided in rental response
            imageUrl: "",    // Not provided in rental response
            coordinates: coordinates
        )
    }
    
    private func extractIATACode(from name: String) -> String {
        // Extract code from "Dubai (DXB)" format
        if let start = name.lastIndex(of: "("),
           let end = name.lastIndex(of: ")") {
            return String(name[name.index(after: start)..<end])
        }
        return name.prefix(3).uppercased() + String(name.hashValue % 1000)
    }
    
    private func extractCityName(from displayName: String) -> String {
        return displayName.components(separatedBy: ", ").first ?? displayName
    }
    
    private func extractCountryName(from displayName: String) -> String {
        let components = displayName.components(separatedBy: ", ")
        return components.last ?? ""
    }
}

struct HotelLocationResponse: Codable {
    let results: [HotelLocationV3]
    let language: String?
    
    // Custom decoder with enhanced error handling
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode results with individual item error handling
        do {
            self.results = try container.decode([HotelLocationV3].self, forKey: .results)
        } catch {
            print("❌ Error decoding hotel location results: \(error)")
            
            // Try to decode items individually to skip corrupted ones
            if let jsonArray = try? container.decode([JSONValue].self, forKey: .results) {
                var validResults: [HotelLocationV3] = []
                
                for (index, jsonItem) in jsonArray.enumerated() {
                    do {
                        let itemData = try JSONSerialization.data(withJSONObject: jsonItem.value)
                        let decodedItem = try JSONDecoder().decode(HotelLocationV3.self, from: itemData)
                        validResults.append(decodedItem)
                    } catch {
                        print("⚠️ Skipping corrupted hotel location at index \(index): \(error)")
                    }
                }
                
                self.results = validResults
                print("✅ Recovered \(validResults.count) valid hotel locations from \(jsonArray.count) total")
            } else {
                // If all else fails, return empty array to prevent app crash
                print("🚨 Could not decode any hotel location results, returning empty array")
                self.results = []
            }
        }
        
        // Hotel v3 API doesn't return language field
        self.language = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case results
    }
}

// ✅ NEW: Hotel v3 Location Structure
struct HotelLocationV3: Codable, Identifiable {
    let id = UUID()
    let placeId: Int
    let primaryPlaceType: String
    let displayPlaceType: DisplayPlaceType
    let fullName: String
    let location: LocationCoordinates
    let countryName: String
    let countryCode: String
    let regionName: String
    let cityName: String?       // ✅ Already optional
    let cityId: Int?            // ✅ FIXED: Make optional to prevent crashes
    
    // Custom decoder to handle missing optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        self.placeId = try container.decode(Int.self, forKey: .placeId)
        self.primaryPlaceType = try container.decode(String.self, forKey: .primaryPlaceType)
        self.displayPlaceType = try container.decode(DisplayPlaceType.self, forKey: .displayPlaceType)
        self.fullName = try container.decode(String.self, forKey: .fullName)
        self.location = try container.decode(LocationCoordinates.self, forKey: .location)
        self.countryName = try container.decode(String.self, forKey: .countryName)
        self.countryCode = try container.decode(String.self, forKey: .countryCode)
        self.regionName = try container.decode(String.self, forKey: .regionName)
        
        // Optional fields with fallback handling
        self.cityName = try container.decodeIfPresent(String.self, forKey: .cityName)
        self.cityId = try container.decodeIfPresent(Int.self, forKey: .cityId)
        
        // Debug logging for missing fields
        if self.cityName == nil {
            print("⚠️ Hotel location missing cityName for: \(self.fullName)")
        }
        if self.cityId == nil {
            print("⚠️ Hotel location missing cityId for: \(self.fullName)")
        }
    }
    
    // Convert to standard Location for UI compatibility
    func toLocation() -> Location {
        // ✅ Use fallback logic for missing cityName
        let safeCityName = cityName ?? extractCityFromFullName()
        
        return Location(
            iataCode: safeCityName,             // ✅ Use safe city name
            airportName: safeCityName,
            type: primaryPlaceType,
            displayName: fullName,
            cityName: safeCityName,             // ✅ Use safe city name
            countryName: countryName,
            countryCode: countryCode,
            imageUrl: "",
            coordinates: Coordinates(
                latitude: String(location.latitude),
                longitude: String(location.longitude)
            )
        )
    }
    
    // ✅ NEW: Extract city name from fullName as fallback
    private func extractCityFromFullName() -> String {
        // "Malacca, Malaysia" -> "Malacca"
        let components = fullName.components(separatedBy: ", ")
        return components.first ?? fullName
    }
    
    enum CodingKeys: String, CodingKey {
        case placeId, primaryPlaceType, displayPlaceType, fullName, location
        case countryName, countryCode, regionName, cityName, cityId
    }
}

// ✅ NEW: Supporting v3 structures
struct DisplayPlaceType: Codable {
    let type: String
    let displayName: String
}

struct LocationCoordinates: Codable {
    let latitude: Double
    let longitude: Double
}

struct JSONValue: Codable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([JSONValue].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: JSONValue].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else {
            try container.encodeNil()
        }
    }
}

// MARK: - Location Type Enum
enum LocationType: String, CaseIterable {
    case city = "city"
    case airport = "airport"
    
    var iconName: String {
        switch self {
        case .city:
            return "HotelIcon"
        case .airport:
            return "FlightIcon"
        }
    }
}
