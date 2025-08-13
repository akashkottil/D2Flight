import Foundation
import Combine

class RentalSearchViewModel: ObservableObject {
    @Published var pickUpIATACode: String = ""
    @Published var dropOffIATACode: String = ""
    @Published var pickUpDate: Date = Date()
    @Published var pickUpTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    @Published var dropOffDate: Date = {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    }()
    @Published var dropOffTime: Date = {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    }()
    @Published var isSameDropOff: Bool = true
    
    @Published var deeplink: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    func searchRentals() {
        guard !pickUpIATACode.isEmpty else {
            errorMessage = "Please select pick-up location."
            return
        }
        
        // For different drop-off, ensure drop-off location is selected
        if !isSameDropOff && dropOffIATACode.isEmpty {
            errorMessage = "Please select drop-off location."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let combinedPickUpDateTime = combineDateAndTime(date: pickUpDate, time: pickUpTime)
        let combinedDropOffDateTime = combineDateAndTime(date: dropOffDate, time: dropOffTime)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        
        let pickUpDateString = dateFormatter.string(from: combinedPickUpDateTime)
        let dropOffDateString = dateFormatter.string(from: combinedDropOffDateTime)
        
        // ✅ UPDATED: Use dynamic parameters (country, currency, language, and user ID will be auto-selected)
        let request = RentalRequest(
            pickUp: pickUpIATACode,
            dropOff: isSameDropOff ? nil : dropOffIATACode,
            pickUpDate: pickUpDateString,
            dropOffDate: dropOffDateString
            // Dynamic country, currency, language, and user ID will be automatically set from APIConstants
        )
        
        print("🚗 Starting rental search with request:")
        print("   Same Drop-off: \(isSameDropOff)")
        print("   Pick-up: \(pickUpIATACode)")
        if !isSameDropOff {
            print("   Drop-off: \(dropOffIATACode)")
        }
        print("   Pick-up Date/Time: \(pickUpDateString)")
        print("   Drop-off Date/Time: \(dropOffDateString)")
        print("   🔧 Using dynamic country: \(request.countryCode)")
        print("   🔧 Using dynamic currency: \(request.currencyCode)")
        print("   🔧 Using dynamic language: \(request.languageCode)")
        print("   🔧 Using dynamic user ID: \(request.userId)")
        
        RentalApi.shared.searchRental(request: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    self?.deeplink = response.deeplink
                    
                    print("✅ Rental search successful!")
                    print("   Deeplink: \(response.deeplink)")
                    
                    // ✅ ADDED: Track successful rental search
                    UserManager.shared.trackRentalSearch()
                    
                case .failure(let error):
                    self?.errorMessage = "Search failed: \(error.localizedDescription)"
                    self?.deeplink = nil
                    
                    print("❌ Rental search failed:")
                    print("   Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        return calendar.date(from: combinedComponents) ?? date
    }
}
