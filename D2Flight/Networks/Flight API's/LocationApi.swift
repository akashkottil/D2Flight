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
            // ✅ UPDATED: Handle empty response with nullable language
            let apiParams = APIConstants.getAPIParameters()
            let emptyResponse = LocationResponse(data: [], language: apiParams.language)
            completion(.success(emptyResponse))
            return
        }
        
        // ✅ UPDATED: Get dynamic values from settings INCLUDING language
        let apiParams = APIConstants.getAPIParameters()
        
        let url = APIConstants.flightBaseURL + APIConstants.Endpoints.autocomplete
        
        let parameters: [String: Any] = [
            "search": query,
            "country": apiParams.country,
            "language": apiParams.language  // ✅ Now uses dynamic language
        ]
        
        let headers: HTTPHeaders = [
            "accept": APIConstants.Headers.accept
        ]
        
        print("🔧 LocationApi using dynamic parameters:")
        print("   Country: \(apiParams.country)")
        print("   🌐 Language: \(apiParams.language)")  // ✅ Now shows dynamic language
        print("   Query: \(query)")
        
        AF.request(
            url,
            method: .get,
            parameters: parameters,
            headers: headers
        )
        .validate()
        .response { response in
            // ✅ CUSTOM RESPONSE HANDLING: Handle the response manually to debug issues
            switch response.result {
            case .success(let data):
                guard let data = data else {
                    print("❌ No response data received")
                    completion(.failure(NSError(domain: "LocationApi", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response data"])))
                    return
                }
                
                // ✅ DEBUG: Print raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 Raw API Response:")
                    print("   \(jsonString.prefix(500))...") // Print first 500 chars
                }
                
                do {
                    let locationResponse = try JSONDecoder().decode(LocationResponse.self, from: data)
                    print("✅ Location search successful!")
                    print("   Results found: \(locationResponse.data.count)")
                    print("   Response language: \(locationResponse.language ?? "null")")
                    completion(.success(locationResponse))
                } catch {
                    print("❌ Location decoding failed: \(error)")
                    
                    // ✅ ENHANCED ERROR HANDLING: Provide more context
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .valueNotFound(let type, let context):
                            print("   Value not found for type: \(type)")
                            print("   Coding path: \(context.codingPath)")
                            print("   Debug description: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("   Type mismatch for type: \(type)")
                            print("   Coding path: \(context.codingPath)")
                            print("   Debug description: \(context.debugDescription)")
                        case .keyNotFound(let key, let context):
                            print("   Key not found: \(key)")
                            print("   Coding path: \(context.codingPath)")
                        case .dataCorrupted(let context):
                            print("   Data corrupted at: \(context.codingPath)")
                        @unknown default:
                            print("   Unknown decoding error: \(error)")
                        }
                    }
                    
                    completion(.failure(error))
                }
                
            case .failure(let error):
                print("❌ Location search network failed: \(error)")
                completion(.failure(error))
            }
        }
    }
}
