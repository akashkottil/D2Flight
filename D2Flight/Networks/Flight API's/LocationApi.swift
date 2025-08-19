import Foundation
import Alamofire

class LocationApi {
    static let shared = LocationApi()
    
    private init() {}
    
    func searchLocations(
        query: String,
        completion: @escaping (Result<LocationResponse, Error>) -> Void
    ) {
        guard !query.isEmpty else {
            // ✅ UPDATED: Get dynamic language for empty response
            let apiParams = APIConstants.getAPIParameters()
            completion(.success(LocationResponse(data: [], language: apiParams.language)))
            return
        }
        
        // ✅ UPDATED: Get dynamic values from settings INCLUDING language
        let apiParams = APIConstants.getAPIParameters()
        
        let url = APIConstants.flightBaseURL + APIConstants.Endpoints.autocomplete
        
        let parameters: [String: Any] = [
            "search": query,
            "country": apiParams.country,
            "language": apiParams.language  // ✅ Now uses dynamic language
        ]
        
        let headers: HTTPHeaders = [
            "accept": APIConstants.Headers.accept
        ]
        
        print("🔧 LocationApi using dynamic parameters:")
        print("   Country: \(apiParams.country)")
        print("   🌐 Language: \(apiParams.language)")  // ✅ Now shows dynamic language
        print("   Query: \(query)")
        
        AF.request(
            url,
            method: .get,
            parameters: parameters,
            headers: headers
        )
        .validate()
        .responseDecodable(of: LocationResponse.self) { response in
            switch response.result {
            case .success(let locationResponse):
                print("✅ Location search successful with language: \(apiParams.language)")
                completion(.success(locationResponse))
            case .failure(let error):
                print("❌ Location search failed: \(error)")
                completion(.failure(error))
            }
        }
    }
}
