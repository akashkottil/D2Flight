import Foundation

// MARK: - Poll Request Models
struct PollRequest: Codable {
    let duration_max: Int?
    let stop_count_max: Int?
    let arrival_departure_ranges: [ArrivalDepartureRange]?
    let iata_codes_exclude: [String]?
    let iata_codes_include: [String]?
    let sort_by: String?
    let sort_order: String?
    let agency_exclude: [String]?
    let agency_include: [String]?
    let price_min: Int?
    let price_max: Int?
    
    // Empty initializer for initial poll without filters
    init() {
        self.duration_max = nil
        self.stop_count_max = nil
        self.arrival_departure_ranges = nil
        self.iata_codes_exclude = nil
        self.iata_codes_include = nil
        self.sort_by = nil
        self.sort_order = nil
        self.agency_exclude = nil
        self.agency_include = nil
        self.price_min = nil
        self.price_max = nil
    }
}

struct ArrivalDepartureRange: Codable {
    let arrival: TimeRange
    let departure: TimeRange
}

struct TimeRange: Codable {
    let min: Int
    let max: Int
}

// MARK: - Poll Response Models
struct PollResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let cache: Bool
    let passenger_count: Int
    let airlines: [Airline]
    let min_duration: Int
    let max_duration: Int
    let agencies: [Agency]
    let cheapest_flight: FlightSummary?
    let best_flight: FlightSummary?
    let fastest_flight: FlightSummary?
    let results: [FlightResult]
}

struct Airline: Codable {
    let airlineName: String
    let airlineIata: String
    let airlineLogo: String
}

struct Agency: Codable {
    let code: String
    let name: String
    let image: String
}

struct FlightSummary: Codable {
    let price: Double
    let duration: Int
}

struct FlightResult: Codable, Identifiable {
    let id: String
    let total_duration: Int
    let min_price: Double
    let max_price: Double
    let legs: [FlightLeg]
    let providers: [Provider]
    let is_best: Bool
    let is_cheapest: Bool
    let is_fastest: Bool
}

struct FlightLeg: Codable {
    let arriveTimeAirport: Int
    let departureTimeAirport: Int
    let duration: Int
    let origin: String
    let originCode: String
    let destination: String
    let destinationCode: String
    let stopCount: Int
    let segments: [FlightSegment]
}

struct FlightSegment: Codable {
    let id: String
    let arriveTimeAirport: Int
    let departureTimeAirport: Int
    let duration: Int
    let flightNumber: String
    let airlineName: String
    let airlineIata: String
    let airlineLogo: String
    let originCode: String
    let origin: String
    let destinationCode: String
    let destination: String
    let arrival_day_difference: Int
    let wifi: Bool
    let cabinClass: String?
    let aircraft: String?
}

struct Provider: Codable {
    let isSplit: Bool
    let transferType: String?
    let price: Double
    let splitProviders: [SplitProvider]?
}

struct SplitProvider: Codable {
    let name: String
    let imageURL: String
    let price: Double
    let deeplink: String
    let rating: Double?
    let ratingCount: Int?
    let fareFamily: [String: String]?
}

// MARK: - Helper Extensions
extension FlightResult {
    var formattedDuration: String {
        let hours = total_duration / 60
        let minutes = total_duration % 60
        return "\(hours)h \(minutes)m"
    }
    
    var formattedPrice: String {
        return String(format: "$%.0f", min_price)
    }
}

extension FlightLeg {
    var formattedDepartureTime: String {
        let date = Date(timeIntervalSince1970: TimeInterval(departureTimeAirport))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var formattedArrivalTime: String {
        let date = Date(timeIntervalSince1970: TimeInterval(arriveTimeAirport))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var stopsText: String {
        if stopCount == 0 {
            return "Non-stop"
        } else if stopCount == 1 {
            return "1 Stop"
        } else {
            return "\(stopCount) Stops"
        }
    }
}
