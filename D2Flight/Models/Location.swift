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

// ✅ Hotel Location Response (array format)
struct HotelLocationResponse: Codable {
    let locations: [HotelLocation]
    let language: String?
    
    // Custom decoder to handle array response
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.locations = try container.decode([HotelLocation].self)
        self.language = nil // Hotel API doesn't return language
    }
}

struct HotelLocation: Codable, Identifiable {
    let id = UUID()
    let cc: String                      // Country code
    let n: String                       // Name
    let k: String                       // Key/ID
    let hc: String                      // Hotel count
    let s: Int                          // Score/relevance
    let t: String                       // Type
    let tn: String                      // Type name
    let h: String                       // Hotel count text
    let p: [String]                     // Path/location hierarchy
    
    // Convert to standard Location for UI compatibility
    func toLocation() -> Location {
        let displayName = createDisplayName()
        
        return Location(
            iataCode: k,                // Use key as IATA code
            airportName: n,
            type: t,
            displayName: displayName,
            cityName: n,
            countryName: p.last ?? "",
            countryCode: cc,
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0") // Not provided
        )
    }
    
    private func createDisplayName() -> String {
        if p.isEmpty {
            return n
        }
        return "\(n), \(p.joined(separator: ", "))"
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
