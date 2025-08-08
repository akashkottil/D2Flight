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
        let url = "\(baseURL)/poll/?search_id=\(searchId)&page=\(page)&limit=\(limit)"
        
        let headers: HTTPHeaders = [
            "accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        // ✅ FIXED: Only send user-selected filter values
        let parameters: [String: Any] = buildFilterParameters(from: request)
        
        print("🔍 Polling flights with search_id: \(searchId), page: \(page), limit: \(limit)")
        print("📋 Request has filters: \(request.hasFilters())")
        print("📋 Request parameters: \(parameters)")
        
        // ✅ NEW: Print CURL command for debugging
        printCurlCommand(url: url, headers: headers, parameters: parameters)
        
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
                print("✅ Poll successful! Found \(pollResponse.results.count) flights in this batch (total: \(pollResponse.count))")
                print("   Cache status: \(pollResponse.cache)")
                print("   Next page: \(pollResponse.next != nil ? "Available" : "None")")
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
        
        // ✅ Stop count filter - only if user modified it
        if let stop_count_max = request.stop_count_max {
            params["stop_count_max"] = stop_count_max
            print("🔧 Adding stop_count_max: \(stop_count_max)")
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
    
    // ✅ NEW: Print CURL command for debugging
    private func printCurlCommand(url: String, headers: HTTPHeaders, parameters: [String: Any]) {
        print("\n🌐 ===== CURL COMMAND FOR DEBUGGING =====")
        print("curl -X POST '\(url)' \\")
        
        // Add headers - Fixed for Alamofire HTTPHeaders
        for header in headers {
            print("  -H '\(header.name): \(header.value)' \\")
        }
        
        // Add body data
        if !parameters.isEmpty {
            if let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                // Clean up the JSON for curl command
                let cleanJson = jsonString
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "  ", with: "")
                print("  -d '\(cleanJson)'")
            }
        } else {
            print("  -d '{}'")
        }
        print("🌐 ===== END CURL COMMAND =====\n")
    }
    
    // Alternative method using next URL if the API provides full URLs
    func pollFlightsWithURL(
        nextURL: String,
        completion: @escaping (Result<PollResponse, Error>) -> Void
    ) {
        let headers: HTTPHeaders = [
            "accept": "application/json",
            "Content-Type": "application/json"
        ]
        
        print("🔍 Polling flights with next URL: \(nextURL)")
        
        AF.request(
            nextURL,
            method: .post,
            parameters: [:],
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
