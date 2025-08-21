import SwiftUI

// MARK: - Updated HotelView with Localized Date Display
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
    @State private var currentDeeplink: String? = nil
    
    // Recent locations management
    @StateObject private var recentLocationsManager = RecentLocationsManager.shared
    @State private var hasPrefilled = false
    
    // ✅ UPDATED: Remove individual notification states, use WarningManager
    @StateObject private var warningManager = WarningManager.shared
    @State private var lastNetworkStatus = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading) {
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
                    .padding(.bottom, 30)
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
        // Handle search results
        .onReceive(hotelSearchVM.$deeplink) { deeplink in
            if let deeplink = deeplink {
                currentDeeplink = deeplink
                showWebView = true
                print("🔗 HotelView received deeplink: \(deeplink)")
            }
        }
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
                isFromHotel: true
            ) { selectedLocation, isOrigin, iataCode in
                hotelLocation = selectedLocation
                hotelIATACode = iataCode
                print("🏨 Hotel location selected: \(selectedLocation) (\(iataCode))")
            }
        }
        .sheet(isPresented: $showWebView) {
            if let deeplink = currentDeeplink {
                HotelWebView(url: deeplink)
            }
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
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Search Handler with Universal Validation
    private func handleSearchHotels() {
        print("🏨 Search Hotels button tapped!")
        
        // ✅ Use SearchValidationHelper for validation
        if let warningType = SearchValidationHelper.validateHotelSearch(
            hotelIATACode: hotelIATACode,
            hotelLocation: hotelLocation,
            isConnected: networkMonitor.isConnected
        ) {
            warningManager.showWarning(type: warningType)
            return
        }
        
        // Save current search
        saveCurrentSearch()
        
        // Update ViewModel properties
        hotelSearchVM.cityCode = hotelIATACode
        hotelSearchVM.cityName = hotelLocation
        hotelSearchVM.rooms = rooms
        hotelSearchVM.adults = adults
        hotelSearchVM.children = children
        
        if selectedDates.count > 0 {
            hotelSearchVM.checkinDate = selectedDates[0]
        }
        if selectedDates.count > 1 {
            hotelSearchVM.checkoutDate = selectedDates[1]
        }
        
        print("🎯 Hotel search parameters validated and starting search")
        
        // Start the search
        hotelSearchVM.searchHotels()
    }
    
    // ✅ UPDATED: Popular Location Handler with Universal Validation
    private func handlePopularLocationTapped(_ location: MasonryImage) {
        print("🏨 Popular hotel location tapped: \(location.title) (\(location.iataCode))")
        
        // Set hotel location to popular location
        hotelLocation = location.title
        hotelIATACode = location.iataCode
        
        // ✅ Use SearchValidationHelper for validation
        if let warningType = SearchValidationHelper.validateHotelSearch(
            hotelIATACode: location.iataCode,
            hotelLocation: location.title,
            isConnected: networkMonitor.isConnected
        ) {
            warningManager.showWarning(type: warningType)
            return
        }
        
        // Save search for recent locations
        savePopularHotelSearch(location: location)
        
        // Update ViewModel properties
        hotelSearchVM.cityCode = location.iataCode
        hotelSearchVM.cityName = location.title
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
        
        print("🎯 Popular hotel search validated and starting")
        
        // Start the hotel search
        hotelSearchVM.searchHotels()
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
            hotelLocation = lastHotelPair.origin.displayName
            hotelIATACode = lastHotelPair.origin.iataCode
            hasPrefilled = true
            print("✅ HotelView: Auto-prefilled from hotel searches")
        } else if let anyRecentPair = recentPairs.first {
            hotelLocation = anyRecentPair.origin.displayName
            hotelIATACode = anyRecentPair.origin.iataCode
            hasPrefilled = true
            print("✅ HotelView: Auto-prefilled from any recent search")
        }
    }
    
    private func saveCurrentSearch() {
        let hotelLocationObj = Location(
            iataCode: hotelIATACode,
            airportName: hotelLocation,
            type: "city",
            displayName: hotelLocation,
            cityName: hotelLocation,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        recentLocationsManager.addSearchPair(origin: hotelLocationObj, destination: hotelLocationObj)
        print("💾 HotelView: Saved hotel search: \(hotelLocation)")
    }
    
    private func savePopularHotelSearch(location: MasonryImage) {
        let hotelLocationObj = Location(
            iataCode: location.iataCode,
            airportName: location.title,
            type: "city",
            displayName: location.title,
            cityName: location.title,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        recentLocationsManager.addSearchPair(origin: hotelLocationObj, destination: hotelLocationObj)
        print("💾 Saved popular hotel search: \(location.title)")
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
