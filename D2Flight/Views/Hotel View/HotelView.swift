import SwiftUI
import SafariServices

// MARK: - Updated HotelView with Localized Date Display and Optimized Loading
struct HotelView: View {
    @State private var hotelLocation = ""
    @State private var hotelIATACode = ""
    
    // ✅ UPDATED: Remove the default system formatter and let updateDateTimeLabels handle it
    @State private var checkInDateTime: String = ""
    @State private var checkOutDateTime: String = ""
    
    @State private var guestsCount: String = ""
    
    // Passenger Sheet States
    @State private var showPassengerSheet = false
    @State private var adults = 2
    @State private var children = 0
    @State private var rooms = 1
    @State private var selectedClass: TravelClass = .economy
    
    // Date and Time Selection States
    @State private var navigateToDateTimeSelection = false
    @State private var selectedDates: [Date] = []
    @State private var selectedTimes: [Date] = []
    
    // Location Selection States
    @State private var navigateToLocationSelection = false
    
    // Hotel Search and Navigation States
    @StateObject private var hotelSearchVM = HotelSearchViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showWebView = false
    
    // Recent locations management
    @StateObject private var recentLocationsManager = RecentLocationsManager.shared
    @State private var hasPrefilled = false
    
    //  UPDATED: Remove individual notification states, use WarningManager
    @StateObject private var warningManager = WarningManager.shared
    @State private var lastNetworkStatus = true
    
//    safari services
    @State private var showingSafariView = false
    @State private var selectedURL: String = ""
    @State private var selectedProviderName: String? = nil
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading,spacing: 6) {
                        // Header
                        HStack {
                            Image("HomeLogo")
                                .frame(width: 32, height: 32)
                            Text("Last Minute Flights".localized)
                                .font(CustomFont.font(.large, weight: .bold))
                                .foregroundColor(Color.white)
                        }
                        .padding(.vertical, 10)
                        
                        // Hotel Location Input (Single Input)
                        locationSection
                        
                        // Date & Time Views
                        VStack(spacing: 0) {
                            HStack(spacing: 6) {
                                dateTimeView(
                                    label: formatSelectedDateTime(for: .checkin),
                                    icon: "CalenderIcon",
                                    title: "check-in".localized
                                )
                                .id("checkin_date")
                                
                                dateTimeView(
                                    label: formatSelectedDateTime(for: .checkout),
                                    icon: "CalenderIcon",
                                    title: "check-out".localized
                                )
                                .id("checkout_date")
                            }
                        }
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedDates.count)
                        
                        // Guests Section
                        Button(action: {
                            showPassengerSheet = true
                        }) {
                            HStack {
                                Image("PassengerIcon")
                                    .foregroundColor(.gray)
                                    .frame(width: 22)
                                Text(guestsCount)
                                    .foregroundColor(.gray)
                                    .fontWeight(.medium)
                                    .font(CustomFont.font(.regular))
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // Search Hotels Button
                        PrimaryButton(
                            title: "search.hotels".localized,
                            font: CustomFont.font(.medium),
                            fontWeight: .bold,
                            textColor: .white,
                            verticalPadding: 20,
                            cornerRadius: 16,
                            action: {
                                handleSearchHotels()
                            }
                        )
                    }
                    .padding()
                    .padding(.top, 50)
                    .padding(.bottom, 10)
                    .background(GradientColor.Primary)
                    .cornerRadius(20)
                    
                    PopularLocationsGrid(
                        searchType: .hotel,
                        selectedDates: selectedDates,
                        adults: adults,
                        children: children,
                        infants: 0,
                        selectedClass: .economy,
                        rooms: rooms,
                        onLocationTapped: handlePopularLocationTapped
                    )
                    AutoSlidingCardsView()
                    BottomBar()
                }
                .scrollIndicators(.hidden)
                
                // ✅ UPDATED: Universal Warning Overlay
                WarningOverlay()
            }
            .ignoresSafeArea()
        }
        // ✅ UPDATED: Use NetworkMonitor extension for centralized network handling
        .onReceive(networkMonitor.$isConnected) { isConnected in
            networkMonitor.handleNetworkChange(
                isConnected: isConnected,
                lastNetworkStatus: &lastNetworkStatus
            )
        }
        // ✅ OPTIMIZED: Remove deeplink receiver - web view handles it directly
        .onReceive(hotelSearchVM.$errorMessage) { errorMessage in
            if let error = errorMessage {
                print("⚠️ HotelView received error: \(error)")
            }
        }
        .sheet(isPresented: $showPassengerSheet) {
            PassengerSheet(
                isPresented: $showPassengerSheet,
                adults: $adults,
                children: $children,
                infants: .constant(0),
                rooms: $rooms,
                selectedClass: $selectedClass,
                isFromHotel: true
            ) { updatedGuestsText in
                // ✅ CHANGE: Use the helper function
                guestsCount = formatGuestsText(adults: adults, children: children, rooms: rooms)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $navigateToDateTimeSelection) {
            DateTimeSelectionView(
                selectedDates: $selectedDates,
                selectedTimes: $selectedTimes,
                isFromHotel: true
            ) { updatedDates, updatedTimes in
                selectedDates = updatedDates
                selectedTimes = updatedTimes
                updateDateTimeLabels()
            }
        }
        .fullScreenCover(isPresented: $navigateToLocationSelection) {
            LocationSelectionView(
                originLocation: $hotelLocation,
                destinationLocation: .constant(""),
                isFromHotel: true,
                serviceType: .hotel
            ) { selectedLocation, isOrigin, iataCode in
                hotelLocation = selectedLocation
                hotelIATACode = iataCode
                
                // ✅ CRITICAL: Reset ViewModel state when location changes
                hotelSearchVM.deeplink = nil           // Clear old deeplink
                hotelSearchVM.isLoading = false        // Reset loading state
                hotelSearchVM.errorMessage = nil       // Clear errors
                
                print("🏨 Hotel location selected: \(selectedLocation) (\(iataCode))")
                print("🔄 ViewModel state reset for new location")
            }
        }
        // ✅ OPTIMIZED: Show web view with loading state
        .fullScreenCover(isPresented: $showingSafariView) {
            SafariView(
                url: selectedURL,
                providerName: selectedProviderName,
                providerImageURL: nil
            )
        }
        .onAppear {
            if hotelLocation.isEmpty {
                hasPrefilled = false
            }
            prefillRecentLocationsIfNeeded()
            initializeDateTimes()
            
            if guestsCount.isEmpty {
                guestsCount = formatGuestsText(adults: adults, children: children, rooms: rooms)
            }
        }
    }
    
    // MARK: - Location Section (Single Input)
    private var locationSection: some View {
        Button(action: {
            navigateToLocationSelection = true
        }) {
            VStack(spacing: 1) {
                HStack {
                    Image("DepartureIcon")
                        .frame(width: 20, height: 20)
                    Text(hotelLocation.isEmpty ? "enter.hotel.location".localized : hotelLocation)
                        .foregroundColor(hotelLocation.isEmpty ? .gray : .black)
                        .fontWeight(hotelLocation.isEmpty ? .medium : .bold)
                        .font(CustomFont.font(.regular))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 18)
                .padding(.horizontal)
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // ✅ UPDATED: Date Time View with localized formatting
    func dateTimeView(label: String, icon: String, title: String) -> some View {
        Button(action: {
            navigateToDateTimeSelection = true
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(icon)
                        .frame(width: 16, height: 16)
                    Text(label)
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                        .font(CustomFont.font(.regular))
                    Spacer()
                }
            }
            .padding(.leading)
            .padding(.vertical)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private func handleSearchHotels() {
        print("🏨 Search Hotels button tapped!")
        
        if let warningType = SearchValidationHelper.validateHotelSearch(
            hotelIATACode: hotelIATACode,
            hotelLocation: hotelLocation,
            isConnected: networkMonitor.isConnected
        ) {
            warningManager.showWarning(type: warningType)
            return
        }
        
        saveCurrentSearch()
        
        print("🏨 Hotel search data analysis:")
        print("   hotelLocation: '\(hotelLocation)'")
        print("   hotelIATACode: '\(hotelIATACode)'")
        
        let countryName = extractCountryNameFromLocation(hotelLocation)
        
        print("🏨 Hotel search parameters (debugging):")
        print("   📍 Full Display: '\(hotelLocation)'")
        print("   🏙️ City Name: '\(hotelIATACode)'")
        print("   🌍 Country Name: '\(countryName)'")
        
        // Set ViewModel properties for search
        hotelSearchVM.cityCode = hotelIATACode
        hotelSearchVM.cityName = hotelIATACode
        hotelSearchVM.countryName = countryName
        hotelSearchVM.rooms = rooms
        hotelSearchVM.adults = adults
        hotelSearchVM.children = children
        
        if selectedDates.count > 0 {
            hotelSearchVM.checkinDate = selectedDates[0]
        }
        if selectedDates.count > 1 {
            hotelSearchVM.checkoutDate = selectedDates[1]
        }
        
        // Generate the deeplink for hotel search
        hotelSearchVM.searchHotels()
        
        // Wait for deeplink to be generated, then open SafariView
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let deeplink = hotelSearchVM.deeplink {
                selectedURL = deeplink
                selectedProviderName = "Hotel Search"
                showingSafariView = true
            }
        }
    }

    
    
    private func extractCityNameFromLocation(_ location: String) -> String {
        let components = location.components(separatedBy: ", ")
        return components.first ?? location  // "Dubai"
    }
    
    private func extractCountryNameFromLocation(_ location: String) -> String {
        print("🔍 Extracting country from location: '\(location)'")
        let components = location.components(separatedBy: ", ")
        
        if components.count >= 2 {
            let country = components.last ?? ""
            print("   ✅ Extracted country: '\(country)'")
            return country
        } else {
            print("   ⚠️ No comma found in location, using fallback")
            return "Unknown"
        }
    }
    
    private func handlePopularLocationTapped(_ location: MasonryImage) {
        print("🏨 Popular hotel location tapped: \(location.title) (\(location.iataCode))")
        
        let formattedTitle = LocationDisplayFormatter.formatDisplayName(
            from: location.title,
            type: "city"
        )
        
        hotelLocation = formattedTitle
        hotelIATACode = location.iataCode
        
        print("🏨 Formatted popular location: \(formattedTitle)")
        
        if let warningType = SearchValidationHelper.validateHotelSearch(
            hotelIATACode: location.iataCode,
            hotelLocation: formattedTitle,
            isConnected: networkMonitor.isConnected
        ) {
            warningManager.showWarning(type: warningType)
            return
        }
        
        savePopularHotelSearch(location: location)
        
        // Update ViewModel properties
        hotelSearchVM.cityCode = location.iataCode
        hotelSearchVM.cityName = location.iataCode
        hotelSearchVM.rooms = rooms
        hotelSearchVM.adults = adults
        hotelSearchVM.children = children
        
        if selectedDates.count > 0 {
            hotelSearchVM.checkinDate = selectedDates[0]
        } else {
            hotelSearchVM.checkinDate = Date()
        }
        
        if selectedDates.count > 1 {
            hotelSearchVM.checkoutDate = selectedDates[1]
        } else {
            hotelSearchVM.checkoutDate = Calendar.current.date(byAdding: .day, value: 1, to: hotelSearchVM.checkinDate) ?? Date()
        }
        
        // Generate the deeplink for hotel search
        hotelSearchVM.searchHotels()
        
        // Wait for deeplink to be generated, then open SafariView
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let deeplink = hotelSearchVM.deeplink {
                selectedURL = deeplink
                selectedProviderName = "Hotel Search"
                showingSafariView = true
            }
        }
    }
    
    // MARK: - Helper Methods
    enum HotelDateType {
        case checkin, checkout
    }
    
    // ✅ UPDATED: Use LocalizedDateFormatter for date/time formatting
    private func formatSelectedDateTime(for type: HotelDateType) -> String {
        switch type {
        case .checkin:
            if selectedDates.count > 0 && selectedTimes.count > 0 {
                let combinedDateTime = combineDateAndTime(date: selectedDates[0], time: selectedTimes[0])
                return formatLocalizedDateTime(combinedDateTime)
            }
            return calculateDefaultCheckinDateTime()
            
        case .checkout:
            if selectedDates.count > 1 && selectedTimes.count > 1 {
                let combinedDateTime = combineDateAndTime(date: selectedDates[1], time: selectedTimes[1])
                return formatLocalizedDateTime(combinedDateTime)
            }
            return calculateDefaultCheckoutDateTime()
        }
    }
    
    // ✅ NEW: Format date with localized weekday and month
    private func formatLocalizedDateTime(_ date: Date) -> String {
        let calendar = Calendar.current
        
        // Get weekday index (0 = Sunday, 1 = Monday, etc.)
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        let localizedWeekday = CalendarLocalization.getLocalizedWeekdayName(for: weekdayIndex)
        
        // Get day number
        let dayNumber = calendar.component(.day, from: date)
        
        // Get month using custom localization
        let localizedMonth = CalendarLocalization.getLocalizedMonthName(for: date, isShort: true)
        
        // Get time
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        return "\(localizedWeekday) \(dayNumber) \(localizedMonth), \(String(format: "%02d:%02d", hour, minute))"
    }
    
    private func calculateDefaultCheckinDateTime() -> String {
        let today = Date()
        let defaultTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: today) ?? today
        return formatLocalizedDateTime(defaultTime)
    }
    
    private func calculateDefaultCheckoutDateTime() -> String {
        let baseCheckinDate: Date
        if selectedDates.count > 0 {
            baseCheckinDate = selectedDates[0]
        } else {
            baseCheckinDate = Date()
        }
        
        let checkoutDate = Calendar.current.date(byAdding: .day, value: 1, to: baseCheckinDate) ?? baseCheckinDate
        let defaultTime = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: checkoutDate) ?? checkoutDate
        return formatLocalizedDateTime(defaultTime)
    }
    
    private func initializeDateTimes() {
        if !selectedDates.isEmpty && !selectedTimes.isEmpty {
            updateDateTimeLabels()
        } else {
            // Initialize with default values using localized formatting
            checkInDateTime = calculateDefaultCheckinDateTime()
            checkOutDateTime = calculateDefaultCheckoutDateTime()
        }
        
        print("📅 HotelView initializeDateTimes completed")
    }
    
    private func updateDateTimeLabels() {
        if selectedDates.count > 0 && selectedTimes.count > 0 {
            let combinedCheckInDateTime = combineDateAndTime(date: selectedDates[0], time: selectedTimes[0])
            checkInDateTime = formatLocalizedDateTime(combinedCheckInDateTime)
        }
        
        if selectedDates.count > 1 && selectedTimes.count > 1 {
            let combinedCheckOutDateTime = combineDateAndTime(date: selectedDates[1], time: selectedTimes[1])
            checkOutDateTime = formatLocalizedDateTime(combinedCheckOutDateTime)
        } else {
            checkOutDateTime = calculateDefaultCheckoutDateTime()
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
    
    private func prefillRecentLocationsIfNeeded() {
        guard !hasPrefilled, hotelLocation.isEmpty else {
            return
        }
        
        let recentPairs = recentLocationsManager.getRecentSearchPairs()
        let hotelPairs = recentPairs.filter { pair in
            return pair.origin.iataCode == pair.destination.iataCode ||
                   pair.origin.type == "city"
        }
        
        if let lastHotelPair = hotelPairs.first {
            // ✅ UPDATED: Use formatted display name
            let originalDisplayName = lastHotelPair.origin.displayName
            let formattedDisplayName = LocationDisplayFormatter.formatDisplayName(
                from: originalDisplayName,
                type: lastHotelPair.origin.type
            )
            
            hotelLocation = formattedDisplayName
            hotelIATACode = lastHotelPair.origin.iataCode
            hasPrefilled = true
            print("✅ HotelView: Auto-prefilled from hotel searches")
            print("   Original: \(originalDisplayName)")
            print("   Formatted: \(formattedDisplayName)")
        } else if let anyRecentPair = recentPairs.first {
            // ✅ UPDATED: Use formatted display name
            let originalDisplayName = anyRecentPair.origin.displayName
            let formattedDisplayName = LocationDisplayFormatter.formatDisplayName(
                from: originalDisplayName,
                type: anyRecentPair.origin.type
            )
            
            hotelLocation = formattedDisplayName
            hotelIATACode = anyRecentPair.origin.iataCode
            hasPrefilled = true
            print("✅ HotelView: Auto-prefilled from any recent search")
            print("   Original: \(originalDisplayName)")
            print("   Formatted: \(formattedDisplayName)")
        }
    }
    
    private func saveCurrentSearch() {
        // ✅ UPDATED: Save with formatted display name but preserve original for data
        let hotelLocationObj = Location(
            iataCode: hotelIATACode,
            airportName: hotelLocation,
            type: "city", // Hotel locations are typically saved as city type
            displayName: hotelLocation, // Use the formatted name that's already clean
            cityName: hotelIATACode, // Usually the city code
            countryName: extractCountryNameFromLocation(hotelLocation),
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        recentLocationsManager.addSearchPair(origin: hotelLocationObj, destination: hotelLocationObj)
        print("💾 HotelView: Saved hotel search with formatted name: \(hotelLocation)")
    }
    
    private func savePopularHotelSearch(location: MasonryImage) {
        // ✅ UPDATED: Format the location title before saving
        let formattedTitle = LocationDisplayFormatter.formatDisplayName(
            from: location.title,
            type: "city" // Popular locations are typically cities
        )
        
        let hotelLocationObj = Location(
            iataCode: location.iataCode,
            airportName: formattedTitle,
            type: "city",
            displayName: formattedTitle,
            cityName: location.iataCode, // Use iataCode as city name for consistency
            countryName: extractCountryNameFromLocation(formattedTitle),
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        recentLocationsManager.addSearchPair(origin: hotelLocationObj, destination: hotelLocationObj)
        print("💾 Saved popular hotel search with formatted name: \(formattedTitle)")
    }
    
    private func formatGuestsText(adults: Int, children: Int, rooms: Int) -> String {
        let totalGuests = adults + children
        let guestsText = totalGuests == 1 ?
            "\(totalGuests) \("guest".localized)" :
            "\(totalGuests) \("guests".localized)"
        let roomsText = rooms == 1 ?
            "\(rooms) \("room".localized)" :
            "\(rooms) \("rooms".localized)"
        return "\(guestsText), \(roomsText)"
    }
}




#Preview {
    HotelView()
}
