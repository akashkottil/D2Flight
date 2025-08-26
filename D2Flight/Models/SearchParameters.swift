// FILE: D2Flight/Models/SearchParameters.swift (CREATE THIS FILE)

import Foundation

// MARK: - SearchParameters Model
struct SearchParameters {
    let originCode: String
    let destinationCode: String
    let originName: String
    let destinationName: String
    let isRoundTrip: Bool
    let departureDate: Date
    let returnDate: Date?
    let adults: Int
    let children: Int
    let infants: Int
    let selectedClass: TravelClass
}

// MARK: - SearchParameters Localized Extensions
extension SearchParameters {
    /// Returns localized formatted travel date
    var formattedTravelDate: String {
        if isRoundTrip, let returnDate = returnDate {
            let departureString = LocalizedDateFormatter.formatShortDate(departureDate)
            let returnString = LocalizedDateFormatter.formatShortDate(returnDate)
            return "\(departureString) - \(returnString)"
        } else {
            return LocalizedDateFormatter.formatShortDate(departureDate)
        }
    }
    
    /// Returns localized formatted traveler information
    var formattedTravelerInfo: String {
        let totalTravelers = adults + children + infants
        let travelerText = totalTravelers == 1 ?
            "traveller".localized :
            "travellers".localized
        return "\(totalTravelers) \(travelerText), \(selectedClass.localizedDisplayName)"
    }
}

// MARK: - TravelClass Localized Extension
extension TravelClass {
    /// Returns localized display name for travel class
    var localizedDisplayName: String {
        switch self {
        case .economy:
            return "economy".localized
        case .premiumEconomy:
            return "premium.economy".localized
        case .business:
            return "business".localized
        case .firstClass:
            return "first.class".localized
        }
    }
}
