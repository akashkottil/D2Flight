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
        
        // ✅ FIXED: Use hasFilters() method instead of just checking duration_max
        let parameters: [String: Any] = request.hasFilters() ? buildFilterParameters(from: request) : [:]
        
        print("🔍 Polling flights with search_id: \(searchId), page: \(page), limit: \(limit)")
        print("📋 Request has filters: \(request.hasFilters())")
        print("📋 Request parameters: \(parameters)")
        
        print("📡 Poll API Request:")
        print("URL: \(url)")
        print("Headers: \(headers)")
        print("HTTP Method: POST")
        print("Body parameters: \(parameters)")
        
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
                print("next page link:\(pollResponse.next != nil ? pollResponse.next! : "no links")")
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
    
    // ✅ NEW: Properly build filter parameters from PollRequest
    private func buildFilterParameters(from request: PollRequest) -> [String: Any] {
        var params: [String: Any] = [:]
        
        // Duration filter
        if let duration_max = request.duration_max {
            params["duration_max"] = duration_max
        }
        
        // Stop count filter
        if let stop_count_max = request.stop_count_max {
            params["stop_count_max"] = stop_count_max
        }
        
        // Time range filters
        if let arrival_departure_ranges = request.arrival_departure_ranges {
            params["arrival_departure_ranges"] = arrival_departure_ranges.map { range in
                [
                    "arrival": ["min": range.arrival.min, "max": range.arrival.max],
                    "departure": ["min": range.departure.min, "max": range.departure.max]
                ]
            }
        }
        
        // Airline filters
        if let iata_codes_exclude = request.iata_codes_exclude, !iata_codes_exclude.isEmpty {
            params["iata_codes_exclude"] = iata_codes_exclude
        }
        if let iata_codes_include = request.iata_codes_include, !iata_codes_include.isEmpty {
            params["iata_codes_include"] = iata_codes_include
        }
        
        // Sort options
        if let sort_by = request.sort_by {
            params["sort_by"] = sort_by
        }
        if let sort_order = request.sort_order {
            params["sort_order"] = sort_order
        }
        
        // Agency filters
        if let agency_exclude = request.agency_exclude, !agency_exclude.isEmpty {
            params["agency_exclude"] = agency_exclude
        }
        if let agency_include = request.agency_include, !agency_include.isEmpty {
            params["agency_include"] = agency_include
        }
        
        // Price filters
        if let price_min = request.price_min {
            params["price_min"] = price_min
        }
        if let price_max = request.price_max {
            params["price_max"] = price_max
        }
        
        return params
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
