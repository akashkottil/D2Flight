import SwiftUI

// MARK: - Universal Warning Types
enum WarningType {
    case noInternet
    case emptySearch
    case sameLocation
    case hotelSearchError
    case rentalSearchError
    case deeplinkError
    case searchTimeout
    
    var message: String {
        switch self {
        case .noInternet:
            return "no.internet.connection.try.reconnecting".localized
        case .emptySearch:
            return "select.location.to.search.flight".localized
        case .sameLocation:
            return "try.different.locations".localized
        case .hotelSearchError:
            return "hotel.search.failed.try.again".localized
        case .rentalSearchError:
            return "rental.search.failed.try.again".localized
        case .deeplinkError:
            return "search.failed.please.try.again".localized
        case .searchTimeout:
            return "search.taking.too.long.please.try.again".localized
        }
    }
    
    var icon: String {
        switch self {
        case .noInternet:
            return "wifi.slash"
        case .emptySearch, .sameLocation:
            return "exclamationmark.triangle.fill"
        case .hotelSearchError:
            return "bed.double.fill"
        case .rentalSearchError:
            return "car.fill"
        case .deeplinkError, .searchTimeout:
            return "exclamationmark.circle.fill"
        }
    }
    
    // NEW: Auto-dismiss behavior configuration
    var shouldAutoDismiss: Bool {
        switch self {
        case .noInternet:
            return false // Keep showing until network is restored
        case .emptySearch, .sameLocation:
            return true // Auto-dismiss after 3 seconds
        case .hotelSearchError, .rentalSearchError, .deeplinkError, .searchTimeout:
            return true // Auto-dismiss after 4 seconds for error messages
        }
    }
    
    var autoDismissDelay: TimeInterval {
        switch self {
        case .emptySearch, .sameLocation:
            return 3.0
        case .hotelSearchError, .rentalSearchError, .deeplinkError, .searchTimeout:
            return 4.0
        default:
            return 3.0
        }
    }
}

// MARK: - Universal Warning Component (Updated with better error handling)
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
            
            // Auto dismiss based on warning type configuration
            if warningType.shouldAutoDismiss {
                DispatchQueue.main.asyncAfter(deadline: .now() + warningType.autoDismissDelay) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVisible = false
                    }
                }
            }
        }
    }
}

// MARK: - Warning Manager (Enhanced with error tracking)
class WarningManager: ObservableObject {
    @Published var activeWarning: WarningType? = nil
    @Published var showWarning = false
    
    static let shared = WarningManager()
    private init() {}
    
    func showWarning(type: WarningType) {
        // If there's already a warning showing, dismiss it first
        if showWarning {
            hideWarning()
            // Small delay before showing new warning
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.displayWarning(type: type)
            }
        } else {
            displayWarning(type: type)
        }
    }
    
    private func displayWarning(type: WarningType) {
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
    
    // NEW: Show deeplink-specific errors
    func showDeeplinkError(for searchType: SearchType, error: Error? = nil) {
        let warningType: WarningType
        
        switch searchType {
        case .hotel:
            warningType = .hotelSearchError
        case .rental:
            warningType = .rentalSearchError
        case .flight:
            warningType = .deeplinkError
        }
        
        if let error = error {
            print("🔗 Deeplink error for \(searchType): \(error.localizedDescription)")
        }
        
        showWarning(type: warningType)
    }
    
    // NEW: Show timeout errors
    func showTimeoutError() {
        showWarning(type: .searchTimeout)
    }
}



// MARK: - Warning Overlay View (Enhanced)
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

// MARK: - Search Validation Helper (Enhanced with deeplink validation)
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
    
    // NEW: Validate deeplink response
    static func validateDeeplink(_ deeplink: String?) -> Bool {
        guard let deeplink = deeplink,
              !deeplink.isEmpty,
              URL(string: deeplink) != nil else {
            return false
        }
        return true
    }
}

// MARK: - Network Monitor Integration (Enhanced)
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
