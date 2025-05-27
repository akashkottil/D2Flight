import Foundation

// MARK: - Location Response Models
struct LocationResponse: Codable {
    let data: [Location]
    let language: String
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

struct Coordinates: Codable {
    let latitude: String
    let longitude: String
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
