import Foundation
import Alamofire

class RentalApi {
    static let shared = RentalApi()
    private init() {}
    
    private let baseURL = APIConstants.rentalBaseURL
    
    func searchRental(
        request: RentalRequest,
        completion: @escaping (Result<RentalResponse, Error>) -> Void
    ) {
        let url = "\(baseURL)\(APIConstants.Endpoints.rentalDeeplink)\(request.id)/"
        
        // Get dynamic language for consistency check
        let apiParams = APIConstants.getAPIParameters()
        
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
            "accept": APIConstants.Headers.accept,  // Use JSON accept header
            "Accept-Language": request.languageCode,
            "country": request.countryCode,
        ]
        
        print("🚗 Rental API Request with dynamic language:")
        print("   URL: \(url)")
        print("   🌐 Language Code: \(request.languageCode)")
        print("   🌐 API Language: \(apiParams.language)")
        print("   💰 Currency Code: \(request.currencyCode)")
        print("   🌍 Country Code: \(request.countryCode)")
        print("   📱 App Code: \(request.appCode)")  // ✅ Show app code in debug
        print("   Parameters: \(parameters)")
        print("   Headers: \(headers)")
        
        // Verification: Check if request language matches current dynamic language
        if request.languageCode != apiParams.language {
            print("⚠️ WARNING: Request language (\(request.languageCode)) differs from current API language (\(apiParams.language))")
        } else {
            print("✅ Language consistency verified: \(request.languageCode)")
        }
        
        // Create request with timeout and validation
        let afRequest = AF.request(
            url,
            method: .get,
            parameters: parameters,
            headers: headers
        ).validate(statusCode: 200..<400)
        
        // Set timeout and handle response
        afRequest.response(queue: .main) { response in
            // Check for timeout or network errors first
            if let error = response.error {
                if error.isTimeoutError {
                    print("⏰ Rental API timeout error")
                    completion(.failure(RentalAPIError.timeout))
                    return
                } else if error.isActualNetworkError {
                    print("🌐 Rental API network error: \(error)")
                    completion(.failure(RentalAPIError.networkError(error)))
                    return
                }
            }
            
            // Check HTTP status code
            if let httpResponse = response.response {
                print("🚗 Rental API HTTP Status: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 400...499:
                    print("❌ Rental API client error: \(httpResponse.statusCode)")
                    completion(.failure(RentalAPIError.clientError(httpResponse.statusCode)))
                    return
                case 500...599:
                    print("❌ Rental API server error: \(httpResponse.statusCode)")
                    completion(.failure(RentalAPIError.serverError(httpResponse.statusCode)))
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
                    completion(.failure(RentalAPIError.invalidDeeplink))
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
                        completion(.failure(RentalAPIError.searchFailed))
                        return
                    }
                }
                
                let rentalResponse = RentalResponse(
                    deeplink: finalURL,
                    status: "success",
                    message: "Rental search URL generated successfully with language \(request.languageCode)"
                )
                
                print("✅ Rental search successful with language \(request.languageCode)!")
                print("   Final URL: \(finalURL)")
                completion(.success(rentalResponse))
                
            case .failure(let error):
                print("❌ Rental search failed: \(error)")
                if let data = response.data {
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                }
                completion(.failure(RentalAPIError.apiError(error)))
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
            "no cars available at this location",
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

// MARK: - Rental API Specific Errors
enum RentalAPIError: LocalizedError {
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
            return "Car rental search timed out. Please try again."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .clientError(let code):
            return "Request error (code: \(code)). Please check your search parameters."
        case .serverError(let code):
            return "Server error (code: \(code)). Please try again later."
        case .invalidDeeplink:
            return "Invalid search result. Please try again."
        case .searchFailed:
            return "Car rental search failed. Please try different dates or location."
        case .apiError(let error):
            return "Search failed: \(error.localizedDescription)"
        }
    }
}
