import SwiftUI

struct SearchCard: View {
    @Namespace private var animationNamespace
    
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
    
    // Action closure
    let onSearchFlights: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            // Location Input
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
            
            // Search Flights Button
            PrimaryButton(title: "Search Flights",
                          font: CustomFont.font(.medium),
                          fontWeight: .bold,
                          textColor: .white,
                          verticalPadding: 20,
                          cornerRadius: 16,
                          action: onSearchFlights)
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
    private func initializeReturnDate() {
        if returnDate.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "E dd MMM"
            let twoDaysLater = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
            returnDate = formatter.string(from: twoDaysLater)
        }
    }
    
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
            // Calculate return date based on departure date + 2 days
            return calculateDefaultReturnDate()
        }
    }
    
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
            // Update return date based on new departure date + 2 days
            returnDate = calculateDefaultReturnDate()
        }
    }
}
