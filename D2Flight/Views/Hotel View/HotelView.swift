import SwiftUI

struct HotelView: View {
    @State private var hotelLocation = ""
    @State private var hotelIATACode = ""
    
    @State private var checkInDateTime: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM, HH:mm"
        let defaultTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: defaultTime)
    }()
    
    @State private var checkOutDateTime: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM, HH:mm"
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let defaultTime = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        return formatter.string(from: defaultTime)
    }()
    
    @State private var guestsCount = "2 Guests, 1 Room"
    
    // Passenger Sheet States
    @State private var showPassengerSheet = false
    @State private var adults = 2
    @State private var children = 0
    @State private var rooms = 1
    @State private var selectedClass: TravelClass = .economy // Not used for hotel but kept for compatibility
    
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
    
    // Notification States
    @State private var showNoInternet = false
    @State private var showEmptySearch = false
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
                            Text("Last Minute Flights")
                                .font(CustomFont.font(.large, weight: .bold))
                                .foregroundColor(Color.white)
                        }
                        .padding(.vertical, 10)
                        
                        // Hotel Location Input (Single Input)
                        locationSection
                        
                        // UPDATED: Two separate Date & Time Views (like original design)
                        VStack(spacing: 0) {
                            HStack(spacing: 10) {
                                // Check-in Date & Time
                                dateTimeView(
                                    label: formatSelectedDateTime(for: .checkin),
                                    icon: "CalenderIcon",
                                    title: "Check-in"
                                )
                                .id("checkin_date")
                                
                                // Check-out Date & Time
                                dateTimeView(
                                    label: formatSelectedDateTime(for: .checkout),
                                    icon: "CalenderIcon",
                                    title: "Check-out"
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
                            title: "Search Hotels",
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
                                        infants: 0, // Not used for hotels
                                        selectedClass: .economy, // Not used for hotels
                                        rooms: rooms,
                                        onLocationTapped: handlePopularLocationTapped
                                    )
                }
                .scrollIndicators(.hidden)
                

                
                // Notification Components Overlay
                VStack {
                    Spacer()
                    
                    if showNoInternet {
                        NoInternet(isVisible: $showNoInternet)
                            .padding(.bottom, 100)
                    }
                    
                    if showEmptySearch {
                        EmptySearch(isVisible: $showEmptySearch)
                            .padding(.bottom, 100)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: showNoInternet)
                .animation(.easeInOut(duration: 0.3), value: showEmptySearch)
            }
            .ignoresSafeArea()
        }
        // Network monitoring
        .onReceive(networkMonitor.$isConnected) { isConnected in
            if lastNetworkStatus && !isConnected {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showNoInternet = true
                    showEmptySearch = false
                }
            }
            lastNetworkStatus = isConnected
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
                infants: .constant(0), // Not used for hotels
                rooms: $rooms,
                selectedClass: $selectedClass,
                isFromHotel: true
            ) { updatedGuestsText in
                guestsCount = updatedGuestsText
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        // DateTimeSelectionView - Both buttons open the same view
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
                destinationLocation: .constant(""), // Not used for hotel
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
            // Reset prefill state when view appears fresh
            if hotelLocation.isEmpty {
                hasPrefilled = false
            }
            prefillRecentLocationsIfNeeded()
            initializeDateTimes()
        }
    }
    
    // MARK: - Location Section (Single Input)
    private var locationSection: some View {
        Button(action: {
            navigateToLocationSelection = true
        }) {
            VStack(spacing: 1) {
                HStack {
                    Image("HotelIcon") // Use hotel-specific icon
                        .frame(width: 20, height: 20)
                    Text(hotelLocation.isEmpty ? "Enter Hotel Location" : hotelLocation)
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
    
    // UPDATED: Individual Date Time View (with title)
    func dateTimeView(label: String, icon: String, title: String) -> some View {
        Button(action: {
            navigateToDateTimeSelection = true
        }) {
            VStack(alignment: .leading, spacing: 4) {
//                Text(title)
//                    .font(CustomFont.font(.small, weight: .medium))
//                    .foregroundColor(.gray)
                
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
    
    // MARK: - Helper Methods
    enum HotelDateType {
        case checkin, checkout
    }
    
    private func formatSelectedDateTime(for type: HotelDateType) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM, HH:mm"
        
        switch type {
        case .checkin:
            if selectedDates.count > 0 && selectedTimes.count > 0 {
                let combinedDateTime = combineDateAndTime(date: selectedDates[0], time: selectedTimes[0])
                return formatter.string(from: combinedDateTime)
            }
            return calculateDefaultCheckinDateTime()
            
        case .checkout:
            if selectedDates.count > 1 && selectedTimes.count > 1 {
                let combinedDateTime = combineDateAndTime(date: selectedDates[1], time: selectedTimes[1])
                return formatter.string(from: combinedDateTime)
            }
            return calculateDefaultCheckoutDateTime()
        }
    }
    
    private func calculateDefaultCheckinDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM, HH:mm"
        
        // Use today with 3 PM as default check-in
        let today = Date()
        let defaultTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: today) ?? today
        return formatter.string(from: defaultTime)
    }
    
    private func calculateDefaultCheckoutDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM, HH:mm"
        
        // Use selected check-in date if available, otherwise use current date
        let baseCheckinDate: Date
        if selectedDates.count > 0 {
            baseCheckinDate = selectedDates[0]
        } else {
            baseCheckinDate = Date()
        }
        
        // Add 1 day to the check-in date for check-out, with 11 AM time
        let checkoutDate = Calendar.current.date(byAdding: .day, value: 1, to: baseCheckinDate) ?? baseCheckinDate
        let defaultTime = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: checkoutDate) ?? checkoutDate
        return formatter.string(from: defaultTime)
    }
    
    private func initializeDateTimes() {
        // Don't set defaults here - let DateTimeSelectionView handle smart defaults
        // Only update labels if we have existing selected data
        if !selectedDates.isEmpty && !selectedTimes.isEmpty {
            updateDateTimeLabels()
        }
        
        print("📅 HotelView initializeDateTimes completed")
    }
    
    private func updateDateTimeLabels() {
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "E dd MMM, HH:mm"
        
        if selectedDates.count > 0 && selectedTimes.count > 0 {
            let combinedCheckInDateTime = combineDateAndTime(date: selectedDates[0], time: selectedTimes[0])
            checkInDateTime = dateTimeFormatter.string(from: combinedCheckInDateTime)
        }
        
        if selectedDates.count > 1 && selectedTimes.count > 1 {
            let combinedCheckOutDateTime = combineDateAndTime(date: selectedDates[1], time: selectedTimes[1])
            checkOutDateTime = dateTimeFormatter.string(from: combinedCheckOutDateTime)
        } else {
            // Update checkout based on new checkin date
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
        guard !hasPrefilled,
              hotelLocation.isEmpty else {
            print("🚫 HotelView: Skipping prefill - already prefilled or location not empty")
            return
        }
        
        // Only prefill from hotel-specific or city-based searches
        let recentPairs = recentLocationsManager.getRecentSearchPairs()
        let hotelPairs = recentPairs.filter { pair in
            // Filter for hotel-like searches (same origin/destination or city-based)
            return pair.origin.iataCode == pair.destination.iataCode ||
                   pair.origin.type == "city"
        }
        
        if let lastHotelPair = hotelPairs.first {
            hotelLocation = lastHotelPair.origin.displayName
            hotelIATACode = lastHotelPair.origin.iataCode
            hasPrefilled = true
            print("✅ HotelView: Auto-prefilled from hotel searches")
        } else if let anyRecentPair = recentPairs.first {
            // Fallback to any recent location
            hotelLocation = anyRecentPair.origin.displayName
            hotelIATACode = anyRecentPair.origin.iataCode
            hasPrefilled = true
            print("✅ HotelView: Auto-prefilled from any recent search")
        }
    }
    
    private func saveCurrentSearch() {
        // Create Location object from current selection
        let hotelLocationObj = Location(
            iataCode: hotelIATACode,
            airportName: hotelLocation,
            type: "city", // Hotels are usually city-based
            displayName: hotelLocation,
            cityName: hotelLocation,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        // For hotels, save the same location as both origin and destination
        recentLocationsManager.addSearchPair(origin: hotelLocationObj, destination: hotelLocationObj)
        print("💾 HotelView: Saved hotel search: \(hotelLocation)")
    }
    
    // MARK: - Search Handler
    private func handleSearchHotels() {
        print("🏨 Search Hotels button tapped!")
        
        // Check internet connection first
        if !networkMonitor.isConnected {
            withAnimation(.easeInOut(duration: 0.3)) {
                showNoInternet = true
                showEmptySearch = false
            }
            return
        }
        
        // Validate hotel location
        guard !hotelIATACode.isEmpty else {
            print("⚠️ Missing hotel location")
            withAnimation(.easeInOut(duration: 0.3)) {
                showEmptySearch = true
                showNoInternet = false
            }
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
        
        print("🎯 Hotel search parameters:")
        print("   Location: \(hotelLocation) (\(hotelIATACode))")
        print("   Check-in: \(checkInDateTime)")
        print("   Check-out: \(checkOutDateTime)")
        print("   Guests: \(adults) adults, \(children) children")
        print("   Rooms: \(rooms)")
        
        // Start the search
        hotelSearchVM.searchHotels()
    }
    
    private func handlePopularLocationTapped(_ location: MasonryImage) {
        print("🏨 Popular hotel location tapped: \(location.title) (\(location.iataCode))")
        
        // Check internet connection first
        if !networkMonitor.isConnected {
            withAnimation(.easeInOut(duration: 0.3)) {
                showNoInternet = true
                showEmptySearch = false
            }
            return
        }
        
        // Set hotel location to popular location
        hotelLocation = location.title
        hotelIATACode = location.iataCode
        
        // Save search for recent locations
        savePopularHotelSearch(location: location)
        
        // Update ViewModel properties for hotel search
        hotelSearchVM.cityCode = location.iataCode
        hotelSearchVM.cityName = location.title
        hotelSearchVM.rooms = rooms
        hotelSearchVM.adults = adults
        hotelSearchVM.children = children
        
        // Use selected dates or default dates
        if selectedDates.count > 0 {
            hotelSearchVM.checkinDate = selectedDates[0]
        } else {
            hotelSearchVM.checkinDate = Date() // Today
        }
        
        if selectedDates.count > 1 {
            hotelSearchVM.checkoutDate = selectedDates[1]
        } else {
            // Default to tomorrow if no checkout date selected
            hotelSearchVM.checkoutDate = Calendar.current.date(byAdding: .day, value: 1, to: hotelSearchVM.checkinDate) ?? Date()
        }
        
        print("🎯 Popular hotel search parameters:")
        print("   Location: \(location.title) (\(location.iataCode))")
        print("   Check-in: \(hotelSearchVM.checkinDate)")
        print("   Check-out: \(hotelSearchVM.checkoutDate)")
        print("   Guests: \(adults) adults, \(children) children")
        print("   Rooms: \(rooms)")
        
        // Start the hotel search
        hotelSearchVM.searchHotels()
    }

    // Helper method to save popular hotel search
    private func savePopularHotelSearch(location: MasonryImage) {
        let hotelLocationObj = Location(
            iataCode: location.iataCode,
            airportName: location.title,
            type: "city", // Hotels are city-based
            displayName: location.title,
            cityName: location.title,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        // For hotels, save the same location as both origin and destination
        recentLocationsManager.addSearchPair(origin: hotelLocationObj, destination: hotelLocationObj)
        print("💾 Saved popular hotel search: \(location.title)")
    }
}

#Preview {
    HotelView()
}
