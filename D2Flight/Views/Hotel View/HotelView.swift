import SwiftUI
import SafariServices

// MARK: - Updated HotelView (uses TrackableScrollView + collapsible header like FlightView)
struct HotelView: View {
    // MARK: Collapsible header / scroll tracking (same pattern as FlightView)
    @State private var scrollView: UIScrollView? = nil
    @State private var offsetY: CGFloat = 0

    /// These are tuned to preserve your current visual proportions
    private let expandedHeaderHeight: CGFloat = 380   // similar to Flight
    private let collapsedHeaderHeight: CGFloat = 220  // similar to Flight

    /// 0 → expanded, 1 → collapsed
    private var collapseProgress: CGFloat {
        let range = max(expandedHeaderHeight - collapsedHeaderHeight, 1)
        return min(max(offsetY / range, 0), 1)
    }

    /// Smooth header height interpolation
    private var headerHeight: CGFloat {
        let p = collapseProgress
        return expandedHeaderHeight - (expandedHeaderHeight - collapsedHeaderHeight) * p
    }

    // drive collapsed/expanded
    @State private var searchHeaderIsCollapsed: Bool = false

    // Relative thresholds (hysteresis) — match FlightView behavior
    private var collapseThreshold: CGFloat {
        (expandedHeaderHeight - collapsedHeaderHeight) * 0.45
    }
    private var expandThreshold: CGFloat {
        (expandedHeaderHeight - collapsedHeaderHeight) * 0.30
    }

    // Button morph namespace (passed into HotelSearchCard)
    @Namespace private var searchButtonNS

    // MARK: - Hotel search state (same as your current HotelView)
    @State private var hotelLocation = ""
    @State private var hotelIATACode = ""

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

    // Location Selection
    @State private var navigateToLocationSelection = false

    // ViewModels / managers
    @StateObject private var hotelSearchVM = HotelSearchViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var recentLocationsManager = RecentLocationsManager.shared
    @StateObject private var warningManager = WarningManager.shared

    // Misc (unchanged)
    @State private var showWebView = false
    @State private var lastNetworkStatus = true
    @State private var showingSafariView = false
    @State private var selectedURL: String = ""
    @State private var selectedProviderName: String? = nil
    @State private var showHotelSearchWebView = false
    @State private var lastPresentedDeeplink: String? = nil
    @State private var hasPrefilled = false

    private let CITY_META: [String: (city: String, country: String)] = [
        "COK": ("Kochi", "India"),
        "SYD": ("Sydney", "Australia"),
        "MXP": ("Milan", "Italy"),
        "BER": ("Berlin", "Germany"),
        "GIG": ("Rio de Janeiro", "Brazil"),
        "CAI": ("Cairo", "Egypt"),
    ]

    var body: some View {
        NavigationStack {
            ZStack (alignment: .top) {

                // MARK: - TrackableScrollView (like FlightView)
                TrackableScrollView(offsetY: $offsetY, scrollView: $scrollView) {
                    VStack(spacing: 0) {
                        // Spacer to push content below sticky header
                        Color.clear.frame(height: headerHeight)

                        // Main content (unchanged)
                        LazyVStack {
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

                        LazyVStack {
                            AutoSlidingCardsView()
                            BottomBar()
                        }
                    }
                }
                .onChange(of: offsetY) { y in
                    if !searchHeaderIsCollapsed, y > collapseThreshold {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            searchHeaderIsCollapsed = true
                        }
                    } else if searchHeaderIsCollapsed, y < expandThreshold {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            searchHeaderIsCollapsed = false
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .ignoresSafeArea(.all, edges: .bottom)

                // MARK: - Header Section (gradient + rounded mask — same as FlightView)
                headerSection
                    .frame(height: headerHeight, alignment: .top)
                    .background(GradientColor.Primary)
                    .mask(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .clipped()
                    .animation(.easeInOut(duration: 0.2), value: collapseProgress)

                // Universal warning overlay
                WarningOverlay()
            }
            .ignoresSafeArea()
            // observers / sheets (unchanged)
            .onReceive(networkMonitor.$isConnected) { isConnected in
                networkMonitor.handleNetworkChange(
                    isConnected: isConnected,
                    lastNetworkStatus: &lastNetworkStatus
                )
            }
            .onReceive(hotelSearchVM.$deeplink) { deeplink in
                guard let deeplink, !deeplink.isEmpty else { return }
                guard deeplink != lastPresentedDeeplink else { return }
                selectedURL = deeplink
                selectedProviderName = "Hotel Search"
                showingSafariView = true
                lastPresentedDeeplink = deeplink
            }
            .onReceive(hotelSearchVM.$isLoading) { isLoading in
                print("🔔 HotelView.$isLoading: \(isLoading)")
            }
            .onReceive(hotelSearchVM.$errorMessage) { errorMessage in
                print("🔔 HotelView.$errorMessage: '\(errorMessage ?? "nil")'")
                if let error = errorMessage, !error.isEmpty, showingSafariView {
                    showingSafariView = false
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
                ) { _ in
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
                ) { selectedLocation, _, iataCode in
                    hotelLocation = selectedLocation
                    hotelIATACode = iataCode

                    // Reset VM state on change
                    hotelSearchVM.deeplink = nil
                    hotelSearchVM.isLoading = false
                    hotelSearchVM.errorMessage = nil

                    print("🏨 Hotel location selected: \(selectedLocation) (\(iataCode))")
                }
            }
            .fullScreenCover(isPresented: $showHotelSearchWebView) {
                HotelSearchWebView(hotelSearchVM: hotelSearchVM)
            }
            .onAppear {
                if hotelLocation.isEmpty { hasPrefilled = false }
                prefillRecentLocationsIfNeeded()
                initializeDateTimes()
                if guestsCount.isEmpty {
                    guestsCount = formatGuestsText(adults: adults, children: children, rooms: rooms)
                }
            }
        }
    }

    // MARK: - Header content (logo + HotelSearchCard) — matches FlightView composition
    private var headerSection: some View {
        VStack(alignment: .leading) {
            // Header (same style as before)
            HStack {
                Image("HomeLogo")
                    .frame(width: 32, height: 32)
                Text("Last Minute Flights".localized) // unchanged title to preserve design
                    .font(CustomFont.font(.large, weight: .bold))
                    .foregroundColor(Color.white)
            }
            .padding(.vertical, 10)

            // HotelSearchCard plugged in like SearchCard in FlightView
            HotelSearchCard(
                hotelLocation: $hotelLocation,
                hotelIATACode: $hotelIATACode,
                selectedDates: $selectedDates,
                selectedTimes: $selectedTimes,
                guestsCount: $guestsCount,
                showPassengerSheet: $showPassengerSheet,
                adults: $adults,
                children: $children,
                rooms: $rooms,
                navigateToLocationSelection: $navigateToLocationSelection,
                navigateToDateTimeSelection: $navigateToDateTimeSelection,
                collapseProgress: collapseProgress,          // 0…1 from scroll
                buttonNamespace: searchButtonNS,
                onSearchHotels: { handleSearchHotels() },
                onExpandSearchCard: { expandSearchCard() }
            )
        }
        .padding()
        .padding(.top, 50)
        .padding(.bottom, 10)
    }

    // MARK: - Actions (same behavior as your existing HotelView)
    private func handleSearchHotels() {
        #if DEBUG
        print("🏨 Search Hotels button tapped!")
        #endif

        if let warningType = SearchValidationHelper.validateHotelSearch(
            hotelIATACode: hotelIATACode,
            hotelLocation: hotelLocation,
            isConnected: networkMonitor.isConnected
        ) {
            warningManager.showWarning(type: warningType)
            return
        }

        // Persist + configure VM
        saveCurrentSearch()
        let countryName = extractCountryNameFromLocation(hotelLocation)

        hotelSearchVM.cityCode = hotelIATACode
        hotelSearchVM.cityName = extractCityNameFromLocation(hotelLocation)
        hotelSearchVM.countryName = countryName
        hotelSearchVM.rooms = rooms
        hotelSearchVM.adults = adults
        hotelSearchVM.children = children

        if selectedDates.count > 0 { hotelSearchVM.checkinDate = selectedDates[0] }
        if selectedDates.count > 1 { hotelSearchVM.checkoutDate = selectedDates[1] }

        // Show loader then kick off search
        showHotelSearchWebView = true
        hotelSearchVM.isLoading = true
        DispatchQueue.main.async {
            hotelSearchVM.searchHotels()
        }
    }

    // Match FlightView’s expand handler to jump back to expanded header
    private func expandSearchCard() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            searchHeaderIsCollapsed = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scrollView?.setContentOffset(.zero, animated: true)
        }
    }

    // MARK: - Popular locations (unchanged)
    private func handlePopularLocationTapped(_ location: MasonryImage) {
        print("🏨 Popular hotel location tapped: \(location.title) (\(location.iataCode))")

        let formattedTitle = LocationDisplayFormatter.formatDisplayName(
            from: location.title,
            type: "city"
        )

        hotelLocation = formattedTitle
        hotelIATACode = location.iataCode

        if let warningType = SearchValidationHelper.validateHotelSearch(
            hotelIATACode: location.iataCode,
            hotelLocation: formattedTitle,
            isConnected: networkMonitor.isConnected
        ) {
            warningManager.showWarning(type: warningType)
            return
        }

        savePopularHotelSearch(location: location)

        let meta = CITY_META[location.iataCode]
        hotelSearchVM.cityCode = location.iataCode
        hotelSearchVM.cityName = meta?.city ?? formattedTitle
        hotelSearchVM.countryName = meta?.country ?? "Unknown"

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

        showHotelSearchWebView = true
        hotelSearchVM.isLoading = true
        DispatchQueue.main.async {
            print("🚀 Popular location - calling hotelSearchVM.searchHotels() (grid flow)")
            hotelSearchVM.searchHotels()
        }
    }

    // MARK: - Helpers (same as your existing HotelView)
    enum HotelDateType { case checkin, checkout }

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

    private func formatLocalizedDateTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        let localizedWeekday = CalendarLocalization.getLocalizedWeekdayName(for: weekdayIndex)
        let dayNumber = calendar.component(.day, from: date)
        let localizedMonth = CalendarLocalization.getLocalizedMonthName(for: date, isShort: true)
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
        let baseCheckinDate: Date = selectedDates.first ?? Date()
        let checkoutDate = Calendar.current.date(byAdding: .day, value: 1, to: baseCheckinDate) ?? baseCheckinDate
        let defaultTime = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: checkoutDate) ?? checkoutDate
        return formatLocalizedDateTime(defaultTime)
    }

    private func initializeDateTimes() {
        if !selectedDates.isEmpty && !selectedTimes.isEmpty {
            updateDateTimeLabels()
        } else {
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
        guard !hasPrefilled, hotelLocation.isEmpty else { return }

        let recentPairs = recentLocationsManager.getRecentSearchPairs()
        let hotelPairs = recentPairs.filter { pair in
            pair.origin.iataCode == pair.destination.iataCode || pair.origin.type == "city"
        }

        if let lastHotelPair = hotelPairs.first {
            let originalDisplayName = lastHotelPair.origin.displayName
            let formattedDisplayName = LocationDisplayFormatter.formatDisplayName(
                from: originalDisplayName,
                type: lastHotelPair.origin.type
            )
            hotelLocation = formattedDisplayName
            hotelIATACode = lastHotelPair.origin.iataCode
            hasPrefilled = true
            print("✅ HotelView: Auto-prefilled from hotel searches")
        } else if let anyRecentPair = recentPairs.first {
            let originalDisplayName = anyRecentPair.origin.displayName
            let formattedDisplayName = LocationDisplayFormatter.formatDisplayName(
                from: originalDisplayName,
                type: anyRecentPair.origin.type
            )
            hotelLocation = formattedDisplayName
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
            cityName: hotelIATACode,
            countryName: extractCountryNameFromLocation(hotelLocation),
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        recentLocationsManager.addSearchPair(origin: hotelLocationObj, destination: hotelLocationObj)
        print("💾 HotelView: Saved hotel search with formatted name: \(hotelLocation)")
    }

    private func savePopularHotelSearch(location: MasonryImage) {
        let formattedTitle = LocationDisplayFormatter.formatDisplayName(from: location.title, type: "city")
        let meta = CITY_META[location.iataCode]
        let hotelLocationObj = Location(
            iataCode: location.iataCode,
            airportName: formattedTitle,
            type: "city",
            displayName: formattedTitle,
            cityName: meta?.city ?? formattedTitle,
            countryName: meta?.country ?? "Unknown",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        recentLocationsManager.addSearchPair(origin: hotelLocationObj, destination: hotelLocationObj)
        print("💾 Saved popular hotel search with formatted name: \(formattedTitle)")
    }

    private func extractCityNameFromLocation(_ location: String) -> String {
        let components = location.components(separatedBy: ", ")
        return components.first ?? location
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

    private func formatGuestsText(adults: Int, children: Int, rooms: Int) -> String {
        let totalGuests = adults + children
        let guestsText = totalGuests == 1 ? "\(totalGuests) \("guest".localized)" : "\(totalGuests) \("guests".localized)"
        let roomsText = rooms == 1 ? "\(rooms) \("room".localized)" : "\(rooms) \("rooms".localized)"
        return "\(guestsText), \(roomsText)"
    }
}
