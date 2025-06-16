import SwiftUI
import SafariServices

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
    
    // Notification States
    @State private var showNoInternet = false
    @State private var showEmptySearch = false
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
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color.white)
                        }
                        .padding(.vertical, 10)
                        
                        // Enhanced Tabs with coordinated animations
                        HStack {
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    isSameDropOff = true
                                }
                            }) {
                                Text("Same drop-off")
                                    .foregroundColor(isSameDropOff ? .white : .gray)
                                    .font(.system(size: 14))
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
                                    isSameDropOff = false
                                }
                            }) {
                                Text("Different drop-off")
                                    .foregroundColor(!isSameDropOff ? .white : .gray)
                                    .font(.system(size: 12))
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
                            // Pick-up Date & Time - Always visible
                            dateTimeView(
                                icon: "CalenderIcon",
                                title: "Pick-up",
                                pickUp: selectedDates.first ?? Date(),
                                dropOff: selectedDates.count > 1 ? selectedDates[1] : Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
                            )
                            .id("pickup_datetime")
                            
//                            // Drop-off Date & Time - Always visible
//                            dateTimeView(
//                                icon: "CalenderIcon",
//                                title: isSameDropOff ? "Drop-off (Same location)" : "Drop-off",
//                                pickUp: selectedDates.count > 1 ? selectedDates[1] : Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date(),
//                                dropOff: selectedDates.count > 1 ? selectedDates[1] : Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
//                            )
//                            .id("dropoff_datetime")
                        }
                        
                        // Search Rentals Button with validation
                        PrimaryButton(
                            title: "Search Rentals",
                            font: .system(size: 16),
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
                    
                    // Explore section (you can customize this for rentals)
                    //                    RentalExploreCard()
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
                destinationLocation: $dropOffLocation
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
            prefillRecentLocationsIfNeeded()
            initializeDateTimes()
        }
    }
    
    // MARK: - Location Section
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
                            .font(.system(size: 16))
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity)
                    
                    // Divider and Drop-off location (conditionally visible)
                    if !isSameDropOff {
                        Divider()
                            .background(Color.gray.opacity(0.5))
                            .padding(.leading)
                            .padding(.trailing, 70)
                            .transition(.opacity.combined(with: .scale))
                        
                        HStack {
                            Image("DestinationIcon")
                                .frame(width: 20, height: 20)
                            Text(dropOffLocation.isEmpty ? "Enter Drop-off Location" : dropOffLocation)
                                .foregroundColor(dropOffLocation.isEmpty ? .gray : .black)
                                .fontWeight(dropOffLocation.isEmpty ? .medium : .bold)
                                .font(.system(size: 14))
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 18)
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
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
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    // MARK: - Date Time View
    // MARK: - Date Time View
    private func dateTimeView(icon: String, title: String, pickUp: Date, dropOff: Date) -> some View {
        let isSameDay = Calendar.current.isDate(pickUp, inSameDayAs: dropOff)
        let pickUpText = formattedDate(pickUp)
        let dropOffText = isSameDay ? "" : formattedDate(dropOff)

        return Button(action: {
            navigateToDateTimeSelection = true
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(icon)
                        .resizable()
                        .frame(width: 16, height: 16)

                    Text(pickUpText)
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                        .font(.system(size: 13))
                    
                    Spacer()

                    // Only show drop-off text if it's different drop-off tab AND not same day
                    if !isSameDropOff && !isSameDay {
                        Spacer()
                        Text(dropOffText)
                            .foregroundColor(.gray)
                            .fontWeight(.medium)
                            .font(.system(size: 13))
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Methods
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM, HH:mm"
        return formatter.string(from: date)
    }
    
    private func initializeDateTimes() {
        if selectedDates.isEmpty {
            selectedDates = [Date()]
            let defaultDropOffDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
            selectedDates.append(defaultDropOffDate)
        }
        
        if selectedTimes.isEmpty {
            let pickUpTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            let dropOffTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
            selectedTimes = [pickUpTime, dropOffTime]
        }
        
        updateDateTimeLabels()
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
            // For same drop-off or single date, use pick-up date with drop-off time
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
        guard !hasPrefilled,
              pickUpLocation.isEmpty,
              dropOffLocation.isEmpty else {
            return
        }
        
        let lastLocations = recentLocationsManager.getLastSearchLocations()
        
        if let origin = lastLocations.origin {
            pickUpLocation = origin.displayName
            pickUpIATACode = origin.iataCode
        }
        
        if let destination = lastLocations.destination {
            dropOffLocation = destination.displayName
            dropOffIATACode = destination.iataCode
        }
        
        if lastLocations.origin != nil || lastLocations.destination != nil {
            hasPrefilled = true
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
        
        let dropOffLocationObj = Location(
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
        
        recentLocationsManager.addSearchPair(origin: pickUpLocationObj, destination: dropOffLocationObj)
    }
    
    // MARK: - Search Handler
    private func handleSearchRentals() {
        print("🚗 Search Rentals button tapped!")
        
        if !networkMonitor.isConnected {
            withAnimation(.easeInOut(duration: 0.3)) {
                showNoInternet = true
                showEmptySearch = false
            }
            return
        }
        
        guard !pickUpIATACode.isEmpty else {
            withAnimation(.easeInOut(duration: 0.3)) {
                showEmptySearch = true
                showNoInternet = false
            }
            return
        }
        
        if !isSameDropOff && dropOffIATACode.isEmpty {
            withAnimation(.easeInOut(duration: 0.3)) {
                showEmptySearch = true
                showNoInternet = false
            }
            return
        }
        
        saveCurrentSearchPair()
        
        // Update ViewModel properties
        rentalSearchVM.pickUpIATACode = pickUpIATACode
        rentalSearchVM.dropOffIATACode = dropOffIATACode
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
        
        rentalSearchVM.searchRentals()
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

#Preview {
    RentalView()
}
