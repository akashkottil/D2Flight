import Foundation
import Alamofire

class FlightSearchApi {
    static let shared = FlightSearchApi()
    private init() {}

    private let baseURL = APIConstants.flightBaseURL

    func startSearch(
        request: SearchRequest,
        userId: String = APIConstants.DefaultParams.userId,
        completion: @escaping (Result<SearchResponse, Error>) -> Void
    ) {
        // Get dynamic values from settings
        let apiParams = APIConstants.getAPIParameters()
        
        let url = "\(baseURL)\(APIConstants.Endpoints.search)?user_id=\(userId)&currency=\(apiParams.currency)&language=\(apiParams.language)&app_code=\(APIConstants.DefaultParams.appCode)"

        print("🔧 Using dynamic API parameters:")
        print("   Country: \(apiParams.country)")
        print("   Currency: \(apiParams.currency)")
        print("   Language: \(apiParams.language)")

        let headers: HTTPHeaders = [
            "accept": APIConstants.Headers.accept,
            "country": apiParams.country,
            "Content-Type": APIConstants.Headers.contentType,
        ]

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
                completion(.success(searchResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
