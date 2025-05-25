import Foundation

struct LocationResponse: Codable {
    let data: [LocationData]
}

struct LocationData: Codable, Identifiable {
    let id = UUID() // Required for List rendering
    let iataCode: String
    let airportName: String
    let type: String
    let displayName: String
    let cityName: String
    let countryName: String
    let countryCode: String
    let imageUrl: String?
    let coordinates: Coordinates

    struct Coordinates: Codable {
        let latitude: String
        let longitude: String
    }

    enum CodingKeys: String, CodingKey {
        case iataCode, airportName, type, displayName, cityName,
             countryName, countryCode, imageUrl, coordinates
    }
}
