//
//  User.swift
//  D2Flight
//
//  Created by Akash Kottil on 05/08/25.
//


import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let profileImageURL: String?
    let provider: AuthProvider
    let createdAt: Date
    let lastLoginAt: Date
    
    enum AuthProvider: String, Codable, CaseIterable {
        case google = "google"
        case facebook = "facebook"
        case apple = "apple"
        case email = "email"
        
        var displayName: String {
            switch self {
            case .google: return "Google"
            case .facebook: return "Facebook"
            case .apple: return "Apple"
            case .email: return "Email"
            }
        }
    }
}

struct AuthResponse: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String?
    let expiresIn: TimeInterval
}

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError
    case userCancelled
    case configurationError
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials provided"
        case .networkError:
            return "Network connection failed"
        case .userCancelled:
            return "Sign in was cancelled"
        case .configurationError:
            return "Authentication configuration error"
        case .unknownError(let message):
            return message
        }
    }
}