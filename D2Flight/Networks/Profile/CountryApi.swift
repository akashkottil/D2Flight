import Foundation
import Alamofire

class CountryApi {
    static let shared = CountryApi()
    private init() {}
    
    private let baseURL = APIConstants.flightBaseURL
    
    func fetchCountries(
        page: Int = 1,
        limit: Int = 100, // Fetch all countries at once
        completion: @escaping (Result<CountryApiResponse, Error>) -> Void
    ) {
        let url = "\(baseURL)\(APIConstants.Endpoints.countries)"
        
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
        
        print("🌍 Fetching countries from API with dynamic language:")
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
        .responseDecodable(of: CountryApiResponse.self) { response in
            switch response.result {
            case .success(let countryResponse):
                print("✅ Countries API success with language \(apiParams.language)!")
                print("   Fetched \(countryResponse.results.count) countries")
                print("   Total count: \(countryResponse.count)")
                print("   Next page: \(countryResponse.next != nil ? "Available" : "None")")
                completion(.success(countryResponse))
            case .failure(let error):
                print("❌ Countries API failed: \(error)")
                if let data = response.data {
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                }
                completion(.failure(error))
            }
        }
    }
    
    // Fetch all countries with pagination if needed
    func fetchAllCountries(completion: @escaping (Result<[CountryApiModel], Error>) -> Void) {
        var allCountries: [CountryApiModel] = []
        
        func fetchPage(_ page: Int) {
            fetchCountries(page: page, limit: 100) { result in
                switch result {
                case .success(let response):
                    allCountries.append(contentsOf: response.results)
                    
                    // Check if there are more pages
                    if response.next != nil && response.results.count == 100 {
                        fetchPage(page + 1)
                    } else {
                        // All data fetched
                        let apiParams = APIConstants.getAPIParameters()
                        print("🌍 Fetched all countries with language \(apiParams.language): \(allCountries.count) total")
                        completion(.success(allCountries))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        fetchPage(1)
    }
}
