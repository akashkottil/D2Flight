import SwiftUI

struct HotelView: View {
    @State private var hotelLocation = ""
    @State private var hotelIATACode = ""
    
    @State private var checkInDate: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        return formatter.string(from: Date())
    }()
    
    @State private var checkOutDate: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return formatter.string(from: tomorrow)
    }()
    
    @State private var guestsCount = "2 Guests, 1 Room"
    
    // Passenger Sheet States
    @State private var showPassengerSheet = false
    @State private var adults = 2
    @State private var children = 0
    @State private var rooms = 1
    @State private var selectedClass: TravelClass = .economy // Not used for hotel but kept for compatibility
    
    // Date Selection States
    @State private var navigateToDateSelection = false
    @State private var selectedDates: [Date] = []
    
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
                            Text("Last Minute Hotels")
                                .font(CustomFont.font(.large, weight: .bold))
                                .foregroundColor(Color.white)
                        }
                        .padding(.vertical, 10)
                        
                        // Hotel Location Input (Single Input)
                        locationSection
                        
                        // Date Section (Check-in and Check-out)
                        VStack(spacing: 0) {
                            HStack(spacing: 10) {
                                // Check-in Date
                                dateView(
                                    label: formatSelectedDate(for: .checkin),
                                    icon: "CalenderIcon",
                                    title: "Check-in"
                                )
                                
                                // Check-out Date
                                dateView(
                                    label: formatSelectedDate(for: .checkout),
                                    icon: "CalenderIcon",
                                    title: "Check-out"
                                )
                            }
                        }
                        
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
                    
                    // Hotel Explore Card (you can create this similar to FlightExploreCard)
                    // HotelExploreCard()
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
        .fullScreenCover(isPresented: $navigateToDateSelection) {
            DateSelectionView(
                selectedDates: $selectedDates,
                isFromHotel: true
            ) { updatedDates in
                selectedDates = updatedDates
                updateDateLabels()
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
            initializeDates()
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
    
    // MARK: - Date View (Check-in/Check-out)
    func dateView(label: String, icon: String, title: String) -> some View {
        Button(action: {
            navigateToDateSelection = true
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CustomFont.font(.small, weight: .medium))
                    .foregroundColor(.gray)
                
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
    
    private func formatSelectedDate(for type: HotelDateType) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        
        switch type {
        case .checkin:
            if let firstDate = selectedDates.first {
                return formatter.string(from: firstDate)
            }
            return checkInDate // Fallback to default
            
        case .checkout:
            if selectedDates.count > 1, let secondDate = selectedDates.last {
                return formatter.string(from: secondDate)
            }
            return calculateDefaultCheckOutDate()
        }
    }
    
    private func calculateDefaultCheckOutDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        
        // Use selected check-in date if available, otherwise use current date
        let baseCheckInDate: Date
        if let selectedCheckInDate = selectedDates.first {
            baseCheckInDate = selectedCheckInDate
        } else {
            baseCheckInDate = Date()
        }
        
        // Add 1 day to the check-in date for check-out
        let checkOutDate = Calendar.current.date(byAdding: .day, value: 1, to: baseCheckInDate) ?? baseCheckInDate
        return formatter.string(from: checkOutDate)
    }
    
    private func initializeDates() {
        if selectedDates.isEmpty {
            let today = Date()
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
            selectedDates = [today, tomorrow]
            updateDateLabels()
        }
    }
    
    private func updateDateLabels() {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        
        if let firstDate = selectedDates.first {
            checkInDate = formatter.string(from: firstDate)
        }
        
        if selectedDates.count > 1, let secondDate = selectedDates.last {
            checkOutDate = formatter.string(from: secondDate)
        } else {
            checkOutDate = calculateDefaultCheckOutDate()
        }
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
        print("   Check-in: \(checkInDate)")
        print("   Check-out: \(checkOutDate)")
        print("   Guests: \(adults) adults, \(children) children")
        print("   Rooms: \(rooms)")
        
        // Start the search
        hotelSearchVM.searchHotels()
    }
}

#Preview {
    HotelView()
}
