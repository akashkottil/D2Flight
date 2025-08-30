import Foundation
import Alamofire

enum LocationService {
    case flight
    case hotel
    case rental
    
    var autocompleteURL: String {
        switch self {
        case .flight:
            return APIConstants.flightBaseURL + APIConstants.Endpoints.autocomplete
            
        case .hotel:
            return APIConstants.hotelBaseURL + "/api/v3/hotels/autocomplete"
            
        case .rental:
            return APIConstants.rentalBaseURL + "/api/v1/autocomplete"
        }
    }
    
    var serviceName: String {
        switch self {
        case .flight: return "✈️ Flight"
        case .hotel: return "🏨 Hotel"
        case .rental: return "🚗 Rental"
        }
    }
}


class LocationApi {
    static let shared = LocationApi()
    private init() {}
    
    func searchLocations(
        query: String,
        service: LocationService = .flight,
        completion: @escaping (Result<LocationResponse, Error>) -> Void
    ) {
        guard !query.isEmpty else {
            let apiParams = APIConstants.getAPIParameters()
            let emptyResponse = LocationResponse(data: [], language: apiParams.language)
            completion(.success(emptyResponse))
            return
        }
        
        let apiParams = APIConstants.getAPIParameters()
        let url = service.autocompleteURL
        
        // ✅ UPDATED: Service-specific parameter construction
        let parameters: [String: Any]
        
        switch service {
        case .flight:
            // Flight API parameters (existing format)
            parameters = [
                "search": query,
                "country": apiParams.country,
                "language": apiParams.language
            ]
            
        case .rental:
            // Rental API parameters (existing format)
            parameters = [
                "search": query,
                "country": apiParams.country,
                "language": apiParams.language
            ]
            
        case .hotel:
            // ✅ CORRECT: Hotel v3 API parameters with dynamic values
            parameters = [
                "search": query,                    // ✅ Selected city name from user input
                "country": apiParams.country,       // ✅ Dynamic country from app settings (e.g., "IN")
                "language": apiParams.language      // ✅ Dynamic language from app settings (e.g., "en-GB")
            ]
        }
        
        let headers: HTTPHeaders = [
            "accept": APIConstants.Headers.accept
        ]
        
        print("🔧 \(service.serviceName) LocationApi:")
        print("   Autocomplete URL: \(url)")
        print("   🔍 Search Query: \(query)")                    // User's typed city name
        print("   🌍 Country (dynamic): \(apiParams.country)")   // App setting country
        print("   🌐 Language (dynamic): \(apiParams.language)") // App setting language
        print("   📋 Parameters: \(parameters)")
        
        AF.request(
            url,
            method: .get,
            parameters: parameters,
            headers: headers
        )
        .validate()
        .response { response in
            // ... existing response handling stays the same
            switch response.result {
            case .success(let data):
                guard let data = data else {
                    print("❌ No response data received from \(service.serviceName)")
                    completion(.failure(NSError(domain: "LocationApi", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response data"])))
                    return
                }
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 \(service.serviceName) Raw API Response:")
                    print("   \(jsonString.prefix(300))...")
                }
                
                // Service-specific decoding (existing code)
                self.decodeServiceResponse(data: data, service: service, completion: completion)
                
            case .failure(let error):
                print("❌ \(service.serviceName) location search network failed: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    // ✅ NEW: Service-specific response decoding
    private func decodeServiceResponse(
        data: Data,
        service: LocationService,
        completion: @escaping (Result<LocationResponse, Error>) -> Void
    ) {
        do {
            let locations: [Location]
            let language: String?
            
            switch service {
            case .flight:
                // Flight uses the original LocationResponse format
                let flightResponse = try JSONDecoder().decode(LocationResponse.self, from: data)
                locations = flightResponse.data
                language = flightResponse.language
                
            case .rental:
                // Rental has different field names
                let rentalResponse = try JSONDecoder().decode(RentalLocationResponse.self, from: data)
                locations = rentalResponse.data.map { $0.toLocation() }
                language = rentalResponse.language
                
            case .hotel:
                        // ✅ UPDATED: Hotel v3 API structure
                        let hotelResponse = try JSONDecoder().decode(HotelLocationResponse.self, from: data)
                        locations = hotelResponse.results.map { $0.toLocation() }  // ✅ Use 'results' not 'locations'
                        language = hotelResponse.language
                    }
            
            let standardResponse = LocationResponse(data: locations, language: language)
            
            print("✅ \(service.serviceName) location search successful!")
            print("   Results found: \(locations.count)")
            print("   Response language: \(language ?? "null")")
            
            completion(.success(standardResponse))
            
        } catch {
            print("❌ \(service.serviceName) location decoding failed: \(error)")
            
            if let decodingError = error as? DecodingError {
                self.printDetailedDecodingError(decodingError, service: service)
            }
            
            completion(.failure(error))
        }
    }
    
    // ✅ Enhanced error logging
    private func printDetailedDecodingError(_ error: DecodingError, service: LocationService) {
        print("\n🔬 \(service.serviceName) Detailed Decoding Error:")
        
        switch error {
        case .keyNotFound(let key, let context):
            print("   📍 KEY NOT FOUND: \(key.stringValue)")
            print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("   Description: \(context.debugDescription)")
            
        case .typeMismatch(let type, let context):
            print("   📍 TYPE MISMATCH: Expected \(type)")
            print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("   Description: \(context.debugDescription)")
            
        case .valueNotFound(let type, let context):
            print("   📍 VALUE NOT FOUND: \(type)")
            print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            
        case .dataCorrupted(let context):
            print("   📍 DATA CORRUPTED")
            print("   Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("   Description: \(context.debugDescription)")
            
        @unknown default:
            print("   📍 UNKNOWN ERROR: \(error)")
        }
    }
}
