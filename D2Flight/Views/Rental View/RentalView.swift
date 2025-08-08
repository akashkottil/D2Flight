import SwiftUI
import SafariServices

// MARK: - Updated RentalView with Universal Warning System
struct RentalView: View {
    @Namespace private var animationNamespace
    
    @State private var isSameDropOff = true
    @State private var pickUpLocation = ""
    @State private var dropOffLocation = ""
    @State private var pickUpIATACode = ""
    @State private var dropOffIATACode = ""
    
    @State private var pickUpDateTime: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM, HH:mm"
        let defaultTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: defaultTime)
    }()
    
    @State private var dropOffDateTime: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM, HH:mm"
        let defaultDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        let defaultTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: defaultDate) ?? defaultDate
        return formatter.string(from: defaultTime)
    }()
    
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
    
    // ✅ UPDATED: Remove individual notification states, use WarningManager
    @StateObject private var warningManager = WarningManager.shared
    @State private var lastNetworkStatus = true
    @State private var swapButtonRotationAngle: Double = 0
    
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
                        
                        // Enhanced Tabs with coordinated animations
                        HStack {
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    let wasChanged = isSameDropOff != true
                                    isSameDropOff = true
                                    
                                    if wasChanged {
                                        selectedDates = []
                                        selectedTimes = []
                                        dropOffLocation = ""
                                        dropOffIATACode = ""
                                        print("🔄 Switched to SAME drop-off - cleared dates/times for smart defaults")
                                    }
                                }
                            }) {
                                Text("Same drop-off")
                                    .foregroundColor(isSameDropOff ? .white : .gray)
                                    .font(CustomFont.font(.regular))
                                    .fontWeight(.semibold)
                                    .frame(width: 120, height: 31)
                                    .background(
                                        Group {
                                            if isSameDropOff {
                                                Color("Violet")
                                                    .matchedGeometryEffect(id: "rental_tab", in: animationNamespace)
                                            } else {
                                                Color("Violet").opacity(0.15)
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
                                        selectedDates = []
                                        selectedTimes = []
                                        print("🔄 Switched to DIFFERENT drop-off - cleared dates/times for smart defaults")
                                    }
                                }
                            }) {
                                Text("Different drop-off")
                                    .foregroundColor(!isSameDropOff ? .white : .gray)
                                    .font(CustomFont.font(.small))
                                    .fontWeight(.semibold)
                                    .frame(width: 120, height: 31)
                                    .background(
                                        Group {
                                            if !isSameDropOff {
                                                Color("Violet")
                                                    .matchedGeometryEffect(id: "rental_tab", in: animationNamespace)
                                            } else {
                                                Color("Violet").opacity(0.15)
                                            }
                                        }
                                    )
                                    .cornerRadius(100)
                            }
                        }
                        .padding(.vertical, 10)
                        
                        // Location Input Section
                        locationSection
                        
                        HStack(spacing: 10) {
                            dateTimeView(
                                icon: "CalenderIcon",
                                title: isSameDropOff ? "Pick-up (Same drop-off)" : "Pick-up & Drop-off"
                            )
                            .id("datetime_selector")
                        }
                        
                        // Search Rentals Button with validation
                        PrimaryButton(
                            title: "Search Rentals",
                            font: CustomFont.font(.medium),
                            fontWeight: .bold,
                            textColor: .white,
                            verticalPadding: 20,
                            cornerRadius: 16
                        ) {
                            handleSearchRentals()
                        }
                    }
                    .padding()
                    .padding(.top, 50)
                    .padding(.bottom, 30)
                    .background(GradientColor.Primary)
                    .cornerRadius(20)
                    
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
        .onReceive(rentalSearchVM.$deeplink) { deeplink in
            if let deeplink = deeplink {
                currentDeeplink = deeplink
                showWebView = true
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
                isSameDropOff: isSameDropOff
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
        .sheet(isPresented: $showWebView) {
            if let deeplink = currentDeeplink {
                RentalWebView(url: deeplink)
            }
        }
        .onAppear {
            if pickUpLocation.isEmpty {
                hasPrefilled = false
            }
            prefillRecentLocationsIfNeeded()
            initializeDateTimes()
        }
    }
    
    // MARK: - Location Section (same as before but with updated validation)
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
                        Text(pickUpLocation.isEmpty ? "Enter Pick-up Location" : pickUpLocation)
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
                            Text(dropOffLocation.isEmpty ? "Enter Drop-off Location" : dropOffLocation)
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
    
    // ✅ UPDATED: Search Handler with Universal Validation
    private func handleSearchRentals() {
        print("🚗 Search Rentals button tapped!")
        
        // ✅ Use SearchValidationHelper for validation
        if let warningType = SearchValidationHelper.validateRentalSearch(
            pickUpIATACode: pickUpIATACode,
            dropOffIATACode: dropOffIATACode,
            pickUpLocation: pickUpLocation,
            dropOffLocation: dropOffLocation,
            isSameDropOff: isSameDropOff,
            isConnected: networkMonitor.isConnected
        ) {
            warningManager.showWarning(type: warningType)
            return
        }
        
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
        
        rentalSearchVM.searchRentals()
    }
    
    // ✅ UPDATED: Popular Location Handler with Universal Validation
    private func handlePopularLocationTapped(_ location: MasonryImage) {
        print("🚗 Popular rental location tapped: \(location.title) (\(location.iataCode))")
        
        // Set pickup location to popular location
        pickUpLocation = location.title
        pickUpIATACode = location.iataCode
        
        // ✅ Use SearchValidationHelper for validation
        if let warningType = SearchValidationHelper.validateRentalSearch(
            pickUpIATACode: location.iataCode,
            dropOffIATACode: isSameDropOff ? "" : dropOffIATACode,
            pickUpLocation: location.title,
            dropOffLocation: dropOffLocation,
            isSameDropOff: isSameDropOff,
            isConnected: networkMonitor.isConnected
        ) {
            warningManager.showWarning(type: warningType)
            return
        }
        
        // Save search for recent locations
        savePopularRentalSearch(location: location)
        
        // Update ViewModel properties
        rentalSearchVM.pickUpIATACode = location.iataCode
        rentalSearchVM.dropOffIATACode = isSameDropOff ? "" : dropOffIATACode
        rentalSearchVM.isSameDropOff = isSameDropOff
        
        // Set dates and times
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
        
        // Start the rental search
        rentalSearchVM.searchRentals()
    }
    
    // MARK: - Date Time View (same as before)
    private func dateTimeView(icon: String, title: String) -> some View {
        let displayText: String
        
        if selectedDates.isEmpty || selectedTimes.isEmpty {
            if isSameDropOff {
                displayText = "Tap to select"
            } else {
                displayText = "Tap to select"
            }
        } else {
            let actualPickUp = combineDateAndTime(date: selectedDates[0], time: selectedTimes[0])
            let actualDropOff = selectedDates.count > 1 && selectedTimes.count > 1 ?
            combineDateAndTime(date: selectedDates[1], time: selectedTimes[1]) : actualPickUp
            
            let isSameDay = Calendar.current.isDate(actualPickUp, inSameDayAs: actualDropOff)
            
            if isSameDropOff || isSameDay {
                displayText = formattedDate(actualPickUp)
            } else {
                displayText = "\(formattedDate(actualPickUp)) • \(formattedDate(actualDropOff))"
            }
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
    
    // MARK: - Helper Methods (same as before)
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM, HH:mm"
        return formatter.string(from: date)
    }
    
    private func initializeDateTimes() {
        if !selectedDates.isEmpty && !selectedTimes.isEmpty {
            updateDateTimeLabels()
        }
        
        print("📅 RentalView initializeDateTimes completed. Mode: \(isSameDropOff ? "Same" : "Different") drop-off")
    }
    
    private func updateDateTimeLabels() {
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "E dd MMM, HH:mm"
        
        if selectedDates.count > 0 && selectedTimes.count > 0 {
            let combinedPickUpDateTime = combineDateAndTime(date: selectedDates[0], time: selectedTimes[0])
            pickUpDateTime = dateTimeFormatter.string(from: combinedPickUpDateTime)
        }
        
        if selectedDates.count > 1 && selectedTimes.count > 1 {
            let combinedDropOffDateTime = combineDateAndTime(date: selectedDates[1], time: selectedTimes[1])
            dropOffDateTime = dateTimeFormatter.string(from: combinedDropOffDateTime)
        } else if selectedDates.count > 0 && selectedTimes.count > 1 {
            let defaultDropOffDate = Calendar.current.date(byAdding: .day, value: 2, to: selectedDates[0]) ?? selectedDates[0]
            let combinedDropOffDateTime = combineDateAndTime(date: defaultDropOffDate, time: selectedTimes[1])
            dropOffDateTime = dateTimeFormatter.string(from: combinedDropOffDateTime)
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
        guard !hasPrefilled, pickUpLocation.isEmpty else {
            return
        }
        
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
}

// MARK: - Rental Web View
struct RentalWebView: UIViewControllerRepresentable {
    let url: String
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        let safari = SFSafariViewController(url: URL(string: url)!, configuration: config)
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

//#Preview {
//    RentalView()
//}
