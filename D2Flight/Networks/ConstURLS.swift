import Foundation

// MARK: - DEPRECATED - Use APIConstants instead
// This file is kept for backward compatibility
// Gradually migrate to APIConstants for better organization

struct APIEndpoints {
    static let baseURL = APIConstants.flightBaseURL
    static let autocomplete = APIConstants.Endpoints.autocomplete
}
