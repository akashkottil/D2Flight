import Foundation

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
    
    // Computed properties for formatted display
    var formattedTravelDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        
        if isRoundTrip, let returnDate = returnDate {
            return "\(formatter.string(from: departureDate)) - \(formatter.string(from: returnDate))"
        } else {
            return formatter.string(from: departureDate)
        }
    }
    
    var formattedTravelerInfo: String {
        let totalTravelers = adults + children + infants
        let travelerText = totalTravelers == 1 ? "Traveler" : "Travelers"
        return "\(totalTravelers) \(travelerText), \(selectedClass.displayName)"
    }
    
    var routeDisplayText: String {
        return "\(originCode) to \(destinationCode)"
    }
    
    // Initialize with default values for preview/testing
    init(
        originCode: String = "",
        destinationCode: String = "",
        originName: String = "",
        destinationName: String = "",
        isRoundTrip: Bool = false,
        departureDate: Date = Date(),
        returnDate: Date? = nil,
        adults: Int = 1,
        children: Int = 0,
        infants: Int = 0,
        selectedClass: TravelClass = .economy
    ) {
        self.originCode = originCode
        self.destinationCode = destinationCode
        self.originName = originName
        self.destinationName = destinationName
        self.isRoundTrip = isRoundTrip
        self.departureDate = departureDate
        self.returnDate = returnDate
        self.adults = adults
        self.children = children
        self.infants = infants
        self.selectedClass = selectedClass
    }
}
