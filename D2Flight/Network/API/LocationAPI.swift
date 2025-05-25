import Foundation
import Alamofire

class LocationAPI {
    static let shared = LocationAPI()
    private let baseURL = APIConstants.baseURL

    func fetchLocations(search: String, country: String = "IN", language: String = "en-GB", completion: @escaping (Result<[LocationData], Error>) -> Void) {
        let endpoint = "/autocomplete"
        let url = "\(baseURL)\(endpoint)?search=\(search)&country=\(country)&language=\(language)"

        AF.request(url).validate().responseDecodable(of: LocationResponse.self) { response in
            switch response.result {
            case .success(let result):
                completion(.success(result.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
