import SwiftUI

// MARK: - Lazy Navigation View Wrapper
struct NavigationLazyView<Content: View>: View {
    private let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}

// MARK: - Optimized FlightView with Performance Enhancements
struct FlightView: View {
    @Namespace private var animationNamespace
    
    // MARK: - Core State Variables (Minimal @State usage)
    @State private var isOneWay = true
    @State private var originLocation = ""
    @State private var destinationLocation = ""
    @State private var originIATACode: String = ""
    @State private var destinationIATACode: String = ""
    
    // MARK: - Optimized Date State
    @State private var selectedDates: [Date] = []
    @State private var departureDate: String = ""
    
    // MARK: - Passenger Configuration
    @State private var adults = 2
    @State private var children = 0
    @State private var infants = 0
    @State private var selectedClass: TravelClass = .economy
    @State private var travelersCount: String = ""
    
    // MARK: - Navigation States (Optimized)
    @State private var showPassengerSheet = false
    @State private var navigateToDateSelection = false
    @State private var navigateToLocationSelection = false
    @State private var navigateToResults = false
    
    // MARK: - Optimized ViewModels (Lazy initialization)
    @StateObject private var flightSearchVM = FlightSearchViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var warningManager = WarningManager.shared
    @StateObject private var recentLocationsManager = RecentLocationsManager.shared
    
    // MARK: - Performance Optimized State
    @State private var currentSearchId: String? = nil
    @State private var currentSearchParameters: SearchParameters? = nil
    @State private var hasPrefilled = false
    @State private var lastNetworkStatus = true
    @State private var swapButtonRotationAngle: Double = 0
    
    /// Global loader flag (the ONLY AnimatedResultLoader in the flow)
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Main Content (Optimized Layout)
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // MARK: - Header Section
                        headerSection
                        
                        // MARK: - Popular Locations (Lazy Loading)
                        LazyVStack {
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
                        }
                        
                        // MARK: - Additional Content (Lazy Loading)
                        LazyVStack {
//                            FlightExploreCard()
                            AutoSlidingCardsView()
                            BottomBar()
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .ignoresSafeArea(.all, edges: .bottom)
                
                // MARK: - Universal Warning Overlay
                WarningOverlay()
            }
            .ignoresSafeArea()
            
            // MARK: - Network Monitoring (Optimized)
            .onReceive(networkMonitor.$isConnected.throttle(for: .milliseconds(500), scheduler: RunLoop.main, latest: true)) { isConnected in
                networkMonitor.handleNetworkChange(
                    isConnected: isConnected,
                    lastNetworkStatus: &lastNetworkStatus
                )
            }
            
            // MARK: - Search Results Navigation (Lazy Loading)
            .navigationDestination(isPresented: $navigateToResults) {
                if let validSearchId = currentSearchId,
                   let searchParams = currentSearchParameters {
                    // Pass the loader binding down so ResultView can CLOSE it
                    NavigationLazyView(
                        ResultView(
                            searchId: validSearchId,
                            searchParameters: searchParams,
                            loaderBinding: $isSearching
                        )
                    )
                } else {
                    Text("invalid.search.parameters".localized)
                }
            }
            
            // MARK: - Sheet Presentations (Optimized)
            .sheet(isPresented: $showPassengerSheet) {
                NavigationLazyView(
                    PassengerSheet(
                        isPresented: $showPassengerSheet,
                        adults: $adults,
                        children: $children,
                        infants: $infants,
                        selectedClass: $selectedClass
                    ) { _ in
                        updateTravelersText()
                    }
                )
            }
            
            .fullScreenCover(isPresented: $navigateToDateSelection) {
                NavigationLazyView(
                    DateSelectionView(
                        selectedDates: $selectedDates,
                        isRoundTrip: !isOneWay
                    ) { updatedDates in
                        selectedDates = updatedDates
                        updateDateLabels()
                    }
                )
            }
            
            .fullScreenCover(isPresented: $navigateToLocationSelection) {
                NavigationLazyView(
                    LocationSelectionView(
                        originLocation: $originLocation,
                        destinationLocation: $destinationLocation,
                        serviceType: .flight
                    ) { selectedLocation, isOrigin, iataCode in
                        updateLocationSelection(selectedLocation, isOrigin, iataCode)
                    }
                )
            }
            
            // MARK: - Show the ONLY AnimatedResultLoader here
            .fullScreenCover(isPresented: $isSearching) {
                AnimatedResultLoader(isVisible: $isSearching)
            }
            
            // MARK: - Search ID Observation (Optimized)
            .onReceive(flightSearchVM.$searchId.debounce(for: .milliseconds(100), scheduler: RunLoop.main)) { searchId in
                handleSearchIdUpdate(searchId)
            }
            
            .onAppear {
                initializeViewIfNeeded()
            }
        }
    }
    
    // MARK: - Header Section (Extracted for Performance)
    private var headerSection: some View {
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
            
            // Enhanced Tabs
            tripTypeSelector
            
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
                onSearchFlights: handleSearchFlightsOptimized
            )
        }
        .padding()
        .padding(.top, 50)
        .padding(.bottom, 10)
        .background(GradientColor.Primary)
        .cornerRadius(20)
    }
    
    // MARK: - Trip Type Selector (Extracted)
    private var tripTypeSelector: some View {
        HStack {
            Button(action: { switchToOneWay() }) {
                Text("one.way".localized)
                    .foregroundColor(isOneWay ? .white : .gray)
                    .font(CustomFont.font(.small))
                    .fontWeight(.semibold)
                    .frame(width: 87, height: 31)
                    .background(
                        Group {
                            if isOneWay {
                                RoundedRectangle(cornerRadius: 100)
                                           .fill(Color("Violet"))
                                    .matchedGeometryEffect(id: "tab", in: animationNamespace)
                            } else {
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color("Violet").opacity(0.15))
                            }
                        }
                    )
                    .cornerRadius(100)
            }
            
            Button(action: { switchToRoundTrip() }) {
                Text("round.trip".localized)
                    .foregroundColor(!isOneWay ? .white : .gray)
                    .font(CustomFont.font(.small))
                    .fontWeight(.semibold)
                    .frame(width: 87, height: 31)
                    .background(
                        Group {
                            if !isOneWay {
                                RoundedRectangle(cornerRadius: 100)
                                            .fill(Color("Violet"))
                                    .matchedGeometryEffect(id: "tab", in: animationNamespace)
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
    }
    
    // MARK: - Optimized Action Handlers
    
    private func switchToOneWay() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isOneWay = true
        }
    }
    
    private func switchToRoundTrip() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isOneWay = false
        }
    }
    
    private func handleSearchFlightsOptimized() {
        // Immediately show AnimatedResultLoader
        isSearching = true
        
        // Perform validation on background queue
        Task.detached(priority: .userInitiated) {
            // Validation logic
            if let warningType = SearchValidationHelper.validateFlightSearch(
                originIATACode: originIATACode,
                destinationIATACode: destinationIATACode,
                originLocation: originLocation,
                destinationLocation: destinationLocation,
                isConnected: networkMonitor.isConnected
            ) {
                await MainActor.run {
                    // Dismiss loader if validation fails
                    isSearching = false
                    warningManager.showWarning(type: warningType)
                }
                return
            }
            
            // Background preparation
            _ = await prepareSearchParameters()
            
            // Switch to main thread for UI updates and API call
            await MainActor.run {
                // Update ViewModel properties
                updateFlightSearchViewModel()
                
                // Save search pair
                saveCurrentSearchPair()
                
                print("🎯 Search parameters validated and starting search")
                
                // Start the search (ResultView will close the loader)
                flightSearchVM.searchFlights()
            }
        }
    }
    
    private func handleSearchIdUpdate(_ searchId: String?) {
        guard let searchId = searchId else { return }
        
        Task { @MainActor in
            // NOTE: Do NOT close the loader here.
            // Let ResultView close it on appear to avoid double-presentation.
            currentSearchId = searchId
            currentSearchParameters = await createSearchParameters()
            navigateToResults = true
            print("🔍 FlightView updated currentSearchId: \(searchId)")
        }
    }
    
    private func handlePopularLocationTapped(_ location: MasonryImage) {
        print("🌍 Popular location tapped: \(location.title) (\(location.iataCode))")
        
        // Use current location as origin, selected popular location as destination
        let currentOriginIATA = originIATACode.isEmpty ? "COK" : originIATACode
        
        // Validation
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
        
        // Immediately show AnimatedResultLoader
        isSearching = true
        
        // Set destination to popular location
        destinationLocation = location.title
        destinationIATACode = location.iataCode
        
        // Background processing
        Task.detached(priority: .userInitiated) {
            await MainActor.run {
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
        }
    }
    
    private func updateLocationSelection(_ selectedLocation: String, _ isOrigin: Bool, _ iataCode: String) {
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
    
    // MARK: - Background Helper Methods
    
    @MainActor
    private func prepareSearchParameters() async -> SearchParameters {
        let departureDate = selectedDates.first ?? Date()
        let returnDate = (!isOneWay && selectedDates.count > 1) ? selectedDates[1] : nil
        
        return SearchParameters(
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
    
    private func updateFlightSearchViewModel() {
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
    }
    
    // MARK: - Initialization & Utility Methods
    
    private func initializeViewIfNeeded() {
        guard !hasPrefilled else { return }
        
        Task.detached(priority: .background) {
            await MainActor.run {
                prefillRecentLocationsIfNeeded()
                initializeReturnDate()
                
                if travelersCount.isEmpty {
                    updateTravelersText()
                }
            }
        }
    }
    
    private func initializeReturnDate() {
        if departureDate.isEmpty {
            departureDate = LocalizedDateFormatter.formatShortDate(Date())
        }
    }
    
    private func prefillRecentLocationsIfNeeded() {
        guard originLocation.isEmpty && destinationLocation.isEmpty else { return }
        
        let recentPairs = recentLocationsManager.getRecentSearchPairs()
        let flightPairs = recentPairs.filter { $0.origin.iataCode != $0.destination.iataCode }
        
        if let lastFlightPair = flightPairs.first {
            originLocation = lastFlightPair.origin.displayName
            originIATACode = lastFlightPair.origin.iataCode
            destinationLocation = lastFlightPair.destination.displayName
            destinationIATACode = lastFlightPair.destination.iataCode
            hasPrefilled = true
            print("✅ FlightView: Auto-prefilled from flight searches")
        }
    }
    
    private func updateTravelersText() {
        travelersCount = formatTravelersText(
            adults: adults,
            children: children,
            infants: infants,
            selectedClass: selectedClass
        )
    }
    
    private func updateDateLabels() {
        if let firstDate = selectedDates.first {
            departureDate = LocalizedDateFormatter.formatShortDate(firstDate)
        }
    }
    
    @MainActor
    private func createSearchParameters() async -> SearchParameters {
        let departureDate = selectedDates.first ?? Date()
        let returnDate = (!isOneWay && selectedDates.count > 1) ? selectedDates[1] : nil
        
        return SearchParameters(
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
    
    private func saveCurrentSearchPair() {
        let originLocationObj = Location(
            iataCode: originIATACode,
            airportName: originLocation,
            type: "airport",
            displayName: originLocation,
            cityName: originLocation,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        let destinationLocationObj = Location(
            iataCode: destinationIATACode,
            airportName: destinationLocation,
            type: "airport",
            displayName: destinationLocation,
            cityName: destinationLocation,
            countryName: "",
            countryCode: "",
            imageUrl: "",
            coordinates: Coordinates(latitude: "0", longitude: "0")
        )
        
        recentLocationsManager.addSearchPair(origin: originLocationObj, destination: destinationLocationObj)
        print("💾 Saved search pair: \(originLocation) → \(destinationLocation)")
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
    
    private func formatTravelersText(adults: Int, children: Int, infants: Int, selectedClass: TravelClass) -> String {
        let totalTravelers = adults + children + infants
        let travelersText = totalTravelers == 1 ?
            "\(totalTravelers) \("traveller".localized)" :
            "\(totalTravelers) \("travellers".localized)"
        return "\(travelersText), \(selectedClass.displayName)"
    }
}

#Preview {
    FlightView()
}
