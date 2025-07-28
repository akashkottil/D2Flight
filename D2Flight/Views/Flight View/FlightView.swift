import SwiftUI

struct FlightView: View {
    @Namespace private var animationNamespace
    
    @State private var isOneWay = true
    @State private var originLocation = ""
    @State private var destinationLocation = ""
    @State private var iataCode = ""
    @State private var departureDate: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        return formatter.string(from: Date())
    }()

    // Updated: Remove the static return date calculation
    @State private var returnDate: String = ""
    @State private var travelersCount = "2 Travellers, Economy"
    
    // Passenger Sheet States
    @State private var showPassengerSheet = false
    @State private var adults = 2
    @State private var children = 0
    @State private var infants = 0
    @State private var selectedClass: TravelClass = .economy
    
    // Date Selection States
    @State private var navigateToDateSelection = false
    @State private var selectedDates: [Date] = []
    
    // Location Selection States
    @State private var navigateToLocationSelection = false
    
    // Navigation to ResultView
    @State private var navigateToResults = false
    
    
    @StateObject private var flightSearchVM = FlightSearchViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    
    @State private var originIATACode: String = ""
    @State private var destinationIATACode: String = ""
    @State private var currentSearchId: String? = nil
    @State private var currentSearchParameters: SearchParameters? = nil
    
    // NEW: Recent locations management
    @StateObject private var recentLocationsManager = RecentLocationsManager.shared
    @State private var hasPrefilled = false // Prevent multiple prefills
    
    // Notification States
    @State private var showNoInternet = false
    @State private var showEmptySearch = false
    @State private var lastNetworkStatus = true
    
    @State private var swapButtonRotationAngle: Double = 0
    
    @State private var numberOfColumns: Int = 2

        let images: [MasonryImage] = [
            .init(imageName: "https://picsum.photos/200/300", height: 200),
            .init(imageName: "https://picsum.photos/200", height: 150),
            .init(imageName: "https://picsum.photos/id/237/200/300", height: 300),
            .init(imageName: "https://picsum.photos/200/300/?blur", height: 180),
            .init(imageName: "https://picsum.photos/200/600/?blur", height: 220),
        ]

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
                                    isOneWay = true
                                }
                            }) {
                                Text("One Way")
                                    .foregroundColor(isOneWay ? .white : .gray)
                                    .font(CustomFont.font(.small))
                                    .fontWeight(.semibold)
                                    .frame(width: 87, height: 31)
                                    .background(
                                        Group {
                                            if isOneWay {
                                                Color("Violet")
                                                    .matchedGeometryEffect(id: "tab", in: animationNamespace)
                                            } else {
                                                Color("Violet").opacity(0.15)
                                            }
                                        }
                                    )
                                    .cornerRadius(100)
                            }
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    isOneWay = false
                                }
                            }) {
                                Text("Round Trip")
                                    .foregroundColor(!isOneWay ? .white : .gray)
                                    .font(CustomFont.font(.small))
                                    .fontWeight(.semibold)
                                    .frame(width: 87, height: 31)
                                    .background(
                                        Group {
                                            if !isOneWay {
                                                Color("Violet")
                                                    .matchedGeometryEffect(id: "tab", in: animationNamespace)
                                            } else {
                                                Color("Violet").opacity(0.15)
                                            }
                                        }
                                    )
                                    .cornerRadius(100)
                            }
                        }
                        .padding(.vertical, 10)
                        
                        // Location Input - Updated to navigate to LocationSelectionView
                        locationSection
                        
                        // Enhanced Date Section with Smooth Animations
                        VStack(spacing: 0) {
                            HStack(spacing: 10) {
                                // Departure Date - Always visible with stable identity
                                dateView(
                                    label: formatSelectedDate(for: .departure),
                                    icon: "CalenderIcon"
                                )
                                .id("departure_date") // Stable identity prevents recreation
                                
                                // Return Date with smooth conditional visibility
                                Group {
                                    if !isOneWay {
                                        dateView(
                                            label: formatSelectedDate(for: .return),
                                            icon: "CalenderIcon"
                                        )
                                        .transition(
                                            .asymmetric(
                                                insertion: .scale(scale: 0.8)
                                                    .combined(with: .opacity)
                                                    .combined(with: .move(edge: .trailing)),
                                                removal: .scale(scale: 0.8)
                                                    .combined(with: .opacity)
                                                    .combined(with: .move(edge: .trailing))
                                            )
                                        )
                                    }
                                }
                                .frame(maxWidth: !isOneWay ? .infinity : 0)
                                .opacity(!isOneWay ? 1 : 0)
                                .scaleEffect(!isOneWay ? 1 : 0.8)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2),
                                    value: isOneWay
                                )
                            }
                        }
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isOneWay)
                        
                        // Passenger Section
                        Button(action: {
                            showPassengerSheet = true
                        }) {
                            HStack {
                                Image("PassengerIcon")
                                    .foregroundColor(.gray)
                                    .frame(width: 22)
                                Text(travelersCount)
                                    .foregroundColor(.gray)
                                    .fontWeight(.medium)
                                    .font(CustomFont.font(.regular))
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // Updated Search Flights Button with validation
                        PrimaryButton(title: "Search Flights",
                                      font: CustomFont.font(.medium),
                                      fontWeight: .bold,
                                      textColor: .white,
                                      verticalPadding: 20,
                                      cornerRadius: 16,
                                      action: {
                            handleSearchFlights()
                        })
                    }
                    .padding()
                    .padding(.top, 50)
                    .padding(.bottom, 30)
                    .background(GradientColor.Primary)
                    .cornerRadius(20)
                    
                    
//                    MasonryGrid(data: images, columns: numberOfColumns) { item in
//                                        GeometryReader { geo in
//                                            let width = geo.size.width
//                                            let aspectRatio = 3 / 2.0
//                                            let adjustedHeight = item.height * (width / 200)
//
//                                            AsyncImage(url: URL(string: item.imageName)) { image in
//                                                image
//                                                    .resizable()
//                                                    .scaledToFill()
//                                            } placeholder: {
//                                                Color.gray.opacity(0.3)
//                                            }
//                                            .frame(width: width, height: adjustedHeight)
//                                            .clipped()
//                                            .cornerRadius(10)
//                                        }
//                                        .frame(height: item.height)
//                                    }
//                                    .padding(.horizontal)
                    
                FlightExploreCard()
                }
                .scrollIndicators(.hidden)
                
                // Notification Components Overlay
                VStack {
                    Spacer()
                    
                    if showNoInternet {
                        NoInternet(isVisible: $showNoInternet)
                            .padding(.bottom, 100) // Space above tab bar
                    }
                    
                    if showEmptySearch {
                        EmptySearch(isVisible: $showEmptySearch)
                            .padding(.bottom, 100) // Space above tab bar
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: showNoInternet)
                .animation(.easeInOut(duration: 0.3), value: showEmptySearch)
            }
            .ignoresSafeArea()
            // Add navigation destination for ResultView with search parameters
            .navigationDestination(isPresented: Binding(
                get: { currentSearchId != nil && navigateToResults && currentSearchParameters != nil },
                set: { newValue in
                    if !newValue {
                        currentSearchId = nil
                        navigateToResults = false
                        currentSearchParameters = nil
                    }
                }
            )) {
                if let validSearchId = currentSearchId,
                   let searchParams = currentSearchParameters {
                    ResultView(searchId: validSearchId, searchParameters: searchParams)
                } else {
                    Text("Invalid Search Parameters")
                }
            }
        }
        // Network monitoring
        .onReceive(networkMonitor.$isConnected) { isConnected in
            // Show no internet notification when connection is lost
            if lastNetworkStatus && !isConnected {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showNoInternet = true
                    showEmptySearch = false // Hide other notifications
                }
            }
            lastNetworkStatus = isConnected
        }
        // Add search observation with AnimatedResultLoader integration
        .onReceive(flightSearchVM.$searchId) { searchId in
            if let searchId = searchId {
                currentSearchId = searchId
                
                // Create search parameters when search is successful
                createSearchParameters()
                
                // Delay to show the loader for minimum time, then navigate
                
                navigateToResults = true
                
                
                print("🔍 FlightView updated currentSearchId and will show loader: \(searchId)")
            }
        }
        .onReceive(flightSearchVM.$isLoading) { isLoading in
            print("📡 FlightView - Search loading state: \(isLoading)")
            
        }
        .onReceive(flightSearchVM.$errorMessage) { errorMessage in
            if let error = errorMessage {
                print("⚠️ FlightView received error: \(error)")
                
            }
        }
        .sheet(isPresented: $showPassengerSheet) {
            PassengerSheet(
                isPresented: $showPassengerSheet,
                adults: $adults,
                children: $children,
                infants: $infants,
                selectedClass: $selectedClass
            ) { updatedTravelersText in
                travelersCount = updatedTravelersText
            }
        }
        .fullScreenCover(isPresented: $navigateToDateSelection) {
            DateSelectionView(
                selectedDates: $selectedDates,
                isRoundTrip: !isOneWay
            ) { updatedDates in
                selectedDates = updatedDates
                updateDateLabels()
            }
        }
        .fullScreenCover(isPresented: $navigateToLocationSelection) {
            LocationSelectionView(
                originLocation: $originLocation,
                destinationLocation: $destinationLocation
            ) { selectedLocation, isOrigin, iataCode in
                if isOrigin {
                    originLocation = selectedLocation
                    originIATACode = iataCode
                    print("📍 Origin location selected: \(selectedLocation) (\(iataCode))")
                } else {
                    destinationLocation = selectedLocation
                    destinationIATACode = iataCode
                    print("📍 Destination location selected: \(selectedLocation) (\(iataCode))")
                }
            }
        }
        
        .onAppear {
            // Reset prefill state when view appears fresh
            if originLocation.isEmpty && destinationLocation.isEmpty {
                hasPrefilled = false
            }
            prefillRecentLocationsIfNeeded()
            initializeReturnDate()
        }
    }
    
    // NEW: Initialize return date based on current date + 2 days initially
    private func initializeReturnDate() {
        if returnDate.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "E dd MMM"
            let twoDaysLater = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
            returnDate = formatter.string(from: twoDaysLater)
        }
    }
    
    private func prefillRecentLocationsIfNeeded() {
        guard !hasPrefilled,
              originLocation.isEmpty,
              destinationLocation.isEmpty else {
            print("🚫 FlightView: Skipping prefill - already prefilled or locations not empty")
            return
        }
        
        // Only prefill from flight-specific recent searches
        let recentPairs = recentLocationsManager.getRecentSearchPairs()
        let flightPairs = recentPairs.filter { pair in
            // Filter for flight-like searches (different origin/destination)
            return pair.origin.iataCode != pair.destination.iataCode
        }
        
        if let lastFlightPair = flightPairs.first {
            originLocation = lastFlightPair.origin.displayName
            originIATACode = lastFlightPair.origin.iataCode
            destinationLocation = lastFlightPair.destination.displayName
            destinationIATACode = lastFlightPair.destination.iataCode
            hasPrefilled = true
            print("✅ FlightView: Auto-prefilled from flight searches")
        }
    }
    
    // NEW: Save current search pair when search is initiated
    private func saveCurrentSearchPair() {
        // Create Location objects from current selection
        let originLocation = Location(
            iataCode: originIATACode,
            airportName: self.originLocation, // Using the display name as airport name
            type: "airport", // Default to airport
            displayName: self.originLocation,
            cityName: self.originLocation,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        let destinationLocation = Location(
            iataCode: destinationIATACode,
            airportName: self.destinationLocation,
            type: "airport",
            displayName: self.destinationLocation,
            cityName: self.destinationLocation,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        // Save the complete search pair
        recentLocationsManager.addSearchPair(origin: originLocation, destination: destinationLocation)
        print("💾 Saved search pair: \(self.originLocation) → \(self.destinationLocation)")
    }
    
    // Create search parameters from current state
    private func createSearchParameters() {
        let departureDate = selectedDates.first ?? Date()
        let returnDate = (!isOneWay && selectedDates.count > 1) ? selectedDates[1] : nil
        
        currentSearchParameters = SearchParameters(
            originCode: originIATACode,
            destinationCode: destinationIATACode,
            originName: originLocation,
            destinationName: destinationLocation,
            isRoundTrip: !isOneWay,
            departureDate: departureDate,
            returnDate: returnDate,
            adults: adults,
            children: children,
            infants: infants,
            selectedClass: selectedClass
        )
        
        print("🎯 Created search parameters:")
        print("   Route: \(originIATACode) to \(destinationIATACode)")
        print("   Trip Type: \(!isOneWay ? "Round Trip" : "One Way")")
        print("   Departure: \(departureDate)")
        if let returnDate = returnDate {
            print("   Return: \(returnDate)")
        }
        print("   Travelers: \(adults) adults, \(children) children, \(infants) infants")
        print("   Class: \(selectedClass.displayName)")
    }
    
    // MARK: - Search Handler
    private func handleSearchFlights() {
        print("🚀 Search Flights button tapped!")
        
        // Check internet connection first
        if !networkMonitor.isConnected {
            withAnimation(.easeInOut(duration: 0.3)) {
                showNoInternet = true
                showEmptySearch = false
            }
            return
        }
        
        // Validate locations
        guard !originIATACode.isEmpty, !destinationIATACode.isEmpty else {
            print("⚠️ Missing IATA codes - Origin: '\(originIATACode)', Destination: '\(destinationIATACode)'")
            withAnimation(.easeInOut(duration: 0.3)) {
                showEmptySearch = true
                showNoInternet = false
            }
            return
        }
        
        // NEW: Save complete search pair for proper auto-prefill
        saveCurrentSearchPair()
        
        // Update ViewModel properties before search
        flightSearchVM.departureIATACode = originIATACode
        flightSearchVM.destinationIATACode = destinationIATACode
        flightSearchVM.isRoundTrip = !isOneWay
        
        if let firstDate = selectedDates.first {
            flightSearchVM.travelDate = firstDate
        } else {
            flightSearchVM.travelDate = Date()
        }
        
        // Set return date for round trip
        if !isOneWay && selectedDates.count > 1 {
            flightSearchVM.returnDate = selectedDates[1]
        } else if !isOneWay {
            // Default return date if not selected - use departure date + 2 days
            let departureDate = selectedDates.first ?? Date()
            flightSearchVM.returnDate = Calendar.current.date(byAdding: .day, value: 2, to: departureDate) ?? departureDate.addingTimeInterval(86400 * 2)
        }
        
        flightSearchVM.adults = adults
        flightSearchVM.childrenAges = Array(repeating: 2, count: children)
        flightSearchVM.cabinClass = selectedClass.rawValue
        
        print("🎯 Search parameters:")
        print("   Round Trip: \(!isOneWay)")
        print("   Selected Dates: \(selectedDates.count)")
        if !isOneWay && selectedDates.count > 1 {
            print("   Return Date: \(selectedDates[1])")
        }
        
        // Start the search - this will trigger the animated loader
        flightSearchVM.searchFlights()
    }
    
    // MARK: Location section with swap - Updated to navigate to LocationSelectionView
    var locationSection: some View {
        ZStack {
            Button(action: {
                navigateToLocationSelection = true
            }) {
                VStack(spacing: 1) {
                    HStack {
                        Image("DepartureIcon")
                            .frame(width: 20, height: 20)
                        Text(originLocation.isEmpty ? "Enter Departure" : originLocation)
                            .foregroundColor(originLocation.isEmpty ? .gray : .black)
                            .fontWeight(originLocation.isEmpty ? .medium : .bold)
                            .font(CustomFont.font(.regular))
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity)
                    Divider()
                        .background(Color.gray.opacity(0.5))
                        .padding(.leading)
                        .padding(.trailing, 70)
                    
                    HStack {
                        Image("DestinationIcon")
                            .frame(width: 20, height: 20)
                        Text(destinationLocation.isEmpty ? "Enter Destination" : destinationLocation)
                            .foregroundColor(destinationLocation.isEmpty ? .gray : .black)
                            .fontWeight(destinationLocation.isEmpty ? .medium : .bold)
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
            
            Button(action: {
                let temp = originLocation
                originLocation = destinationLocation
                destinationLocation = temp
                
                // Also swap IATA codes
                let tempIATA = originIATACode
                originIATACode = destinationIATACode
                destinationIATACode = tempIATA
                
                print("🔄 Swapped locations - Origin: \(originLocation), Destination: \(destinationLocation)")
                // Toggle rotation state
                withAnimation(.easeInOut(duration: 0.3)) {
                        swapButtonRotationAngle -= 180
                    }
            }) {
                Image("SwapIcon")
                    .rotationEffect(.degrees(swapButtonRotationAngle))
            }
            .offset(x: 148)
            .shadow(color: .purple.opacity(0.3), radius: 5)
        }
    }
    
    // MARK: Date View with Date Selection Integration
    func dateView(label: String, icon: String) -> some View {
        Button(action: {
            navigateToDateSelection = true
        }) {
            HStack {
                Image(icon)
                    .frame(width: 20, height: 20)
                Text(label)
                    .foregroundColor(.gray)
                    .fontWeight(.medium)
                    .font(CustomFont.font(.regular))
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: Helper Methods
    private func formatSelectedDate(for type: CalendarDateType) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        
        switch type {
        case .departure:
            if let firstDate = selectedDates.first {
                return formatter.string(from: firstDate)
            }
            return departureDate // Fallback to default
            
        case .return:
            if selectedDates.count > 1, let secondDate = selectedDates.last {
                return formatter.string(from: secondDate)
            }
            // NEW: Calculate return date based on departure date + 2 days
            return calculateDefaultReturnDate()
        }
    }
    
    // NEW: Calculate default return date based on departure date + 2 days
    private func calculateDefaultReturnDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        
        // Use selected departure date if available, otherwise use current date
        let baseDepartureDate: Date
        if let selectedDepartureDate = selectedDates.first {
            baseDepartureDate = selectedDepartureDate
        } else {
            baseDepartureDate = Date()
        }
        
        // Add 2 days to the departure date
        let returnDate = Calendar.current.date(byAdding: .day, value: 2, to: baseDepartureDate) ?? baseDepartureDate
        return formatter.string(from: returnDate)
    }
    
    private func updateDateLabels() {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        
        if let firstDate = selectedDates.first {
            departureDate = formatter.string(from: firstDate)
        }
        
        if selectedDates.count > 1, let secondDate = selectedDates.last {
            returnDate = formatter.string(from: secondDate)
        } else {
            // NEW: Update return date based on new departure date + 2 days
            returnDate = calculateDefaultReturnDate()
        }
    }
}





// MARK: - Supporting Types
enum CalendarDateType {
    case departure
    case `return`
}

#Preview {
    FlightView()
}
