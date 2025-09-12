import SwiftUI

struct SearchCard: View {
    
    // Trip type
    @Binding var isOneWay: Bool
    
    // Location states
    @Binding var originLocation: String
    @Binding var destinationLocation: String
    @Binding var originIATACode: String
    @Binding var destinationIATACode: String
    
    // Date states
    @Binding var selectedDates: [Date]
    @State private var departureDate: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        return formatter.string(from: Date())
    }()
    @State private var returnDate: String = ""
    
    // Passenger states
    @Binding var travelersCount: String
    @Binding var showPassengerSheet: Bool
    @Binding var adults: Int
    @Binding var children: Int
    @Binding var infants: Int
    @Binding var selectedClass: TravelClass
    
    // Navigation states
    @Binding var navigateToLocationSelection: Bool
    @Binding var navigateToDateSelection: Bool
    
    // Animation state
    @State private var swapButtonRotationAngle: Double = 0
    
    // NEW: Animation and state properties for expandable functionality
    let buttonAnimationNamespace: Namespace.ID
    
    // Action closure
    let onSearchFlights: () -> Void
    
    // Date type enum for formatting
    enum DateType {
        case departure
        case `return`
    }
    
    // Updated initializer to include animation namespace
    init(
        isOneWay: Binding<Bool>,
        originLocation: Binding<String>,
        destinationLocation: Binding<String>,
        originIATACode: Binding<String>,
        destinationIATACode: Binding<String>,
        selectedDates: Binding<[Date]>,
        travelersCount: Binding<String>,
        showPassengerSheet: Binding<Bool>,
        adults: Binding<Int>,
        children: Binding<Int>,
        infants: Binding<Int>,
        selectedClass: Binding<TravelClass>,
        navigateToLocationSelection: Binding<Bool>,
        navigateToDateSelection: Binding<Bool>,
        buttonAnimationNamespace: Namespace.ID,
        onSearchFlights: @escaping () -> Void
    ) {
        self._isOneWay = isOneWay
        self._originLocation = originLocation
        self._destinationLocation = destinationLocation
        self._originIATACode = originIATACode
        self._destinationIATACode = destinationIATACode
        self._selectedDates = selectedDates
        self._travelersCount = travelersCount
        self._showPassengerSheet = showPassengerSheet
        self._adults = adults
        self._children = children
        self._infants = infants
        self._selectedClass = selectedClass
        self._navigateToLocationSelection = navigateToLocationSelection
        self._navigateToDateSelection = navigateToDateSelection
        self.buttonAnimationNamespace = buttonAnimationNamespace
        self.onSearchFlights = onSearchFlights
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            
            // Location Input
            locationSection
            
            // Enhanced Date Section with Smooth Animations
            VStack(spacing: 0) {
                HStack(spacing: 6) {
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
            
            // Search Flights Button with matched geometry effect
            PrimaryButton(title: "search.flights".localized,
                          font: CustomFont.font(.medium),
                          fontWeight: .bold,
                          textColor: .white,
                          verticalPadding: 20,
                          cornerRadius: 16,
                          action: onSearchFlights)
            .matchedGeometryEffect(id: "searchButton", in: buttonAnimationNamespace)
        }
        .onAppear {
            initializeReturnDate()
        }
        .onChange(of: selectedDates) { _ in
            updateDateLabels()
        }
    }
    
    // MARK: Location section with swap
    var locationSection: some View {
        ZStack {
            Button(action: {
                navigateToLocationSelection = true
            }) {
                VStack(spacing: 1) {
                    HStack {
                        Image("DepartureIcon")
                            .frame(width: 20, height: 20)
                        Text(originLocation.isEmpty ? "enter.departure".localized : originLocation)
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
                        Text(destinationLocation.isEmpty ? "enter.destination".localized : destinationLocation)
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
    
    // MARK: - NEW: Format Selected Date Function
    private func formatSelectedDate(for type: DateType) -> String {
        switch type {
        case .departure:
            if let firstDate = selectedDates.first {
                return LocalizedDateFormatter.formatShortDate(firstDate)
            } else {
                return LocalizedDateFormatter.formatShortDate(Date())
            }
            
        case .return:
            if selectedDates.count > 1, let secondDate = selectedDates.last {
                return LocalizedDateFormatter.formatShortDate(secondDate)
            } else {
                return calculateDefaultReturnDate()
            }
        }
    }
    
    // MARK: Helper Methods
    private func initializeReturnDate() {
        if returnDate.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "E dd MMM"
            let twoDaysLater = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
            returnDate = formatter.string(from: twoDaysLater)
        }
    }
    
    private func calculateDefaultReturnDate() -> String {
        let baseDepartureDate: Date
        if let selectedDepartureDate = selectedDates.first {
            baseDepartureDate = selectedDepartureDate
        } else {
            baseDepartureDate = Date()
        }
        
        let returnDate = Calendar.current.date(byAdding: .day, value: 2, to: baseDepartureDate) ?? baseDepartureDate
        return LocalizedDateFormatter.formatShortDate(returnDate)
    }
    
    private func updateDateLabels() {
        if let firstDate = selectedDates.first {
            departureDate = LocalizedDateFormatter.formatShortDate(firstDate)
        }
        
        if selectedDates.count > 1, let secondDate = selectedDates.last {
            returnDate = LocalizedDateFormatter.formatShortDate(secondDate)
        } else {
            returnDate = calculateDefaultReturnDate()
        }
    }
}
