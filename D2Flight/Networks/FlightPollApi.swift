import Foundation
import Alamofire

class FlightPollApi {
    static let shared = FlightPollApi()
    private init() {}

    private let baseURL = APIEndpoints.baseURL

    func pollFlightResults(
        searchId: String,
        request: PollRequest = PollRequest(), // Default to empty request
//        csrfToken: String = "3Dk2xyerv0dlJDjOYla7rqeMzLkJyyUgCwr3z9tbvsPMlT6a1JZN5KPxEmTQ6zy5",
        completion: @escaping (Result<PollResponse, Error>) -> Void
    ) {
        let url = "\(baseURL)\(APIEndpoints.poll)?search_id=\(searchId)"

        let headers: HTTPHeaders = [
            "accept": "application/json",
            "Content-Type": "application/json",
//            "X-CSRFTOKEN": csrfToken
        ]

        print("🔍 Polling flight results with:")
        print("   URL: \(url)")
        print("   Search ID: \(searchId)")
        print("   Request: \(request)")

        AF.request(
            url,
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate()
        .responseDecodable(of: PollResponse.self) { response in
            switch response.result {
            case .success(let pollResponse):
                print("✅ Flight poll successful!")
                print("   Results count: \(pollResponse.count)")
                print("   Min price: \(pollResponse.minPrice)")
                print("   Max price: \(pollResponse.maxPrice)")
                print("   Airlines count: \(pollResponse.airlines.count)")
                completion(.success(pollResponse))
            case .failure(let error):
                print("❌ Flight poll failed:")
                print("   Error: \(error.localizedDescription)")
                
                // Print raw response for debugging
                if let data = response.data,
                   let rawResponse = String(data: data, encoding: .utf8) {
                    print("   Raw response: \(rawResponse)")
                }
                
                completion(.failure(error))
            }
        }
    }
    
    // Method to poll with custom filters
    func pollFlightResultsWithFilters(
        searchId: String,
        durationMax: Int? = nil,
        stopCountMax: Int? = nil,
        priceMin: Double? = nil,
        priceMax: Double? = nil,
        sortBy: String? = nil,
        sortOrder: String? = nil,
        completion: @escaping (Result<PollResponse, Error>) -> Void
    ) {
        let request = PollRequest(
            durationMax: durationMax,
            stopCountMax: stopCountMax,
            sortBy: sortBy,
            sortOrder: sortOrder,
            priceMin: priceMin,
            priceMax: priceMax
        )
        
        pollFlightResults(searchId: searchId, request: request, completion: completion)
    }
}
