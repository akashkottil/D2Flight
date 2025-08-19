import Foundation
import Alamofire

class CurrencyApi {
    static let shared = CurrencyApi()
    private init() {}
    
    private let baseURL = APIConstants.flightBaseURL
    
    func fetchCurrencies(
        page: Int = 1,
        limit: Int = 100, // Fetch all currencies at once
        completion: @escaping (Result<CurrencyApiResponse, Error>) -> Void
    ) {
        let url = "\(baseURL)\(APIConstants.Endpoints.currencies)"
        
        let parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        
        let headers: HTTPHeaders = [
            "accept": APIConstants.Headers.accept,
        ]
        
        print("💰 Fetching currencies from API:")
        print("URL: \(url)")
        print("Parameters: \(parameters)")
        
        AF.request(
            url,
            method: .get,
            parameters: parameters,
            headers: headers
        )
        .validate()
        .responseDecodable(of: CurrencyApiResponse.self) { response in
            switch response.result {
            case .success(let currencyResponse):
                print("✅ Currencies API success! Fetched \(currencyResponse.results.count) currencies")
                print("   Total count: \(currencyResponse.count)")
                print("   Next page: \(currencyResponse.next != nil ? "Available" : "None")")
                completion(.success(currencyResponse))
            case .failure(let error):
                print("❌ Currencies API failed: \(error)")
                if let data = response.data {
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                }
                completion(.failure(error))
            }
        }
    }
    
    // Fetch all currencies with pagination if needed
    func fetchAllCurrencies(completion: @escaping (Result<[CurrencyApiModel], Error>) -> Void) {
        var allCurrencies: [CurrencyApiModel] = []
        
        func fetchPage(_ page: Int) {
            fetchCurrencies(page: page, limit: 100) { result in
                switch result {
                case .success(let response):
                    allCurrencies.append(contentsOf: response.results)
                    
                    // Check if there are more pages
                    if response.next != nil && response.results.count == 100 {
                        fetchPage(page + 1)
                    } else {
                        // All data fetched
                        print("💰 Fetched all currencies: \(allCurrencies.count) total")
                        completion(.success(allCurrencies))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        fetchPage(1)
    }
}
