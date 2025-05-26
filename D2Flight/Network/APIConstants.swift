import Foundation

struct APIConstants {
    // MARK: - Base Configuration
    static let baseURL = "https://staging.plane.lascade.com/api"
    static let defaultCountry = "IN"
    static let defaultLanguage = "en-GB"
    
    // MARK: - Endpoints
    enum Endpoint {
        case autocomplete
        
        var path: String {
            switch self {
            case .autocomplete:
                return "/autocomplete"
            }
        }
        
        var fullURL: String {
            return APIConstants.baseURL + path
        }
    }
    
    // MARK: - Query Parameters
    enum QueryParam {
        static let search = "search"
        static let country = "country"
        static let language = "language"
    }
    
    // MARK: - Headers
    enum Headers {
        static let contentType = "Content-Type"
        static let applicationJSON = "application/json"
        static let accept = "Accept"
    }
    
    // MARK: - Request Configuration
    enum RequestConfig {
        static let timeoutInterval: TimeInterval = 10.0
        static let minimumSearchLength = 2
        static let searchDebounceDelay: TimeInterval = 0.5
    }
}
