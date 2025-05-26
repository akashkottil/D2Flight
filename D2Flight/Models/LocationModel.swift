import Foundation

struct LocationResponse: Codable {
    let data: [Location]
}

struct Location: Codable, Identifiable {
    var id: String { iataCode }
    let iataCode: String
    let airportName: String
    let type: String
    let displayName: String
    let cityName: String
    let countryName: String
    let countryCode: String
    let imageUrl: String
    let coordinates: Coordinates
}

struct Coordinates: Codable {
    let latitude: String
    let longitude: String
}
