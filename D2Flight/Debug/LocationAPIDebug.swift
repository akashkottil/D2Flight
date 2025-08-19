//
//  ComprehensiveLocationDebug.swift
//  D2Flight
//
//  Complete debug solution for Location API issues
//

import Foundation
import Alamofire

class ComprehensiveLocationDebug {
    
    static func testLocationAPIWithCurrentSettings() {
        print("\n🧪 ===== COMPREHENSIVE LOCATION API TEST =====")
        
        let currentLanguage = LocalizationManager.shared.currentLanguage
        let apiLanguage = APIConstants.getCurrentLanguageCode()
        let apiParams = APIConstants.getAPIParameters()
        
        print("📱 Current App Settings:")
        print("   App Language: \(currentLanguage)")
        print("   API Language: \(apiLanguage)")
        print("   Country: \(apiParams.country)")
        print("   Currency: \(apiParams.currency)")
        
        // Test the actual API call
        testAPICall(query: "A")
    }
    
    private static func testAPICall(query: String) {
        print("\n📡 Testing API Call with query: '\(query)'")
        
        let apiParams = APIConstants.getAPIParameters()
        let url = APIConstants.flightBaseURL + APIConstants.Endpoints.autocomplete
        
        let parameters: [String: Any] = [
            "search": query,
            "country": apiParams.country,
            "language": apiParams.language
        ]
        
        let headers: HTTPHeaders = [
            "accept": APIConstants.Headers.accept
        ]
        
        print("📤 Request Details:")
        print("   URL: \(url)")
        print("   Parameters: \(parameters)")
        print("   Headers: \(headers)")
        
        AF.request(
            url,
            method: .get,
            parameters: parameters,
            headers: headers
        )
        .response { response in
            print("\n📥 Response Analysis:")
            print("   Status Code: \(response.response?.statusCode ?? -1)")
            print("   Content-Type: \(response.response?.allHeaderFields["Content-Type"] ?? "unknown")")
            
            if let data = response.data {
                print("   Data Size: \(data.count) bytes")
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("\n📋 Raw JSON Response:")
                    print(jsonString)
                    
                    // Try to parse as generic JSON first
                    analyzeRawJSON(data: data)
                    
                    // Try our model
                    testLocationResponseDecoding(data: data)
                } else {
                    print("   ❌ Could not convert response to string")
                }
            } else {
                print("   ❌ No response data")
            }
            
            if let error = response.error {
                print("\n❌ Network Error: \(error)")
            }
        }
    }
    
    private static func analyzeRawJSON(data: Data) {
        print("\n🔍 JSON Structure Analysis:")
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("   Root keys: \(Array(json.keys))")
                
                // Check language field specifically
                if let language = json["language"] {
                    print("   Language field type: \(type(of: language))")
                    print("   Language value: \(language)")
                } else {
                    print("   ❌ No 'language' field found")
                }
                
                // Check data field
                if let data = json["data"] as? [[String: Any]] {
                    print("   Data array count: \(data.count)")
                    
                    if let firstItem = data.first {
                        print("   First item keys: \(Array(firstItem.keys))")
                        
                        // Check coordinates specifically
                        if let coordinates = firstItem["coordinates"] as? [String: Any] {
                            print("   Coordinates keys: \(Array(coordinates.keys))")
                            if let lat = coordinates["latitude"] {
                                print("   Latitude type: \(type(of: lat)), value: \(lat)")
                            }
                            if let lon = coordinates["longitude"] {
                                print("   Longitude type: \(type(of: lon)), value: \(lon)")
                            }
                        }
                    }
                } else {
                    print("   ❌ No 'data' array found or wrong format")
                }
            }
        } catch {
            print("   ❌ Failed to parse as generic JSON: \(error)")
        }
    }
    
    private static func testLocationResponseDecoding(data: Data) {
        print("\n🧩 Testing LocationResponse Decoding:")
        
        do {
            let locationResponse = try JSONDecoder().decode(LocationResponse.self, from: data)
            print("   ✅ Successfully decoded LocationResponse!")
            print("   Data count: \(locationResponse.data.count)")
            print("   Language: \(locationResponse.language ?? "nil")")
            
            if let firstLocation = locationResponse.data.first {
                print("   First location: \(firstLocation.displayName)")
                print("   Coordinates: (\(firstLocation.coordinates.latitude), \(firstLocation.coordinates.longitude))")
            }
            
        } catch {
            print("   ❌ LocationResponse decoding failed: \(error)")
            
            if let decodingError = error as? DecodingError {
                printDetailedDecodingError(decodingError)
            }
        }
    }
    
    private static func printDetailedDecodingError(_ error: DecodingError) {
        print("\n🔬 Detailed Decoding Error Analysis:")
        
        switch error {
        case .valueNotFound(let type, let context):
            print("   📍 VALUE NOT FOUND")
            print("     Expected type: \(type)")
            print("     Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("     Description: \(context.debugDescription)")
            
        case .typeMismatch(let type, let context):
            print("   📍 TYPE MISMATCH")
            print("     Expected type: \(type)")
            print("     Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("     Description: \(context.debugDescription)")
            
        case .keyNotFound(let key, let context):
            print("   📍 KEY NOT FOUND")
            print("     Missing key: \(key.stringValue)")
            print("     Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("     Description: \(context.debugDescription)")
            
        case .dataCorrupted(let context):
            print("   📍 DATA CORRUPTED")
            print("     Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("     Description: \(context.debugDescription)")
            
        @unknown default:
            print("   📍 UNKNOWN ERROR: \(error)")
        }
    }
    
    // Test with different language settings
    static func testWithDifferentLanguages() {
        let testLanguages = ["en", "ar", "es", "fr"]
        
        for (index, language) in testLanguages.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index * 3)) {
                print("\n🌐 Testing with language: \(language)")
                LocalizationManager.shared.currentLanguage = language
                testLocationAPIWithCurrentSettings()
            }
        }
    }
}
