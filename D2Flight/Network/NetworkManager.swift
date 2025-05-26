import Foundation

// MARK: - Network Manager
class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Generic Request Method
    func request<T: Codable>(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String]? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            // Decode response
            let decoder = JSONDecoder()
            let result = try decoder.decode(responseType, from: data)
            return result
            
        } catch let error as DecodingError {
            throw NetworkError.decodingError(error)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }
    
    // MARK: - GET Request Helper
    func get<T: Codable>(
        url: URL,
        headers: [String: String]? = nil,
        responseType: T.Type
    ) async throws -> T {
        return try await request(
            url: url,
            method: .GET,
            headers: headers,
            responseType: responseType
        )
    }
    
    // MARK: - POST Request Helper
    func post<T: Codable>(
        url: URL,
        body: Data? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type
    ) async throws -> T {
        return try await request(
            url: url,
            method: .POST,
            headers: headers,
            body: body,
            responseType: responseType
        )
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(Int)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
