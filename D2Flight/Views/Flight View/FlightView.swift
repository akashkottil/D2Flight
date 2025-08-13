import SwiftUI

// MARK: - Updated FlightView with Universal Warning System
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
    @State private var hasPrefilled = false
    
    // ✅ UPDATED: Remove individual notification states, use WarningManager
    @StateObject private var warningManager = WarningManager.shared
    @State private var lastNetworkStatus = true
    
    @State private var swapButtonRotationAngle: Double = 0
    @State private var numberOfColumns: Int = 2

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    // Top Section with Header and ExpandableSearchContainer
                    VStack(alignment: .leading) {
                        // Header
                        HStack {
                            Image("HomeLogo")
                                .frame(width: 32, height: 32)
                            Text(String(localized: "Last Minute Flights", defaultValue: "app_name"))
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
                        
                        // ExpandableSearchContainer
                        ExpandableSearchContainer(
                            isOneWay: $isOneWay,
                            originLocation: $originLocation,
                            destinationLocation: $destinationLocation,
                            originIATACode: $originIATACode,
                            destinationIATACode: $destinationIATACode,
                            selectedDates: $selectedDates,
                            travelersCount: $travelersCount,
                            showPassengerSheet: $showPassengerSheet,
                            adults: $adults,
                            children: $children,
                            infants: $infants,
                            selectedClass: $selectedClass,
                            navigateToLocationSelection: $navigateToLocationSelection,
                            navigateToDateSelection: $navigateToDateSelection,
                            onSearchFlights: handleSearchFlights
                        )
                    }
                    .padding()
                    .padding(.top, 50)
                    .padding(.bottom, 10)
                    .background(GradientColor.Primary)
                    .cornerRadius(20)

                    // ScrollView for content
                    ScrollView {
                        PopularLocationsGrid(
                            searchType: .flight,
                            selectedDates: selectedDates,
                            adults: adults,
                            children: children,
                            infants: infants,
                            selectedClass: selectedClass,
                            rooms: 1,
                            onLocationTapped: handlePopularLocationTapped
                        )

                        FlightExploreCard()
                        AutoSlidingCardsView()
                        BottomBar()
                    }
                    .scrollIndicators(.hidden)
                    .ignoresSafeArea(.all, edges: .bottom)
                }
                
                // ✅ UPDATED: Universal Warning Overlay
                WarningOverlay()
                
                // Add navigation destination for ResultView
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
            .ignoresSafeArea()
            
            // ✅ UPDATED: Use NetworkMonitor extension for centralized network handling
            .onReceive(networkMonitor.$isConnected) { isConnected in
                networkMonitor.handleNetworkChange(
                    isConnected: isConnected,
                    lastNetworkStatus: &lastNetworkStatus
                )
            }
            
            // Other existing onReceive and sheet handlers remain the same...
            .onReceive(flightSearchVM.$searchId) { searchId in
                if let searchId = searchId {
                    currentSearchId = searchId
                    createSearchParameters()
                    navigateToResults = true
                    print("🔍 FlightView updated currentSearchId: \(searchId)")
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
                if originLocation.isEmpty && destinationLocation.isEmpty {
                    hasPrefilled = false
                }
                prefillRecentLocationsIfNeeded()
                initializeReturnDate()
            }
        }
    }
    
    // ✅ UPDATED: Search Handler with Universal Validation
    private func handleSearchFlights() {
        print("🚀 Search Flights button tapped!")
        
        // ✅ Use SearchValidationHelper for validation
        if let warningType = SearchValidationHelper.validateFlightSearch(
            originIATACode: originIATACode,
            destinationIATACode: destinationIATACode,
            originLocation: originLocation,
            destinationLocation: destinationLocation,
            isConnected: networkMonitor.isConnected
        ) {
            warningManager.showWarning(type: warningType)
            return
        }
        
        // Save complete search pair for proper auto-prefill
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
        
        if !isOneWay && selectedDates.count > 1 {
            flightSearchVM.returnDate = selectedDates[1]
        } else if !isOneWay {
            let departureDate = selectedDates.first ?? Date()
            flightSearchVM.returnDate = Calendar.current.date(byAdding: .day, value: 2, to: departureDate) ?? departureDate.addingTimeInterval(86400 * 2)
        }
        
        flightSearchVM.adults = adults
        flightSearchVM.childrenAges = Array(repeating: 2, count: children)
        flightSearchVM.cabinClass = selectedClass.rawValue
        
        print("🎯 Search parameters validated and starting search")
        
        // Start the search
        flightSearchVM.searchFlights()
    }
    
    // ✅ UPDATED: Popular Location Handler with Universal Validation
    private func handlePopularLocationTapped(_ location: MasonryImage) {
        print("🌍 Popular location tapped: \(location.title) (\(location.iataCode))")
        
        // Use current location as origin, selected popular location as destination
        let currentOriginIATA = originIATACode.isEmpty ? "COK" : originIATACode
        
        // ✅ Use SearchValidationHelper for validation
        if let warningType = SearchValidationHelper.validateFlightSearch(
            originIATACode: currentOriginIATA,
            destinationIATACode: location.iataCode,
            originLocation: originLocation.isEmpty ? "Current Location" : originLocation,
            destinationLocation: location.title,
            isConnected: networkMonitor.isConnected
        ) {
            warningManager.showWarning(type: warningType)
            return
        }
        
        // Set destination to popular location
        destinationLocation = location.title
        destinationIATACode = location.iataCode
        
        // Save search pair
        savePopularLocationSearchPair(originIATA: currentOriginIATA, destinationLocation: location)
        
        // Update ViewModel properties
        flightSearchVM.departureIATACode = currentOriginIATA
        flightSearchVM.destinationIATACode = location.iataCode
        flightSearchVM.isRoundTrip = false
        
        if let firstDate = selectedDates.first {
            flightSearchVM.travelDate = firstDate
        } else {
            flightSearchVM.travelDate = Date()
        }
        
        flightSearchVM.adults = adults
        flightSearchVM.childrenAges = Array(repeating: 2, count: children)
        flightSearchVM.cabinClass = selectedClass.rawValue
        
        print("🎯 Popular destination search validated and starting")
        
        // Start the search
        flightSearchVM.searchFlights()
    }
    
    // All other helper methods remain the same...
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
            return
        }
        
        let recentPairs = recentLocationsManager.getRecentSearchPairs()
        let flightPairs = recentPairs.filter { pair in
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
    
    private func saveCurrentSearchPair() {
        let originLocationObj = Location(
            iataCode: originIATACode,
            airportName: self.originLocation,
            type: "airport",
            displayName: self.originLocation,
            cityName: self.originLocation,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        let destinationLocationObj = Location(
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
        
        recentLocationsManager.addSearchPair(origin: originLocationObj, destination: destinationLocationObj)
        print("💾 Saved search pair: \(self.originLocation) → \(self.destinationLocation)")
    }
    
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
    }
    
    private func calculateDefaultReturnDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        
        let baseDepartureDate: Date
        if let selectedDepartureDate = selectedDates.first {
            baseDepartureDate = selectedDepartureDate
        } else {
            baseDepartureDate = Date()
        }
        
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
            returnDate = calculateDefaultReturnDate()
        }
    }
    
    private func savePopularLocationSearchPair(originIATA: String, destinationLocation: MasonryImage) {
        let originLocationObj = Location(
            iataCode: originIATA,
            airportName: originLocation.isEmpty ? "Current Location" : originLocation,
            type: "airport",
            displayName: originLocation.isEmpty ? "Current Location" : originLocation,
            cityName: originLocation.isEmpty ? "Current Location" : originLocation,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        let destinationLocationObj = Location(
            iataCode: destinationLocation.iataCode,
            airportName: destinationLocation.title,
            type: "airport",
            displayName: destinationLocation.title,
            cityName: destinationLocation.title,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        recentLocationsManager.addSearchPair(origin: originLocationObj, destination: destinationLocationObj)
        print("💾 Saved popular destination search pair: \(originIATA) → \(destinationLocation.title)")
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
