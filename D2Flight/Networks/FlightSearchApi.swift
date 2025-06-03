import Foundation
import Alamofire

class FlightSearchApi {
    static let shared = FlightSearchApi()
    private init() {}

    private let baseURL = "https://staging.plane.lascade.com/api"

    func startSearch(
        request: SearchRequest,
        userId: String = "-0",
        currency: String = "INR",
        language: String = "en-GB",
        appCode: String = "D1WF",
        country: String = "IN",
//        csrfToken: String = "5T0SlYIxaKlAkRtdYep2mWPQ6m59AltKEM7TnzXhacX1W7gz1CeI0gqBbXEg8m7z",
        completion: @escaping (Result<SearchResponse, Error>) -> Void
    ) {
        let url = "\(baseURL)/search/?user_id=\(userId)&currency=\(currency)&language=\(language)&app_code=\(appCode)"

        print(currency)
        let headers: HTTPHeaders = [
            "accept": "application/json",
            "country": country,
            "Content-Type": "application/json",
//            "X-CSRFTOKEN": csrfToken
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
