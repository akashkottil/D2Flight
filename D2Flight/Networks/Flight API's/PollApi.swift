import Foundation
import Alamofire

class PollApi {
    static let shared = PollApi()
    private init() {}
    
    private let baseURL = "https://staging.plane.lascade.com/api"
    
    func pollFlights(
        searchId: String,
        request: PollRequest = PollRequest(), // Default empty request for initial poll
        page: Int = 1,
        limit: Int = 30,
        completion: @escaping (Result<PollResponse, Error>) -> Void
    ) {
        // ✅ FIXED: Get dynamic API parameters including language
        let apiParams = APIConstants.getAPIParameters()
        
        // ✅ FIXED: Add language parameter to URL
        let url = "\(baseURL)/poll/?search_id=\(searchId)&page=\(page)&limit=\(limit)&language=\(apiParams.language)&currency=\(apiParams.currency)"
        
        let headers: HTTPHeaders = [
            "accept": "application/json",
            "Content-Type": "application/json",
            // ✅ ADDED: Country and language headers
            "country": apiParams.country,
            "Accept-Language": apiParams.language
        ]
        
        // ✅ FIXED: Only send user-selected filter values
        let parameters: [String: Any] = buildFilterParameters(from: request)
        
        print("🔍 Polling flights with dynamic language support:")
        print("   Search ID: \(searchId)")
        print("   Page: \(page), Limit: \(limit)")
        print("   🌐 Language: \(apiParams.language)")
        print("   💰 Currency: \(apiParams.currency)")
        print("   🌍 Country: \(apiParams.country)")
        print("   📋 Request has filters: \(request.hasFilters())")
        print("   📋 Request parameters: \(parameters)")
        print("   📡 URL: \(url)")
        
        // ✅ ENHANCED: Print CURL command for filter debugging
        printFilterDebugCurl(
            url: url,
            headers: headers,
            parameters: parameters,
            filterRequest: request,
            context: "FILTER_APPLICATION"
        )
        
        AF.request(
            url,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .validate()
        .responseDecodable(of: PollResponse.self) { response in
            switch response.result {
            case .success(let pollResponse):
                print("✅ Poll successful with language \(apiParams.language)!")
                print("   Found \(pollResponse.results.count) flights in this batch (total: \(pollResponse.count))")
                print("   Cache status: \(pollResponse.cache)")
                print("   Next page available: \(pollResponse.next != nil)")
                print("   ✅ Loaded \(pollResponse.results.count) results in INITIAL batch (target: \(limit))")
                completion(.success(pollResponse))
            case .failure(let error):
                print("❌ Poll failed: \(error)")
                if let data = response.data {
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                }
                completion(.failure(error))
            }
        }
    }
    
    // ✅ COMPLETELY REWRITTEN: Only include user-selected filters
    private func buildFilterParameters(from request: PollRequest) -> [String: Any] {
        var params: [String: Any] = [:]
        
        // ✅ Duration filter - only if user modified it
        if let duration_max = request.duration_max {
            params["duration_max"] = duration_max
            print("🔧 Adding duration_max: \(duration_max)")
        }
        
        // ✅ CRITICAL FIX: Exact stops filtering
        if let stop_count_min = request.stop_count_min,
           let stop_count_max = request.stop_count_max,
           stop_count_min == stop_count_max {
            // Exact stops filtering - both min and max are the same
            params["stop_count_min"] = stop_count_min
            params["stop_count_max"] = stop_count_max
            print("🔧 Adding EXACT stops filter: exactly \(stop_count_min) stops")
            print("   stop_count_min: \(stop_count_min)")
            print("   stop_count_max: \(stop_count_max)")
            print("   This will show ONLY flights with exactly \(stop_count_min) stops")
        } else {
            // Fallback to individual min/max if they're different
            if let stop_count_min = request.stop_count_min {
                params["stop_count_min"] = stop_count_min
                print("🔧 Adding stop_count_min: \(stop_count_min)")
            }
            if let stop_count_max = request.stop_count_max {
                params["stop_count_max"] = stop_count_max
                print("🔧 Adding stop_count_max: \(stop_count_max)")
            }
        }
        
        // ✅ Time range filters - only if user modified them
        if let arrival_departure_ranges = request.arrival_departure_ranges, !arrival_departure_ranges.isEmpty {
            params["arrival_departure_ranges"] = arrival_departure_ranges.map { range in
                [
                    "arrival": [
                        "min": range.arrival.min,
                        "max": range.arrival.max
                    ],
                    "departure": [
                        "min": range.departure.min,
                        "max": range.departure.max
                    ]
                ]
            }
            print("🔧 Adding arrival_departure_ranges: \(arrival_departure_ranges.count) ranges")
        }
        
        // ✅ Airline include filters - only if user selected airlines
        if let iata_codes_include = request.iata_codes_include, !iata_codes_include.isEmpty {
            params["iata_codes_include"] = iata_codes_include
            print("🔧 Adding iata_codes_include: \(iata_codes_include)")
        }
        
        // ✅ Airline exclude filters - only if user excluded airlines
        if let iata_codes_exclude = request.iata_codes_exclude, !iata_codes_exclude.isEmpty {
            params["iata_codes_exclude"] = iata_codes_exclude
            print("🔧 Adding iata_codes_exclude: \(iata_codes_exclude)")
        }
        
        // ✅ Sort options - only if user changed from default
        if let sort_by = request.sort_by {
            params["sort_by"] = sort_by
            print("🔧 Adding sort_by: \(sort_by)")
        }
        if let sort_order = request.sort_order {
            params["sort_order"] = sort_order
            print("🔧 Adding sort_order: \(sort_order)")
        }
        
        // ✅ Agency filters - only if user selected
        if let agency_include = request.agency_include, !agency_include.isEmpty {
            params["agency_include"] = agency_include
            print("🔧 Adding agency_include: \(agency_include)")
        }
        if let agency_exclude = request.agency_exclude, !agency_exclude.isEmpty {
            params["agency_exclude"] = agency_exclude
            print("🔧 Adding agency_exclude: \(agency_exclude)")
        }
        
        // ✅ Price filters - only if user modified them
        if let price_min = request.price_min {
            params["price_min"] = price_min
            print("🔧 Adding price_min: \(price_min)")
        }
        if let price_max = request.price_max {
            params["price_max"] = price_max
            print("🔧 Adding price_max: \(price_max)")
        }
        
        print("🔧 Final filter parameters: \(params)")
        return params
    }
    
    // ✅ ENHANCED: Filter-specific CURL debug printing
    private func printFilterDebugCurl(
        url: String,
        headers: HTTPHeaders,
        parameters: [String: Any],
        filterRequest: PollRequest,
        context: String
    ) {
        print("\n🐛 ===== FILTER DEBUG: \(context) =====")
        print("🔍 FILTER ANALYSIS:")
        print("   Has Filters: \(filterRequest.hasFilters())")
        
        // Detailed filter breakdown
        if let duration = filterRequest.duration_max {
            print("   ⏱️ Duration Filter: ≤ \(duration) minutes")
        }
        if let stops = filterRequest.stop_count_max {
            print("   🛑 Stop Filter: ≤ \(stops) stops")
        }
        if let priceMin = filterRequest.price_min {
            print("   💰 Price Min: ≥ ₹\(priceMin)")
        }
        if let priceMax = filterRequest.price_max {
            print("   💰 Price Max: ≤ ₹\(priceMax)")
        }
        if let airlines = filterRequest.iata_codes_include, !airlines.isEmpty {
            print("   ✈️ Include Airlines: \(airlines.joined(separator: ", "))")
        }
        if let excludeAirlines = filterRequest.iata_codes_exclude, !excludeAirlines.isEmpty {
            print("   🚫 Exclude Airlines: \(excludeAirlines.joined(separator: ", "))")
        }
        if let sortBy = filterRequest.sort_by {
            let sortOrder = filterRequest.sort_order ?? "asc"
            print("   📊 Sort: \(sortBy) (\(sortOrder))")
        }
        if let timeRanges = filterRequest.arrival_departure_ranges, !timeRanges.isEmpty {
            print("   🕐 Time Filters: \(timeRanges.count) leg(s)")
            for (index, range) in timeRanges.enumerated() {
                let depStart = minutesToTime(range.departure.min)
                let depEnd = minutesToTime(range.departure.max)
                let arrStart = minutesToTime(range.arrival.min)
                let arrEnd = minutesToTime(range.arrival.max)
                print("     Leg \(index + 1): Dep \(depStart)-\(depEnd), Arr \(arrStart)-\(arrEnd)")
            }
        }
        
        print("\n🌐 CURL COMMAND:")
        print("curl -X POST '\(url)' \\")
        
        // Add headers
        for header in headers {
            print("  -H '\(header.name): \(header.value)' \\")
        }
        
        // Add body data
        if !parameters.isEmpty {
            if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                // Pretty print JSON for readability
                print("  -d '\\")
                let lines = jsonString.components(separatedBy: .newlines)
                for line in lines {
                    print("    \(line)")
                }
                print("  '")
            }
        } else {
            print("  -d '{}'")
        }
        
        print("\n📋 RAW PARAMETERS JSON:")
        if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted),
           let prettyJson = String(data: jsonData, encoding: .utf8) {
            print(prettyJson)
        }
        
        print("🐛 ===== END FILTER DEBUG =====\n")
    }
    
    // ✅ Helper function to convert minutes to time string
    private func minutesToTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }
    
    // ✅ Updated method signature to accept filters
    func pollFlightsWithURL(
        nextURL: String,
        request: PollRequest = PollRequest(), // ✅ Add this parameter
        completion: @escaping (Result<PollResponse, Error>) -> Void
    ) {
        let apiParams = APIConstants.getAPIParameters()
        
        let headers: HTTPHeaders = [
            "accept": "application/json",
            "Content-Type": "application/json",
            "country": apiParams.country,
            "Accept-Language": apiParams.language
        ]
        
        // ✅ Build filter parameters like the main pollFlights method
        let parameters: [String: Any] = buildFilterParameters(from: request)
        
        print("🔍 Polling flights with next URL: \(nextURL)")
        print("   🌐 Language: \(apiParams.language)")
        print("   🔧 Applied filters: \(request.hasFilters())")
        
        // ✅ ENHANCED: Print CURL for pagination with filters
        printFilterDebugCurl(
            url: nextURL,
            headers: headers,
            parameters: parameters,
            filterRequest: request,
            context: "PAGINATION_WITH_FILTERS"
        )
        
        AF.request(
            nextURL,
            method: .post,
            parameters: parameters, // ✅ Now includes filters
            encoding: JSONEncoding.default,
            headers: headers
        )
        .validate()
        .responseDecodable(of: PollResponse.self) { response in
            switch response.result {
            case .success(let pollResponse):
                print("✅ Poll with URL successful! Found \(pollResponse.results.count) flights in this batch")
                completion(.success(pollResponse))
            case .failure(let error):
                print("❌ Poll with URL failed: \(error)")
                completion(.failure(error))
            }
        }
    }
}
