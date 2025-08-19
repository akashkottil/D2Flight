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
        
        // ✅ FIXED: Get dynamic language parameters
        let apiParams = APIConstants.getAPIParameters()
        
        var parameters: [String: Any] = [
            "page": page,
            "limit": limit,
            // ✅ ADDED: Language parameter
            "language": apiParams.language
        ]
        
        
        let headers: HTTPHeaders = [
            "accept": APIConstants.Headers.accept,
            // ✅ ADDED: Language and country headers
            "Accept-Language": apiParams.language,
            "country": apiParams.country
        ]
        
        print("💰 Fetching currencies from API with dynamic language:")
        print("   URL: \(url)")
        print("   🌐 Language: \(apiParams.language)")
        print("   🌍 Country: \(apiParams.country)")
        print("   Parameters: \(parameters)")
        print("   Headers: \(headers)")
        
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
                print("✅ Currencies API success with language \(apiParams.language)!")
                print("   Fetched \(currencyResponse.results.count) currencies")
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
                        let apiParams = APIConstants.getAPIParameters()
                        print("💰 Fetched all currencies with language \(apiParams.language): \(allCurrencies.count) total")
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
