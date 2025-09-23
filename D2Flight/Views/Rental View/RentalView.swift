import SwiftUI
import SafariServices

// MARK: - Small height reader helper (no visual impact)
private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
private extension View {
    func readHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { g in
                Color.clear.preference(key: HeightPreferenceKey.self, value: g.size.height)
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self, perform: onChange)
    }
}

// MARK: - Updated RentalView with Localized Date Display
struct RentalView: View {
    @Namespace private var animationNamespace
        
    // Collapsing header state (like FlightView)
    @State private var scrollView: UIScrollView? = nil
    @State private var offsetY: CGFloat = 0

    // Legacy fallbacks (kept, used only until real measurements arrive)
    private let fallbackExpandedSame: CGFloat = 380
    private let fallbackCollapsedSame: CGFloat = 280
    private let fallbackExpandedDiff: CGFloat = 440   // a bit taller for different drop-off
    private let fallbackCollapsedDiff: CGFloat = 300  // a bit taller for different drop-off

    // Namespace for the primary button morph
    @Namespace private var searchButtonNS

    @State private var isSameDropOff = true
    @State private var pickUpLocation = ""
    @State private var dropOffLocation = ""
    @State private var pickUpIATACode = ""
    @State private var dropOffIATACode = ""
    
    @State private var checkInDateTime: String = ""
    @State private var checkOutDateTime: String = ""
    
    // Date and Time Selection States
    @State private var navigateToDateTimeSelection = false
    @State private var selectedDates: [Date] = []
    @State private var selectedTimes: [Date] = []
    
    // Location Selection States
    @State private var navigateToLocationSelection = false
    
    // Search and Navigation States
    @StateObject private var rentalSearchVM = RentalSearchViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showWebView = false
    @State private var currentDeeplink: String? = nil
    
    // Recent locations management
    @StateObject private var recentLocationsManager = RecentLocationsManager.shared
    @State private var hasPrefilled = false
    
    @StateObject private var warningManager = WarningManager.shared
    @State private var lastNetworkStatus = true
    @State private var swapButtonRotationAngle: Double = 0

    // MARK: - Measured heights (expanded/collapsed × same/different)
    @State private var expandedHeightSame: CGFloat = 0
    @State private var expandedHeightDiff: CGFloat = 0
    @State private var collapsedHeightSame: CGFloat = 0
    @State private var collapsedHeightDiff: CGFloat = 0

    // MARK: - Smooth header state
    @State private var searchHeaderIsCollapsed: Bool = false

    // Computed heights for current tab (fall back to your constants until measured)
    private var expandedHeaderHeightForTab: CGFloat {
        isSameDropOff
        ? (expandedHeightSame > 0 ? expandedHeightSame : fallbackExpandedSame)
        : (expandedHeightDiff > 0 ? expandedHeightDiff : fallbackExpandedDiff)
    }
    private var collapsedHeaderHeightForTab: CGFloat {
        isSameDropOff
        ? (collapsedHeightSame > 0 ? collapsedHeightSame : fallbackCollapsedSame)
        : (collapsedHeightDiff > 0 ? collapsedHeightDiff : fallbackCollapsedDiff)
    }

    // Collapse progress + interpolated header height, using the RIGHT pair for the selected tab
    private var collapseRange: CGFloat { max(expandedHeaderHeightForTab - collapsedHeaderHeightForTab, 1) }
    /// 0 → expanded, 1 → collapsed (driven by scroll)
    private var collapseProgress: CGFloat {
        min(max(offsetY / collapseRange, 0), 1)
    }
    /// Smooth header height shrink
    private var headerHeight: CGFloat {
        let exp = expandedHeaderHeightForTab
        let col = collapsedHeaderHeightForTab
        return col * collapseProgress + exp * (1 - collapseProgress)
    }
    // Hysteresis to avoid jitter (based on current tab’s range)
    private var collapseThreshold: CGFloat { collapseRange * 0.45 }
    private var expandThreshold: CGFloat { collapseRange * 0.30 }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // TrackableScrollView drives collapseProgress
                TrackableScrollView(offsetY: $offsetY, scrollView: $scrollView) {
                    VStack(spacing: 0) {
                        // Push content beneath sticky header
                        Color.clear.frame(height: headerHeight)

                        // Your existing content below the card
                        PopularLocationsGrid(
                            searchType: .rental,
                            selectedDates: selectedDates,
                            adults: 1,
                            children: 0,
                            infants: 0,
                            selectedClass: .economy,
                            rooms: 1,
                            onLocationTapped: handlePopularLocationTapped
                        )
                        AutoSlidingCardsView()
                        BottomBar()
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

                // Sticky header (unchanged design)
                headerSection
                    .frame(height: headerHeight, alignment: .top)
                    .background(GradientColor.Primary)
                    .mask(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .clipped()
                    .animation(.easeInOut(duration: 0.2), value: collapseProgress)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85), value: isSameDropOff)

                // Warning overlay stays on top
                WarningOverlay()
            }
            .ignoresSafeArea()
        }

        // Network handling
        .onReceive(networkMonitor.$isConnected) { isConnected in
            networkMonitor.handleNetworkChange(
                isConnected: isConnected,
                lastNetworkStatus: &lastNetworkStatus
            )
        }
        // Handle search results
        .onReceive(rentalSearchVM.$deeplink) { deeplink in
            if let deeplink = deeplink {
                currentDeeplink = deeplink
                print("🔗 RentalView received deeplink: \(deeplink)")
            }
        }
        .onReceive(rentalSearchVM.$errorMessage) { errorMessage in
            if let error = errorMessage {
                print("⚠️ RentalView received error: \(error)")
            }
        }
        .fullScreenCover(isPresented: $navigateToDateTimeSelection) {
            DateTimeSelectionView(
                selectedDates: $selectedDates,
                selectedTimes: $selectedTimes,
                isSameDropOff: isSameDropOff
            ) { updatedDates, updatedTimes in
                selectedDates = updatedDates
                selectedTimes = updatedTimes
                updateDateTimeLabels()
            }
        }
        .fullScreenCover(isPresented: $navigateToLocationSelection) {
            LocationSelectionView(
                originLocation: $pickUpLocation,
                destinationLocation: $dropOffLocation,
                isFromRental: true,
                isSameDropOff: isSameDropOff,
                serviceType: .rental
            ) { selectedLocation, isOrigin, iataCode in
                if isOrigin {
                    pickUpLocation = selectedLocation
                    pickUpIATACode = iataCode
                    print("📍 Pick-up location selected: \(selectedLocation) (\(iataCode))")
                } else {
                    dropOffLocation = selectedLocation
                    dropOffIATACode = iataCode
                    print("📍 Drop-off location selected: \(selectedLocation) (\(iataCode))")
                }
            }
        }
        .fullScreenCover(isPresented: $showWebView) {
            RentalWebView(rentalSearchVM: rentalSearchVM)
        }
        // Keep measurements warm (no design change)
        .background(offscreenMeasuringCopies)
    }
    
    // MARK: - Location Section (kept as-is)
    private var locationSection: some View {
        ZStack {
            Button(action: {
                navigateToLocationSelection = true
            }) {
                VStack(spacing: 1) {
                    // Pick-up location (always visible)
                    HStack {
                        Image("DepartureIcon")
                            .frame(width: 20, height: 20)
                        Text(pickUpLocation.isEmpty ? "enter.pick-up.location".localized : pickUpLocation)
                            .foregroundColor(pickUpLocation.isEmpty ? .gray : .black)
                            .fontWeight(pickUpLocation.isEmpty ? .medium : .bold)
                            .font(CustomFont.font(.regular))
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity)
                    
                    // Drop-off location section (only for different drop-off)
                    if !isSameDropOff {
                        Divider()
                            .background(Color.gray.opacity(0.5))
                            .padding(.leading)
                            .padding(.trailing, 70)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                        
                        HStack {
                            Image("DestinationIcon")
                                .frame(width: 20, height: 20)
                            Text(dropOffLocation.isEmpty ? "enter.drop-off.location".localized : dropOffLocation)
                                .foregroundColor(dropOffLocation.isEmpty ? .gray : .black)
                                .fontWeight(dropOffLocation.isEmpty ? .medium : .bold)
                                .font(CustomFont.font(.regular))
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 18)
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .bottom))
                        ))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color.white)
            .cornerRadius(12)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSameDropOff)
            
            // Swap Button (only show for different drop-off)
            if !isSameDropOff {
                Button(action: {
                    let temp = pickUpLocation
                    pickUpLocation = dropOffLocation
                    dropOffLocation = temp
                    
                    let tempIATA = pickUpIATACode
                    pickUpIATACode = dropOffIATACode
                    dropOffIATACode = tempIATA
                    
                    print("🔄 Swapped locations - Pick-up: \(pickUpLocation), Drop-off: \(dropOffLocation)")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        swapButtonRotationAngle -= 180
                    }
                }) {
                    Image("SwapIcon")
                        .rotationEffect(.degrees(swapButtonRotationAngle))
                }
                .offset(x: 148)
                .shadow(color: .purple.opacity(0.3), radius: 5)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)),
                    removal: .opacity.combined(with: .scale(scale: 0.8))
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: !isSameDropOff)
            }
        }
    }
    
    private func handleSearchRentals() {
        print("🚗 Search Rentals button tapped!")
        
        // Validation
        if let warningType = SearchValidationHelper.validateRentalSearch(
            pickUpIATACode: pickUpIATACode,
            dropOffIATACode: dropOffIATACode,
            pickUpLocation: pickUpLocation,
            dropOffLocation: dropOffLocation,
            isSameDropOff: isSameDropOff,
            pickUpDate: selectedDates.first,
            pickUpTime: selectedTimes.first,
            dropOffDate: selectedDates.count > 1 ? selectedDates[1] : selectedDates.first,
            dropOffTime: selectedTimes.count > 1 ? selectedTimes[1] : nil,
            isConnected: networkMonitor.isConnected
        ) {
            warningManager.showWarning(type: warningType)
            return
        }
        
        // Set loading state IMMEDIATELY to trigger AnimatedRentalLoader
        rentalSearchVM.isLoading = true
        rentalSearchVM.deeplink = nil
        rentalSearchVM.errorMessage = nil
        
        // Save search pair
        saveCurrentSearchPair()
        
        // Update ViewModel properties
        rentalSearchVM.pickUpIATACode = pickUpIATACode
        rentalSearchVM.dropOffIATACode = isSameDropOff ? "" : dropOffIATACode
        rentalSearchVM.isSameDropOff = isSameDropOff
        
        if selectedDates.count > 0 {
            rentalSearchVM.pickUpDate = selectedDates[0]
        }
        if selectedDates.count > 1 {
            rentalSearchVM.dropOffDate = selectedDates[1]
        }
        if selectedTimes.count > 0 {
            rentalSearchVM.pickUpTime = selectedTimes[0]
        }
        if selectedTimes.count > 1 {
            rentalSearchVM.dropOffTime = selectedTimes[1]
        }
        
        print("🎯 Rental search parameters validated and starting search")
        showWebView = true
        rentalSearchVM.searchRentals()
    }

    private func handlePopularLocationTapped(_ location: MasonryImage) {
        print("🚗 Popular rental location tapped: \(location.title) (\(location.iataCode))")
        
        // Set pickup location to popular location
        pickUpLocation = location.title
        pickUpIATACode = location.iataCode
        
        if let warningType = SearchValidationHelper.validateRentalSearch(
            pickUpIATACode: location.iataCode,
            dropOffIATACode: isSameDropOff ? "" : dropOffIATACode,
            pickUpLocation: location.title,
            dropOffLocation: dropOffLocation,
            isSameDropOff: isSameDropOff,
            pickUpDate: selectedDates.first ?? Date(),
            pickUpTime: selectedTimes.first,
            dropOffDate: selectedDates.count > 1 ? selectedDates[1] : (selectedDates.first ?? Date()),
            dropOffTime: selectedTimes.count > 1 ? selectedTimes[1] : nil,
            isConnected: networkMonitor.isConnected
        ) {
            warningManager.showWarning(type: warningType)
            return
        }
        
        // Loader
        rentalSearchVM.isLoading = true
        rentalSearchVM.deeplink = nil
        rentalSearchVM.errorMessage = nil
        
        // Save search for recent locations
        savePopularRentalSearch(location: location)
        
        // Update ViewModel properties
        rentalSearchVM.pickUpIATACode = location.iataCode
        rentalSearchVM.dropOffIATACode = isSameDropOff ? "" : dropOffIATACode
        rentalSearchVM.isSameDropOff = isSameDropOff
        
        // Dates & times defaults if missing
        if selectedDates.count > 0 {
            rentalSearchVM.pickUpDate = selectedDates[0]
        } else {
            rentalSearchVM.pickUpDate = Date()
        }
        
        if selectedDates.count > 1 {
            rentalSearchVM.dropOffDate = selectedDates[1]
        } else {
            let daysToAdd = isSameDropOff ? 0 : 2
            rentalSearchVM.dropOffDate = Calendar.current.date(byAdding: .day, value: daysToAdd, to: rentalSearchVM.pickUpDate) ?? Date()
        }
        
        if selectedTimes.count > 0 {
            rentalSearchVM.pickUpTime = selectedTimes[0]
        } else {
            rentalSearchVM.pickUpTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        }
        
        if selectedTimes.count > 1 {
            rentalSearchVM.dropOffTime = selectedTimes[1]
        } else {
            let defaultHour = isSameDropOff ? 11 : 10
            rentalSearchVM.dropOffTime = Calendar.current.date(bySettingHour: defaultHour, minute: 0, second: 0, of: Date()) ?? Date()
        }
        
        print("🎯 Popular rental search validated and starting")
        print("🔥 Loading state set to: \(rentalSearchVM.isLoading)")
        
        showWebView = true
        rentalSearchVM.searchRentals()
    }
    
    // MARK: - Date Time View with localized formatting
    private func dateTimeView(icon: String, title: String) -> some View {
        let displayText: String
        
        if selectedDates.isEmpty || selectedTimes.isEmpty {
            displayText = "tap.to.select".localized
        } else if selectedDates.count < 2 || selectedTimes.count < 2 {
            let actualPickUp = combineDateAndTime(date: selectedDates[0], time: selectedTimes[0])
            displayText = formatLocalizedDateTime(actualPickUp)
        } else {
            let actualPickUp = combineDateAndTime(date: selectedDates[0], time: selectedTimes[0])
            let actualDropOff = combineDateAndTime(date: selectedDates[1], time: selectedTimes[1])
            displayText = "\(formatLocalizedDateTime(actualPickUp)) • \(formatLocalizedDateTime(actualDropOff))"
        }
        
        return Button(action: {
            navigateToDateTimeSelection = true
        }) {
            HStack {
                Image(icon)
                    .resizable()
                    .frame(width: 22, height: 22)
                
                Text(displayText)
                    .foregroundColor(.gray)
                    .fontWeight(.medium)
                    .font(.system(size: 13))
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .frame(maxWidth: .infinity)
        }
    }
    
    // Format date with localized weekday and month
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
    
    private func initializeDateTimes() {
        if !selectedDates.isEmpty && !selectedTimes.isEmpty {
            updateDateTimeLabels()
        } else {
            initializeDefaultDateTimes()
        }
        print("📅 RentalView initializeDateTimes completed. Mode: \(isSameDropOff ? "Same" : "Different") drop-off")
    }
    
    private func initializeDefaultDateTimes() {
        let now = Date()
        let calendar = Calendar.current
        
        if isSameDropOff {
            let pickupTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
            let dropoffTime = calendar.date(byAdding: .hour, value: 2, to: pickupTime) ?? pickupTime
            
            checkInDateTime = formatLocalizedDateTime(pickupTime)
            checkOutDateTime = formatLocalizedDateTime(dropoffTime)
        } else {
            let pickupDate = now
            let dropoffDate = calendar.date(byAdding: .day, value: 2, to: now) ?? now
            
            let pickupTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: pickupDate) ?? pickupDate
            let dropoffTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: dropoffDate) ?? dropoffDate
            
            checkInDateTime = formatLocalizedDateTime(pickupTime)
            checkOutDateTime = formatLocalizedDateTime(dropoffTime)
        }
    }
    
    private func calculateDefaultCheckoutDateTime() -> String {
        let baseCheckinDate: Date = selectedDates.first ?? Date()
        let checkoutDate = Calendar.current.date(byAdding: .day, value: 1, to: baseCheckinDate) ?? baseCheckinDate
        let defaultTime = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: checkoutDate) ?? checkoutDate
        return formatLocalizedDateTime(defaultTime)
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
        guard !hasPrefilled, pickUpLocation.isEmpty else { return }
        let recentPairs = recentLocationsManager.getRecentSearchPairs()
        if let lastPair = recentPairs.first {
            pickUpLocation = lastPair.origin.displayName
            pickUpIATACode = lastPair.origin.iataCode
            if !isSameDropOff && lastPair.origin.iataCode != lastPair.destination.iataCode {
                dropOffLocation = lastPair.destination.displayName
                dropOffIATACode = lastPair.destination.iataCode
            }
            hasPrefilled = true
            print("✅ RentalView: Auto-prefilled from recent searches")
        }
    }
    
    private func saveCurrentSearchPair() {
        let pickUpLocationObj = Location(
            iataCode: pickUpIATACode,
            airportName: pickUpLocation,
            type: "airport",
            displayName: pickUpLocation,
            cityName: pickUpLocation,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        let dropOffLocationObj: Location
        if isSameDropOff {
            dropOffLocationObj = pickUpLocationObj
        } else {
            dropOffLocationObj = Location(
                iataCode: dropOffIATACode,
                airportName: dropOffLocation,
                type: "airport",
                displayName: dropOffLocation,
                cityName: dropOffLocation,
                countryName: "",
                countryCode: "",
                imageUrl: "",
                coordinates: Coordinates(latitude: "0", longitude: "0")
            )
        }
        
        recentLocationsManager.addSearchPair(origin: pickUpLocationObj, destination: dropOffLocationObj)
        
        if isSameDropOff {
            print("💾 Saved search pair (same location): \(pickUpLocation)")
        } else {
            print("💾 Saved search pair: \(pickUpLocation) → \(dropOffLocation)")
        }
    }
    
    private func savePopularRentalSearch(location: MasonryImage) {
        let pickUpLocationObj = Location(
            iataCode: location.iataCode,
            airportName: location.title,
            type: "airport",
            displayName: location.title,
            cityName: location.title,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        let dropOffLocationObj: Location
        if isSameDropOff {
            dropOffLocationObj = pickUpLocationObj
        } else if !dropOffLocation.isEmpty {
            dropOffLocationObj = Location(
                iataCode: dropOffIATACode,
                airportName: dropOffLocation,
                type: "airport",
                displayName: dropOffLocation,
                cityName: dropOffLocation,
                countryName: "",
                countryCode: "",
                imageUrl: "",
                coordinates: Coordinates(latitude: "0", longitude: "0")
            )
        } else {
            dropOffLocationObj = pickUpLocationObj
        }
        
        recentLocationsManager.addSearchPair(origin: pickUpLocationObj, destination: dropOffLocationObj)
        
        if isSameDropOff {
            print("💾 Saved popular rental search (same location): \(location.title)")
        } else {
            print("💾 Saved popular rental search: \(location.title) → \(dropOffLocation.isEmpty ? location.title : dropOffLocation)")
        }
    }

    // MARK: - Header Section (sticky)
    private var headerSection: some View {
        VStack(alignment: .leading) {
            // Header
            HStack {
                Image("HomeLogo")
                    .frame(width: 32, height: 32)
                Text("Last Minute Rentals".localized) // optional: update title
                    .font(CustomFont.font(.large, weight: .bold))
                    .foregroundColor(Color.white)
            }
            .padding(.vertical, 10)

            // Tabs (same as your existing)
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        let wasChanged = isSameDropOff != true
                        isSameDropOff = true
                        if wasChanged {
                            selectedDates = []; selectedTimes = []
                            dropOffLocation = ""; dropOffIATACode = ""
                            // When switching tabs, gently keep header in view
                            scrollView?.setContentOffset(.zero, animated: true)
                        }
                    }
                }) {
                    Text("same.drop-off".localized)
                        .foregroundColor(isSameDropOff ? .white : .gray)
                        .font(CustomFont.font(.regular))
                        .fontWeight(.semibold)
                        .frame(width: 120, height: 31)
                        .background(
                            Group {
                                if isSameDropOff {
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color("Violet"))
                                        .matchedGeometryEffect(id: "rental_tab", in: animationNamespace)
                                } else {
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color("Violet").opacity(0.15))
                                }
                            }
                        )
                        .cornerRadius(100)
                }

                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        let wasChanged = isSameDropOff != false
                        isSameDropOff = false
                        if wasChanged {
                            selectedDates = []; selectedTimes = []
                            scrollView?.setContentOffset(.zero, animated: true)
                        }
                    }
                }) {
                    Text("different.drop-off".localized)
                        .foregroundColor(!isSameDropOff ? .white : .gray)
                        .font(CustomFont.font(.small))
                        .fontWeight(.semibold)
                        .frame(width: 120, height: 31)
                        .background(
                            Group {
                                if !isSameDropOff {
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color("Violet"))
                                        .matchedGeometryEffect(id: "rental_tab", in: animationNamespace)
                                } else {
                                    RoundedRectangle(cornerRadius: 100)
                                        .fill(Color("Violet").opacity(0.15))
                                }
                            }
                        )
                        .cornerRadius(100)
                }
            }
            .padding(.vertical, 10)

            // RentalSearchCard (design unchanged)
            RentalSearchCard(
                isSameDropOff: $isSameDropOff,
                pickUpLocation: $pickUpLocation,
                dropOffLocation: $dropOffLocation,
                pickUpIATACode: $pickUpIATACode,
                dropOffIATACode: $dropOffIATACode,
                selectedDates: $selectedDates,
                selectedTimes: $selectedTimes,
                navigateToLocationSelection: $navigateToLocationSelection,
                navigateToDateTimeSelection: $navigateToDateTimeSelection,
                collapseProgress: collapseProgress,   // driven by TrackableScrollView
                buttonNamespace: searchButtonNS,
                onSearchRentals: { handleSearchRentals() },
                onExpandSearchCard: { expandSearchCard() }
            )
        }
        .padding()
        .padding(.top, 50)
        .padding(.bottom, 10)
    }

    // Expand header and scroll to top when the collapsed chip is tapped
    private func expandSearchCard() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            searchHeaderIsCollapsed = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scrollView?.setContentOffset(.zero, animated: true)
        }
    }

    // MARK: - Invisible off-screen measuring copies (NO design changes)
    // We render RentalSearchCard in both states (expanded/collapsed) for both tabs to get exact heights.
    private var offscreenMeasuringCopies: some View {
        Group {
            // SAME drop-off — Expanded
            RentalSearchCard(
                isSameDropOff: .constant(true),
                pickUpLocation: .constant(pickUpLocation),
                dropOffLocation: .constant(dropOffLocation),
                pickUpIATACode: .constant(pickUpIATACode),
                dropOffIATACode: .constant(dropOffIATACode),
                selectedDates: .constant(selectedDates),
                selectedTimes: .constant(selectedTimes),
                navigateToLocationSelection: .constant(false),
                navigateToDateTimeSelection: .constant(false),
                collapseProgress: 0,
                buttonNamespace: searchButtonNS,
                onSearchRentals: {},
                onExpandSearchCard: {}
            )
            .readHeight { expandedHeightSame = $0 }
            .opacity(0.001)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            // SAME drop-off — Collapsed
            RentalSearchCard(
                isSameDropOff: .constant(true),
                pickUpLocation: .constant(pickUpLocation),
                dropOffLocation: .constant(dropOffLocation),
                pickUpIATACode: .constant(pickUpIATACode),
                dropOffIATACode: .constant(dropOffIATACode),
                selectedDates: .constant(selectedDates),
                selectedTimes: .constant(selectedTimes),
                navigateToLocationSelection: .constant(false),
                navigateToDateTimeSelection: .constant(false),
                collapseProgress: 1,
                buttonNamespace: searchButtonNS,
                onSearchRentals: {},
                onExpandSearchCard: {}
            )
            .readHeight { collapsedHeightSame = $0 }
            .opacity(0.001)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            // DIFFERENT drop-off — Expanded
            RentalSearchCard(
                isSameDropOff: .constant(false),
                pickUpLocation: .constant(pickUpLocation),
                dropOffLocation: .constant(dropOffLocation),
                pickUpIATACode: .constant(pickUpIATACode),
                dropOffIATACode: .constant(dropOffIATACode),
                selectedDates: .constant(selectedDates),
                selectedTimes: .constant(selectedTimes),
                navigateToLocationSelection: .constant(false),
                navigateToDateTimeSelection: .constant(false),
                collapseProgress: 0,
                buttonNamespace: searchButtonNS,
                onSearchRentals: {},
                onExpandSearchCard: {}
            )
            .readHeight { expandedHeightDiff = $0 }
            .opacity(0.001)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            // DIFFERENT drop-off — Collapsed
            RentalSearchCard(
                isSameDropOff: .constant(false),
                pickUpLocation: .constant(pickUpLocation),
                dropOffLocation: .constant(dropOffLocation),
                pickUpIATACode: .constant(pickUpIATACode),
                dropOffIATACode: .constant(dropOffIATACode),
                selectedDates: .constant(selectedDates),
                selectedTimes: .constant(selectedTimes),
                navigateToLocationSelection: .constant(false),
                navigateToDateTimeSelection: .constant(false),
                collapseProgress: 1,
                buttonNamespace: searchButtonNS,
                onSearchRentals: {},
                onExpandSearchCard: {}
            )
            .readHeight { collapsedHeightDiff = $0 }
            .opacity(0.001)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .frame(width: 0, height: 0) // ensures no layout impact
    }
}

// MARK: - Preview
#Preview {
    RentalView()
}
