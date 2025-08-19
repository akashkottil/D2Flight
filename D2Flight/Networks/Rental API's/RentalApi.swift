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
        
        // ✅ FIXED: Get dynamic language for consistency check
        let apiParams = APIConstants.getAPIParameters()
        
        var parameters: [String: Any] = [
            "country_code": request.countryCode,
            "app_code": request.appCode,
            "pick_up": request.pickUp,
            "pick_up_date": request.pickUpDate,
            "drop_off_date": request.dropOffDate,
            "currency_code": request.currencyCode,
            "language_code": request.languageCode,  // ✅ Already has language - verify it's dynamic
            "user_id": request.userId
        ]
        
        // Add drop_off parameter only if it's provided (for different drop-off)
        if let dropOff = request.dropOff {
            parameters["drop_off"] = dropOff
        }
        
        let headers: HTTPHeaders = [
            "accept": APIConstants.Headers.htmlAccept,
            // ✅ ADDED: Language header for consistency
            "Accept-Language": request.languageCode,
            // ✅ ADDED: Country header
            "country": request.countryCode
        ]
        
        print("🚗 Rental API Request with dynamic language:")
        print("   URL: \(url)")
        print("   🌐 Language Code: \(request.languageCode)")
        print("   🌐 API Language: \(apiParams.language)")
        print("   💰 Currency Code: \(request.currencyCode)")
        print("   🌍 Country Code: \(request.countryCode)")
        print("   Parameters: \(parameters)")
        print("   Headers: \(headers)")
        
        // ✅ VERIFICATION: Check if request language matches current dynamic language
        if request.languageCode != apiParams.language {
            print("⚠️ WARNING: Request language (\(request.languageCode)) differs from current API language (\(apiParams.language))")
        } else {
            print("✅ Language consistency verified: \(request.languageCode)")
        }
        
        AF.request(
            url,
            method: .get,
            parameters: parameters,
            headers: headers
        )
        // Remove validation since we expect HTML, not JSON
        .response { response in
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
                
                // If we got HTML data, try to extract any redirect URL from it
                if let htmlData = data,
                   let htmlString = String(data: htmlData, encoding: .utf8) {
                    
                    // Look for meta refresh or JavaScript redirects
                    if let redirectURL = self.extractRedirectURL(from: htmlString) {
                        finalURL = redirectURL
                        print("✅ Extracted redirect URL from HTML: \(finalURL)")
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
                completion(.failure(error))
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
}
