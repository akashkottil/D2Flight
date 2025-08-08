//
//  WarningType.swift
//  D2Flight
//
//  Created by Akash Kottil on 08/08/25.
//
import SwiftUI

// MARK: - Universal Warning Types
enum WarningType {
    case noInternet
    case emptySearch
    case sameLocation
    
    var message: String {
        switch self {
        case .noInternet:
            return "No Internet connection. Try reconnecting"
        case .emptySearch:
            return "Select location to search flight"
        case .sameLocation:
            return "Try different locations"
        }
    }
    
    var icon: String {
        switch self {
        case .noInternet:
            return "wifi.slash"
        case .emptySearch:
            return "exclamationmark.triangle.fill"
        case .sameLocation:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Universal Warning Component
struct UniversalWarning: View {
    let warningType: WarningType
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            Image(systemName: warningType.icon)
                .foregroundColor(.black)
                .font(CustomFont.font(.medium))
            
            Text(warningType.message)
                .font(CustomFont.font(.regular, weight: .medium))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.yellow)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .onAppear {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
            
            // Auto dismiss after 3 seconds (except for no internet which needs manual dismiss)
            if warningType != .noInternet {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVisible = false
                    }
                }
            }
        }
    }
}

// MARK: - Warning Manager (ObservableObject for global state)
class WarningManager: ObservableObject {
    @Published var activeWarning: WarningType? = nil
    @Published var showWarning = false
    
    static let shared = WarningManager()
    private init() {}
    
    func showWarning(type: WarningType) {
        activeWarning = type
        withAnimation(.easeInOut(duration: 0.3)) {
            showWarning = true
        }
        
        print("⚠️ Showing warning: \(type.message)")
    }
    
    func hideWarning() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showWarning = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.activeWarning = nil
        }
    }
}

// MARK: - Warning Overlay View (Reusable Component)
struct WarningOverlay: View {
    @ObservedObject var warningManager = WarningManager.shared
    
    var body: some View {
        VStack {
            Spacer()
            
            if warningManager.showWarning, let warningType = warningManager.activeWarning {
                UniversalWarning(
                    warningType: warningType,
                    isVisible: $warningManager.showWarning
                )
                .padding(.bottom, 100) // Adjust based on your layout needs
            }
        }
        .animation(.easeInOut(duration: 0.3), value: warningManager.showWarning)
    }
}

// MARK: - Search Validation Helper
struct SearchValidationHelper {
    
    // Validate flight search
    static func validateFlightSearch(
        originIATACode: String,
        destinationIATACode: String,
        originLocation: String,
        destinationLocation: String,
        isConnected: Bool
    ) -> WarningType? {
        
        // Check internet connection first
        if !isConnected {
            return .noInternet
        }
        
        // Check if both locations are selected
        if originIATACode.isEmpty || destinationIATACode.isEmpty {
            return .emptySearch
        }
        
        // Check if same locations are selected
        if originIATACode == destinationIATACode {
            return .sameLocation
        }
        
        return nil // No validation errors
    }
    
    // Validate rental search
    static func validateRentalSearch(
        pickUpIATACode: String,
        dropOffIATACode: String,
        pickUpLocation: String,
        dropOffLocation: String,
        isSameDropOff: Bool,
        isConnected: Bool
    ) -> WarningType? {
        
        // Check internet connection first
        if !isConnected {
            return .noInternet
        }
        
        // Check if pickup location is selected
        if pickUpIATACode.isEmpty {
            return .emptySearch
        }
        
        // For different drop-off, check if drop-off location is selected
        if !isSameDropOff && dropOffIATACode.isEmpty {
            return .emptySearch
        }
        
        // For different drop-off, check if same locations are selected
        if !isSameDropOff && pickUpIATACode == dropOffIATACode {
            return .sameLocation
        }
        
        return nil // No validation errors
    }
    
    // Validate hotel search
    static func validateHotelSearch(
        hotelIATACode: String,
        hotelLocation: String,
        isConnected: Bool
    ) -> WarningType? {
        
        // Check internet connection first
        if !isConnected {
            return .noInternet
        }
        
        // Check if hotel location is selected
        if hotelIATACode.isEmpty {
            return .emptySearch
        }
        
        return nil // No validation errors
    }
}

// MARK: - Network Monitor Integration
extension NetworkMonitor {
    func handleNetworkChange(isConnected: Bool, lastNetworkStatus: inout Bool) {
        if lastNetworkStatus && !isConnected {
            WarningManager.shared.showWarning(type: .noInternet)
        } else if !lastNetworkStatus && isConnected {
            // Network restored - hide warning if it's a network warning
            if WarningManager.shared.activeWarning == .noInternet {
                WarningManager.shared.hideWarning()
            }
        }
        lastNetworkStatus = isConnected
    }
}
