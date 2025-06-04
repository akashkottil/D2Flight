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

    @State private var returnDate: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        let twoDaysLater = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        return formatter.string(from: twoDaysLater)
    }()
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
    
    // AnimatedResultLoader State
    @State private var showAnimatedLoader = false
    
    @StateObject private var flightSearchVM = FlightSearchViewModel()
    @StateObject private var networkMonitor = NetworkMonitor()
    
    @State private var originIATACode: String = ""
    @State private var destinationIATACode: String = ""
    @State private var currentSearchId: String? = nil
    @State private var currentSearchParameters: SearchParameters? = nil // NEW: Store search parameters
    
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
                                    isOneWay = true
                                }
                            }) {
                                Text("One Way")
                                    .foregroundColor(isOneWay ? .white : .gray)
                                    .font(.system(size: 12))
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
                                    .font(.system(size: 12))
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
                                    .font(.system(size: 14))
                                Spacer()
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // Updated Search Flights Button with validation
                        PrimaryButton(title: "Search Flights",
                                      font: .system(size: 16),
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
            // UPDATED: Add navigation destination for ResultView with search parameters
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showAnimatedLoader = false
                    }
                    
                    // Small delay for smooth transition
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToResults = true
                    }
                }
                
                print("🔍 FlightView updated currentSearchId and will show loader: \(searchId)")
            }
        }
        .onReceive(flightSearchVM.$isLoading) { isLoading in
            print("📡 FlightView - Search loading state: \(isLoading)")
            
            // Show animated loader when search starts
            if isLoading {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showAnimatedLoader = true
                }
            }
        }
        .onReceive(flightSearchVM.$errorMessage) { errorMessage in
            if let error = errorMessage {
                print("⚠️ FlightView received error: \(error)")
                // Hide loader if there's an error
                withAnimation(.easeInOut(duration: 0.5)) {
                    showAnimatedLoader = false
                }
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
        // AnimatedResultLoader as full screen cover - hides tab navigation
        .fullScreenCover(isPresented: $showAnimatedLoader) {
            AnimatedResultLoader(isVisible: $showAnimatedLoader)
        }
    }
    
    // NEW: Create search parameters from current state
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
            // Default return date if not selected
            flightSearchVM.returnDate = (selectedDates.first ?? Date()).addingTimeInterval(86400 * 7)
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
                            .font(.system(size: 14))
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
                            .font(.system(size: 14))
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
                    .font(.system(size: 14))
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
            return returnDate // Fallback to default
        }
    }
    
    private func updateDateLabels() {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        
        if let firstDate = selectedDates.first {
            departureDate = formatter.string(from: firstDate)
        }
        
        if selectedDates.count > 1, let secondDate = selectedDates.last {
            returnDate = formatter.string(from: secondDate)
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
