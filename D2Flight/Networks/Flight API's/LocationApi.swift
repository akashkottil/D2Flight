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
            // Get dynamic language for empty response
            let apiParams = APIConstants.getAPIParameters()
            completion(.success(LocationResponse(data: [], language: apiParams.language)))
            return
        }
        
        // Get dynamic values from settings
        let apiParams = APIConstants.getAPIParameters()
        
        let url = APIConstants.flightBaseURL + APIConstants.Endpoints.autocomplete
        
        let parameters: [String: Any] = [
            "search": query,
            "country": apiParams.country,
            "language": apiParams.language
        ]
        
        let headers: HTTPHeaders = [
            "accept": APIConstants.Headers.accept
        ]
        
        print("🔧 LocationApi using dynamic parameters:")
        print("   Country: \(apiParams.country)")
        print("   Language: \(apiParams.language)")
        
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
                completion(.success(locationResponse))
            case .failure(let error):
                print("API Error: \(error)")
                completion(.failure(error))
            }
        }
    }
}
