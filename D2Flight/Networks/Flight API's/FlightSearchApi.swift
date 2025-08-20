import Foundation
import Alamofire

class FlightSearchApi {
    static let shared = FlightSearchApi()
    private init() {}

    private let baseURL = APIConstants.flightBaseURL

    func startSearch(
        request: SearchRequest,
        userId: String? = nil, // Allow override but use dynamic by default
        completion: @escaping (Result<SearchResponse, Error>) -> Void
    ) {
        // ✅ UPDATED: Use dynamic user ID from UserManager
        let dynamicUserId = userId ?? APIConstants.getCurrentUserId()
        
        // ✅ FIXED: Get dynamic values from settings INCLUDING language
        let apiParams = APIConstants.getAPIParameters()
        
        // ✅ FIXED: Add language parameter to URL
        let url = "\(baseURL)\(APIConstants.Endpoints.search)?user_id=\(dynamicUserId)&currency=\(apiParams.currency)&language=\(apiParams.language)&app_code=\(APIConstants.DefaultParams.appCode)"

        print("🔧 FlightSearchApi using dynamic API parameters:")
        print("   Country: \(apiParams.country)")
        print("   Currency: \(apiParams.currency)")
        print("   🌐 Language: \(apiParams.language)")  // ✅ Now includes language
        print("   🆔 User ID: \(dynamicUserId)")
        print("   📡 URL: \(url)")

        let headers: HTTPHeaders = [
            "accept": APIConstants.Headers.accept,
            "country": apiParams.country,
            "Content-Type": APIConstants.Headers.contentType,
            // ✅ ADDED: Language header for additional context
            "Accept-Language": apiParams.language
        ]

        print("📤 Request Headers: \(headers)")
        print("📤 Request Body: \(request)")

        AF.request(
            url,
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate()
        .responseDecodable(of: SearchResponse.self) { response in
            switch response.result {
            case .success(let searchResponse):
                print("✅ Flight search successful with language: \(apiParams.language)")
                print("   Search ID: \(searchResponse.search_id)")
                print("   Response Language: \(searchResponse.language)")
                print("   Response Currency: \(searchResponse.currency)")
                completion(.success(searchResponse))
            case .failure(let error):
                print("❌ Flight search failed: \(error)")
                if let data = response.data {
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                }
                completion(.failure(error))
            }
        }
    }
}
