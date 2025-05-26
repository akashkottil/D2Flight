import Foundation
import Alamofire

class LocationAPI {
    static func fetchLocations(searchQuery: String, completion: @escaping ([Location]) -> Void) {
        let url = "https://staging.plane.lascade.com/api/autocomplete"
        let parameters: Parameters = [
            "search": searchQuery,
            "country": "IN",
            "language": "en-GB"
        ]
        
        let headers: HTTPHeaders = [
            "accept": "application/json"
        ]
        
        AF.request(url, parameters: parameters, headers: headers)
            .validate()
            .responseDecodable(of: LocationResponse.self) { response in
                switch response.result {
                case .success(let data):
                    completion(data.data)
                case .failure(let error):
                    print("API Error:", error)
                    completion([])
                }
            }
    }
}
