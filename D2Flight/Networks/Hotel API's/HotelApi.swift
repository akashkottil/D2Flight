import Foundation
import Alamofire

class HotelApi {
    static let shared = HotelApi()
    private init() {}
    
    private let baseURL = APIConstants.hotelBaseURL
    
    func searchHotel(
        request: HotelRequest,
        completion: @escaping (Result<HotelResponse, Error>) -> Void
    ) {
        let url = "\(baseURL)\(APIConstants.Endpoints.hotelDeeplink)\(request.id)/"
        
        // Get dynamic language from API parameters
        let apiParams = APIConstants.getAPIParameters()
        
        var parameters: [String: Any] = [
            "country": request.country,
            "user_id": request.userId,
            "city_name": request.cityName,
            "country_name": request.countryName,
            "checkin": request.checkin,
            "checkout": request.checkout,
            "rooms": request.rooms,
            "adults": request.adults,
            "language": apiParams.language,
            "currency": apiParams.currency
        ]
        
        // Add children parameter only if it's provided and greater than 0
        if let children = request.children, children > 0 {
            parameters["children"] = children
        }
        
        let headers: HTTPHeaders = [
            "accept": APIConstants.Headers.accept,
            "Accept-Language": apiParams.language,
            "country": apiParams.country
        ]
        
        print("🏨 Hotel API Request with dynamic language:")
        print("   URL: \(url)")
        print("   🌐 Language: \(apiParams.language)")
        print("   💰 Currency: \(apiParams.currency)")
        print("   🌍 Country: \(apiParams.country)")
        print("   Parameters: \(parameters)")
        print("   Headers: \(headers)")
        
        // Create request with timeout
        let request = AF.request(
            url,
            method: .get,
            parameters: parameters,
            headers: headers
        ).validate(statusCode: 200..<400)
        
        // Set timeout for the request
        request.response(queue: .main) { response in
            // Check for timeout or network errors first
            if let error = response.error {
                if error.isTimeoutError {
                    print("⏰ Hotel API timeout error")
                    completion(.failure(HotelAPIError.timeout))
                    return
                } else if error.isActualNetworkError {
                    print("🌐 Hotel API network error: \(error)")
                    completion(.failure(HotelAPIError.networkError(error)))
                    return
                }
            }
            
            // Check HTTP status code
            if let httpResponse = response.response {
                print("🏨 Hotel API HTTP Status: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 400...499:
                    print("❌ Hotel API client error: \(httpResponse.statusCode)")
                    completion(.failure(HotelAPIError.clientError(httpResponse.statusCode)))
                    return
                case 500...599:
                    print("❌ Hotel API server error: \(httpResponse.statusCode)")
                    completion(.failure(HotelAPIError.serverError(httpResponse.statusCode)))
                    return
                default:
                    break
                }
            }
            
            switch response.result {
            case .success(let data):
                // Handle the response - could be HTML redirect or direct URL
                var finalURL = url
                
                // If there's a redirect, use the final URL
                if let httpResponse = response.response,
                   let responseURL = httpResponse.url {
                    finalURL = responseURL.absoluteString
                    print("✅ Got redirect URL: \(finalURL)")
                } else {
                    // Build the URL with parameters if no redirect
                    var urlComponents = URLComponents(string: url)
                    var queryItems: [URLQueryItem] = []
                    
                    for (key, value) in parameters {
                        queryItems.append(URLQueryItem(name: key, value: String(describing: value)))
                    }
                    
                    urlComponents?.queryItems = queryItems
                    finalURL = urlComponents?.url?.absoluteString ?? url
                    print("✅ Built final URL: \(finalURL)")
                }
                
                // Validate the final URL
                guard SearchValidationHelper.validateDeeplink(finalURL) else {
                    print("❌ Invalid deeplink generated: \(finalURL)")
                    completion(.failure(HotelAPIError.invalidDeeplink))
                    return
                }
                
                // If we got HTML data, try to extract any redirect URL from it
                if let htmlData = data,
                   let htmlString = String(data: htmlData, encoding: .utf8) {
                    
                    // Look for meta refresh or JavaScript redirects
                    if let redirectURL = self.extractRedirectURL(from: htmlString) {
                        finalURL = redirectURL
                        print("✅ Extracted redirect URL from HTML: \(finalURL)")
                    }
                    
                    // Only check for specific error patterns that indicate actual failures
                    if self.containsActualError(htmlString) {
                        print("❌ Actual error detected in HTML response")
                        completion(.failure(HotelAPIError.searchFailed))
                        return
                    }
                }
                
                let hotelResponse = HotelResponse(
                    deeplink: finalURL,
                    status: "success",
                    message: "Hotel search URL generated successfully with language \(apiParams.language)"
                )
                
                print("✅ Hotel search successful with language \(apiParams.language)!")
                print("   Final URL: \(finalURL)")
                completion(.success(hotelResponse))
                
            case .failure(let error):
                print("❌ Hotel search failed: \(error)")
                if let data = response.data {
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                }
                completion(.failure(HotelAPIError.apiError(error)))
            }
        }
    }
    
    // Helper function to extract redirect URLs from HTML
    private func extractRedirectURL(from html: String) -> String? {
        // Look for meta refresh redirects
        let metaRefreshPattern = #"<meta[^>]*http-equiv=["']refresh["'][^>]*content=["'][^"']*url=([^"'\s]+)"#
        if let regex = try? NSRegularExpression(pattern: metaRefreshPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           let urlRange = Range(match.range(at: 1), in: html) {
            return String(html[urlRange])
        }
        
        // Look for JavaScript window.location redirects
        let jsRedirectPattern = #"window\.location(?:\.href)?\s*=\s*["']([^"']+)["']"#
        if let regex = try? NSRegularExpression(pattern: jsRedirectPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
           let urlRange = Range(match.range(at: 1), in: html) {
            return String(html[urlRange])
        }
        
        return nil
    }
    
    // NEW: Check for actual error messages (more specific patterns)
    private func containsActualError(_ html: String) -> Bool {
        let actualErrorPatterns = [
            "404 not found",
            "500 internal server error",
            "503 service unavailable",
            "502 bad gateway",
            "504 gateway timeout",
            "access denied",
            "forbidden",
            "server error occurred",
            "page not found",
            "temporarily unavailable"
        ]
        
        let lowercasedHTML = html.lowercased()
        
        // Only flag as error if we find specific error page indicators
        let hasActualError = actualErrorPatterns.contains { pattern in
            lowercasedHTML.contains(pattern)
        }
        
        // Additional check: if HTML is very short (less than 100 chars), might be an error
        let isTooShort = html.count < 100
        
        // Log for debugging
        if hasActualError {
            print("🔍 Found actual error patterns in HTML")
        }
        if isTooShort {
            print("🔍 HTML response is unusually short (\(html.count) chars)")
        }
        
        return hasActualError || isTooShort
    }
}

// MARK: - Hotel API Specific Errors
enum HotelAPIError: LocalizedError {
    case timeout
    case networkError(Error)
    case clientError(Int)
    case serverError(Int)
    case invalidDeeplink
    case searchFailed
    case apiError(Error)
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Hotel search timed out. Please try again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .clientError(let code):
            return "Request error (code: \(code)). Please check your search parameters."
        case .serverError(let code):
            return "Server error (code: \(code)). Please try again later."
        case .invalidDeeplink:
            return "Invalid search result. Please try again."
        case .searchFailed:
            return "Hotel search failed. Please try different dates or location."
        case .apiError(let error):
            return "Search failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Alamofire Error Extensions
extension Error {
    var isTimeoutError: Bool {
        if let afError = self as? AFError,
           case let .sessionTaskFailed(error) = afError {
            return (error as NSError).code == NSURLErrorTimedOut
        }
        return false
    }
    
    var isActualNetworkError: Bool {
        if let afError = self as? AFError,
           case let .sessionTaskFailed(error) = afError {
            let nsError = error as NSError
            
            // Only treat these as actual network errors
            let networkErrorCodes = [
                NSURLErrorNotConnectedToInternet,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorCannotFindHost,
                NSURLErrorDNSLookupFailed
            ]
            
            return networkErrorCodes.contains(nsError.code)
        }
        return false
    }
    
    var isNetworkError: Bool {
        // Keep for backward compatibility
        return isActualNetworkError
    }
}
