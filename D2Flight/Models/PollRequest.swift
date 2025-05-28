import Foundation

// MARK: - Poll Request Models
struct PollRequest: Codable {
    let durationMax: Int?
    let stopCountMax: Int?
    let arrivalDepartureRanges: [ArrivalDeparture]?
    let iataCodesExclude: [String]?
    let iataCodesInclude: [String]?
    let sortBy: String?
    let sortOrder: String?
    let agencyExclude: [String]?
    let agencyInclude: [String]?
    let priceMin: Double?
    let priceMax: Double?
    
    enum CodingKeys: String, CodingKey {
        case durationMax = "duration_max"
        case stopCountMax = "stop_count_max"
        case arrivalDepartureRanges = "arrival_departure_ranges"
        case iataCodesExclude = "iata_codes_exclude"
        case iataCodesInclude = "iata_codes_include"
        case sortBy = "sort_by"
        case sortOrder = "sort_order"
        case agencyExclude = "agency_exclude"
        case agencyInclude = "agency_include"
        case priceMin = "price_min"
        case priceMax = "price_max"
    }
    
    // Initialize with all nil values for initial request
    init() {
        self.durationMax = nil
        self.stopCountMax = nil
        self.arrivalDepartureRanges = nil
        self.iataCodesExclude = nil
        self.iataCodesInclude = nil
        self.sortBy = nil
        self.sortOrder = nil
        self.agencyExclude = nil
        self.agencyInclude = nil
        self.priceMin = nil
        self.priceMax = nil
    }
    
    // Initialize with custom filter values
    init(durationMax: Int? = nil,
         stopCountMax: Int? = nil,
         arrivalDepartureRanges: [ArrivalDeparture]? = nil,
         iataCodesExclude: [String]? = nil,
         iataCodesInclude: [String]? = nil,
         sortBy: String? = nil,
         sortOrder: String? = nil,
         agencyExclude: [String]? = nil,
         agencyInclude: [String]? = nil,
         priceMin: Double? = nil,
         priceMax: Double? = nil) {
        self.durationMax = durationMax
        self.stopCountMax = stopCountMax
        self.arrivalDepartureRanges = arrivalDepartureRanges
        self.iataCodesExclude = iataCodesExclude
        self.iataCodesInclude = iataCodesInclude
        self.sortBy = sortBy
        self.sortOrder = sortOrder
        self.agencyExclude = agencyExclude
        self.agencyInclude = agencyInclude
        self.priceMin = priceMin
        self.priceMax = priceMax
    }
}

struct ArrivalDeparture: Codable {
    let arrivalTimeRange: TimeRange?
    let departureTimeRange: TimeRange?
    
    enum CodingKeys: String, CodingKey {
        case arrivalTimeRange = "arrival_time_range"
        case departureTimeRange = "departure_time_range"
    }
}

struct TimeRange: Codable {
    let min: Int?
    let max: Int?
}

// MARK: - Poll Response Models
struct PollResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let cache: Bool
    let passengerCount: Int
    let minDuration: Int
    let maxDuration: Int
    let minPrice: Int
    let maxPrice: Int
    let airlines: [Airline]
    let agencies: [Agency]
    let cheapestFlight: FlightSummary
    let bestFlight: FlightSummary
    let fastestFlight: FlightSummary
    let results: [FlightResult]
    
    enum CodingKeys: String, CodingKey {
        case count, next, previous, cache
        case passengerCount = "passenger_count"
        case minDuration = "min_duration"
        case maxDuration = "max_duration"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case airlines, agencies
        case cheapestFlight = "cheapest_flight"
        case bestFlight = "best_flight"
        case fastestFlight = "fastest_flight"
        case results
    }
}

struct Airline: Codable, Identifiable {
    let id = UUID()
    let airlineName: String
    let airlineIata: String
    let airlineLogo: String
    
    enum CodingKeys: String, CodingKey {
        case airlineName, airlineIata, airlineLogo
    }
}

struct Agency: Codable, Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let image: String
}

struct FlightSummary: Codable {
    let price: Int
    let duration: Int
}

struct FlightResult: Codable, Identifiable {
    let id: String
    let totalDuration: Int
    let minPrice: Int
    let maxPrice: Int
    let legs: [FlightLeg]
    let providers: [Provider]
    
    enum CodingKeys: String, CodingKey {
        case id
        case totalDuration = "total_duration"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case legs, providers
    }
}

struct FlightLeg: Codable, Identifiable {
    let id = UUID()
    let arriveTimeAirport: Int
    let departureTimeAirport: Int
    let duration: Int
    let origin: String
    let originCode: String
    let destination: String
    let destinationCode: String
    let stopCount: Int
    let segments: [FlightSegment]
    
    enum CodingKeys: String, CodingKey {
        case arriveTimeAirport, departureTimeAirport, duration
        case origin, originCode, destination, destinationCode
        case stopCount = "stop_count"
        case segments
    }
}

struct FlightSegment: Codable, Identifiable {
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
    let arrivalDayDifference: Int
    let wifi: Bool
    let cabinClass: String?
    let aircraft: String?
    
    enum CodingKeys: String, CodingKey {
        case id, duration, flightNumber, airlineName, airlineIata, airlineLogo
        case originCode, origin, destinationCode, destination, wifi, cabinClass, aircraft
        case arriveTimeAirport, departureTimeAirport
        case arrivalDayDifference = "arrival_day_difference"
    }
}

struct Provider: Codable, Identifiable {
    let id = UUID()
    let isSplit: Bool
    let transferType: String
    let price: Double
    let splitProviders: [SplitProvider]
    
    enum CodingKeys: String, CodingKey {
        case isSplit, transferType, price, splitProviders
    }
}

struct SplitProvider: Codable, Identifiable {
    let id = UUID()
    let name: String
    let imageURL: String
    let price: Double
    let deeplink: String
    let rating: Double
    let ratingCount: Int
    let fareFamily: String?
    
    enum CodingKeys: String, CodingKey {
        case name, price, deeplink, rating, ratingCount, fareFamily
        case imageURL = "imageURL"
    }
}
