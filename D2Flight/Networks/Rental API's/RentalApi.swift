import Foundation
import Alamofire

class RentalApi {
    static let shared = RentalApi()
    private init() {}
    
    private let baseURL = "https://staging.car.lascade.com"
    
    func searchRental(
        request: RentalRequest,
        completion: @escaping (Result<RentalResponse, Error>) -> Void
    ) {
        let url = "\(baseURL)/deeplink/\(request.id)/"
        
        var parameters: [String: Any] = [
            "country_code": request.countryCode,
            "app_code": request.appCode,
            "pick_up": request.pickUp,
            "pick_up_date": request.pickUpDate,
            "drop_off_date": request.dropOffDate,
            "currency_code": request.currencyCode,
            "language_code": request.languageCode,
            "user_id": request.userId
        ]
        
        // Add drop_off parameter only if it's provided (for different drop-off)
        if let dropOff = request.dropOff {
            parameters["drop_off"] = dropOff
        }
        
        let headers: HTTPHeaders = [
            "accept": "application/json",
            "X-CSRFTOKEN": "zx744wOlRDblepgD7fnZ8w8pdmGDQRW5wE41KoUrxjujQIvSZe7acO7CBBLlWOEF"
        ]
        
        print("🚗 Rental API Request:")
        print("URL: \(url)")
        print("Parameters: \(parameters)")
        print("Headers: \(headers)")
        
        AF.request(
            url,
            method: .get,
            parameters: parameters,
            headers: headers
        )
        .validate()
        .responseDecodable(of: RentalResponse.self) { response in
            switch response.result {
            case .success(let rentalResponse):
                print("✅ Rental search successful!")
                print("   Deeplink: \(rentalResponse.deeplink)")
                completion(.success(rentalResponse))
            case .failure(let error):
                print("❌ Rental search failed: \(error)")
                if let data = response.data {
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                }
                completion(.failure(error))
            }
        }
    }
}
