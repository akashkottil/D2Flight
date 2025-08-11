//
//  EditSearchSheet.swift
//  D2Flight
//
//  Created by Akash Kottil on 11/08/25.
//


import SwiftUI

// MARK: - Edit Search Sheet (Top Sheet Implementation)
struct EditSearchSheet: View {
    @Binding var isPresented: Bool
    @Binding var searchParameters: SearchParameters
    @StateObject private var flightSearchVM = FlightSearchViewModel()
    
    // Callback for when new search is completed
    var onNewSearchCompleted: (String, SearchParameters) -> Void
    
    // Local state for the sheet
    @State private var isOneWay: Bool
    @State private var originLocation: String
    @State private var destinationLocation: String
    @State private var originIATACode: String
    @State private var destinationIATACode: String
    @State private var selectedDates: [Date]
    @State private var travelersCount: String
    @State private var adults: Int
    @State private var children: Int
    @State private var infants: Int
    @State private var selectedClass: TravelClass
    
    // Sheet specific navigation states
    @State private var showPassengerSheet = false
    @State private var navigateToLocationSelection = false
    @State private var navigateToDateSelection = false
    @State private var isSearching = false
    
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var warningManager = WarningManager.shared
    @State private var lastNetworkStatus = true
    
    @Namespace private var animationNamespace
    
    init(
        isPresented: Binding<Bool>,
        searchParameters: Binding<SearchParameters>,
        onNewSearchCompleted: @escaping (String, SearchParameters) -> Void
    ) {
        self._isPresented = isPresented
        self._searchParameters = searchParameters
        self.onNewSearchCompleted = onNewSearchCompleted
        
        // Initialize state from searchParameters
        let params = searchParameters.wrappedValue
        self._isOneWay = State(initialValue: !params.isRoundTrip)
        self._originLocation = State(initialValue: params.originName)
        self._destinationLocation = State(initialValue: params.destinationName)
        self._originIATACode = State(initialValue: params.originCode)
        self._destinationIATACode = State(initialValue: params.destinationCode)
        self._selectedDates = State(initialValue: params.returnDate != nil ? [params.departureDate, params.returnDate!] : [params.departureDate])
        self._adults = State(initialValue: params.adults)
        self._children = State(initialValue: params.children)
        self._infants = State(initialValue: params.infants)
        self._selectedClass = State(initialValue: params.selectedClass)
        
        // Format travelers count
        let totalTravelers = params.adults + params.children + params.infants
        let travelerText = totalTravelers == 1 ? "Traveler" : "Travelers"
        self._travelersCount = State(initialValue: "\(totalTravelers) \(travelerText), \(params.selectedClass.displayName)")
    }
    
    var body: some View {
//        VStack(spacing: 0) {
//            // Drag Handle
//            RoundedRectangle(cornerRadius: 2.5)
//                .fill(Color.gray.opacity(0.4))
//                .frame(width: 40, height: 5)
//                .padding(.top, 12)
//                .padding(.bottom, 8)
//            
            // Header
//            HStack {
//                Button("Cancel") {
//                    withAnimation(.easeInOut(duration: 0.3)) {
//                        isPresented = false
//                    }
//                }
//                .font(CustomFont.font(.medium))
//                .foregroundColor(.gray)
//                
//                Spacer()
//                
//                Text("Edit Search")
//                    .font(CustomFont.font(.large, weight: .bold))
//                    .foregroundColor(.black)
//                
//                Spacer()
//                
//                Button("Done") {
//                    handleSearchFlights()
//                }
//                .font(CustomFont.font(.medium, weight: .semibold))
//                .foregroundColor(Color("Violet"))
//                .opacity(isSearching ? 0.6 : 1.0)
//                .disabled(isSearching)
//            }
//            .padding(.horizontal, 24)
//            .padding(.bottom, 20)
            
            // Content - Exact copy of ExpandableSearchContainer content
            VStack(alignment: .leading, spacing: 0) {
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
                .padding(.bottom, 20)
                
                // Search Card Content - Exact copy from SearchCard
                VStack(alignment: .leading, spacing: 16) {
                    // Location Input
                    locationSection
                    
                    // Enhanced Date Section
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            // Departure Date
                            dateView(
                                label: formatSelectedDate(for: .departure),
                                icon: "CalenderIcon"
                            )
                            .id("departure_date")
                            
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
                    
                    // Search Button with loading state
                    PrimaryButton(
                        title: isSearching ? "Searching..." : "Update Search",
                        font: CustomFont.font(.medium),
                        fontWeight: .bold,
                        textColor: .white,
                        verticalPadding: 20,
                        cornerRadius: 16,
                        action: handleSearchFlights
                    )
                    .opacity(isSearching ? 0.6 : 1.0)
                    .disabled(isSearching)
                    .overlay(
                        Group {
                            if isSearching {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Searching...")
                                        .font(CustomFont.font(.medium))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    )
                }
            }
            .padding(20)
            .background(GradientColor.Primary)
            .cornerRadius(20)
            .padding(.horizontal, 16)
            
//            Spacer()
//        }
//        .background(Color.white)
        .onReceive(flightSearchVM.$searchId) { newSearchId in
            if let searchId = newSearchId {
                // Create updated search parameters
                let updatedParams = createUpdatedSearchParameters()
                
                // Call the completion handler
                onNewSearchCompleted(searchId, updatedParams)
                
                // Close the sheet
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
                
                print("✅ Edit search completed with new searchId: \(searchId)")
            }
        }
        .onReceive(flightSearchVM.$errorMessage) { errorMessage in
            if let error = errorMessage {
                isSearching = false
                print("❌ Edit search failed: \(error)")
                // You can show an error alert here if needed
            }
        }
        .onReceive(networkMonitor.$isConnected) { isConnected in
            networkMonitor.handleNetworkChange(
                isConnected: isConnected,
                lastNetworkStatus: &lastNetworkStatus
            )
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
                    print("📍 Edit - Origin location selected: \(selectedLocation) (\(iataCode))")
                } else {
                    destinationLocation = selectedLocation
                    destinationIATACode = iataCode
                    print("📍 Edit - Destination location selected: \(selectedLocation) (\(iataCode))")
                }
            }
        }
    }
    
    // MARK: - Location Section (copied from SearchCard)
    @State private var swapButtonRotationAngle: Double = 0
    
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
                
                let tempIATA = originIATACode
                originIATACode = destinationIATACode
                destinationIATACode = tempIATA
                
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
    
    // MARK: - Date View (copied from SearchCard)
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
    
    // MARK: - Helper Methods
    private func formatSelectedDate(for type: CalendarDateType) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        
        switch type {
        case .departure:
            if let firstDate = selectedDates.first {
                return formatter.string(from: firstDate)
            }
            return formatter.string(from: Date())
            
        case .return:
            if selectedDates.count > 1, let secondDate = selectedDates.last {
                return formatter.string(from: secondDate)
            }
            return calculateDefaultReturnDate()
        }
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
        // This method is called when dates are updated
        // The UI will automatically update due to the binding
    }
    
    private func handleSearchFlights() {
        print("🔄 Edit search initiated")
        
        // Validate search inputs
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
        
        isSearching = true
        
        // Update ViewModel properties
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
        
        print("🎯 Edit search parameters validated and starting search")
        
        // Start the search
        flightSearchVM.searchFlights()
    }
    
    private func createUpdatedSearchParameters() -> SearchParameters {
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
}

#Preview {
    EditSearchSheet(
        isPresented: .constant(true),
        searchParameters: .constant(SearchParameters(
            originCode: "NYC",
            destinationCode: "LAX",
            originName: "New York",
            destinationName: "Los Angeles",
            isRoundTrip: true,
            departureDate: Date(),
            returnDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            adults: 2,
            children: 0,
            infants: 0,
            selectedClass: .economy
        ))
    ) { searchId, searchParams in
        print("New search completed: \(searchId)")
    }
}
