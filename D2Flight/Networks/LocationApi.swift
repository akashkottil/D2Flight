import Foundation
import Alamofire

class LocationApi {
    static let shared = LocationApi()
    
    private init() {}
    
    func searchLocations(
        query: String,
        country: String = "IN",
        language: String = "en-GB",
        completion: @escaping (Result<LocationResponse, Error>) -> Void
    ) {
        guard !query.isEmpty else {
            completion(.success(LocationResponse(data: [], language: language)))
            return
        }
        
        let url = APIEndpoints.baseURL + APIEndpoints.autocomplete
        
        let parameters: [String: Any] = [
            "search": query,
            "country": country,
            "language": language
        ]
        
        let headers: HTTPHeaders = [
            "accept": "application/json"
        ]
        
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
