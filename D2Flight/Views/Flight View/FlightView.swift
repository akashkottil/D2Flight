import SwiftUI

struct FlightView: View {
    @Namespace private var animationNamespace
    
    @State private var isOneWay = true
    @State private var originLocation = ""
    @State private var destinationLocation = ""
    @State private var departureDate = "Sat 23 Oct"
    @State private var returnDate = "Tue 26 Oct"
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
    
    var body: some View {
        NavigationStack {
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
                    
                    // Tabs
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
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
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
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
                    
                    // Date Section with Date Selection Integration
                    if isOneWay {
                        HStack {
                            dateView(
                                label: formatSelectedDate(for: .departure),
                                icon: "CalenderIcon"
                            )
                        }
                    } else {
                        HStack(spacing: 10) {
                            dateView(
                                label: formatSelectedDate(for: .departure),
                                icon: "CalenderIcon"
                            )
                            dateView(
                                label: formatSelectedDate(for: .return),
                                icon: "CalenderIcon"
                            )
                        }
                    }
                    
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
                    
                    // Updated Search Flights Button with Navigation
                    PrimaryButton(title: "Search Flights",
                                  font: .system(size: 16),
                                  fontWeight: .bold,
                                  textColor: .white,
                                  verticalPadding: 20,
                                  cornerRadius: 16,
                                  action: {
                        // Trigger navigation to ResultView
                        navigateToResults = true
                        
                        // Optional: Keep your existing prints for debugging
                        print("Search button tapped")
                        print("Selected dates: \(selectedDates)")
                        print("Origin: \(originLocation)")
                        print("Destination: \(destinationLocation)")
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
            .ignoresSafeArea()
            // Add navigation destination for ResultView
            .navigationDestination(isPresented: $navigateToResults) {
                ResultView()
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
            ) { selectedLocation, isOrigin in
                // Handle location selection callback
                print("Location selected: \(selectedLocation), isOrigin: \(isOrigin)")
            }
        }
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
                }
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color.white)
            .cornerRadius(12)
            
            Button(action: {
                let temp = originLocation
                originLocation = destinationLocation
                destinationLocation = temp
            }) {
                Image("SwapIcon")
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
