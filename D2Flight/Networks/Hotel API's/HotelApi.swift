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
        
        var parameters: [String: Any] = [
            "country": request.country,
            "user_id": request.userId,
            "city_name": request.cityName,
            "country_name": request.countryName,
            "checkin": request.checkin,
            "checkout": request.checkout,
            "rooms": request.rooms,
            "adults": request.adults
        ]
        
        // Add children parameter only if it's provided and greater than 0
        if let children = request.children, children > 0 {
            parameters["children"] = children
        }
        
        let headers: HTTPHeaders = [
            "accept": APIConstants.Headers.accept,
            "X-CSRFTOKEN": APIConstants.CSRFTokens.hotel
        ]
        
        print("🏨 Hotel API Request:")
        print("URL: \(url)")
        print("Parameters: \(parameters)")
        print("Headers: \(headers)")
        
        AF.request(
            url,
            method: .get,
            parameters: parameters,
            headers: headers
        )
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
                
                let hotelResponse = HotelResponse(
                    deeplink: finalURL,
                    status: "success",
                    message: "Hotel search URL generated successfully"
                )
                
                print("✅ Hotel search successful!")
                print("   Final URL: \(finalURL)")
                completion(.success(hotelResponse))
                
            case .failure(let error):
                print("❌ Hotel search failed: \(error)")
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
