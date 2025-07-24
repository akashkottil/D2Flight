import Foundation

// MARK: - Poll Request Models
struct PollRequest: Codable {
    var duration_max: Int?
    var stop_count_max: Int?
    var arrival_departure_ranges: [ArrivalDepartureRange]?
    var iata_codes_exclude: [String]?
    var iata_codes_include: [String]?
    var sort_by: String?
    var sort_order: String?
    var agency_exclude: [String]?
    var agency_include: [String]?
    var price_min: Int?
    var price_max: Int?
    
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
    
    // Full initializer for filtered polls
    init(
        duration_max: Int? = nil,
        stop_count_max: Int? = nil,
        arrival_departure_ranges: [ArrivalDepartureRange]? = nil,
        iata_codes_exclude: [String]? = nil,
        iata_codes_include: [String]? = nil,
        sort_by: String? = nil,
        sort_order: String? = nil,
        agency_exclude: [String]? = nil,
        agency_include: [String]? = nil,
        price_min: Int? = nil,
        price_max: Int? = nil
    ) {
        self.duration_max = duration_max
        self.stop_count_max = stop_count_max
        self.arrival_departure_ranges = arrival_departure_ranges
        self.iata_codes_exclude = iata_codes_exclude
        self.iata_codes_include = iata_codes_include
        self.sort_by = sort_by
        self.sort_order = sort_order
        self.agency_exclude = agency_exclude
        self.agency_include = agency_include
        self.price_min = price_min
        self.price_max = price_max
    }
    
    // Helper method to check if request has any filters
    func hasFilters() -> Bool {
        return duration_max != nil ||
               stop_count_max != nil ||
               arrival_departure_ranges != nil ||
               iata_codes_exclude != nil ||
               iata_codes_include != nil ||
               sort_by != nil ||
               sort_order != nil ||
               agency_exclude != nil ||
               agency_include != nil ||
               price_min != nil ||
               price_max != nil
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
  let fareFamily: FareFamily?
  enum CodingKeys: String, CodingKey {
    case name
    case imageURL = "imageURL"
    case price
    case deeplink
    case rating
    case ratingCount
    case fareFamily
  }
}
struct FareFamily: Codable {
  let code: String
  let displayName: String
  let features: [FareFeature]
}
struct FareFeature: Codable {
  let type: String
  let description: String
}

// MARK: - Helper Extensions
extension FlightResult {
    var formattedDuration: String {
        let hours = total_duration / 60
        let minutes = total_duration % 60
        return "\(hours)h \(minutes)m"
    }
    
    var formattedPrice: String {
        return String(format: "₹%.0f", min_price)
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
