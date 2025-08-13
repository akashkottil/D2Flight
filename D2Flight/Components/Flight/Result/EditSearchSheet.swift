import SwiftUI

struct EditSearchSheet: View {
    @Binding var isPresented: Bool
    
    // Search parameters - these will be bound to the parent
    @Binding var isOneWay: Bool
    @Binding var originLocation: String
    @Binding var destinationLocation: String
    @Binding var originIATACode: String
    @Binding var destinationIATACode: String
    @Binding var selectedDates: [Date]
    @Binding var travelersCount: String
    @Binding var adults: Int
    @Binding var children: Int
    @Binding var infants: Int
    @Binding var selectedClass: TravelClass
    
    // Internal states for sheet functionality
    @State private var showPassengerSheet = false
    @State private var showLocationPicker = false
    @State private var showDatePicker = false
    @State private var swapButtonRotationAngle: Double = 0
    
    // Action closure for when search is updated
    let onSearchUpdated: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay - close on tap
            Color.black.opacity(0.3)
                .ignoresSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            
            // Sheet content
            VStack(spacing: 0) {
                // MARK: - Top Handle and Header
                VStack(spacing: 0) {
                    // Drag handle
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                    
                    // Header
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }) {
                            Image("BlackArrow")
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        Text("Edit Search")
                            .font(.system(size: 20, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        
                        // Invisible spacer to balance the layout
                        Spacer()
                            .frame(width: 44)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .background(Color.white)
                
                Divider()
                
                // MARK: - Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Trip Type Tabs
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
                                            } else {
                                                Color("Violet").opacity(0.15)
                                            }
                                        }
                                    )
                                    .cornerRadius(100)
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        // MARK: - Location Section
                        ZStack {
                            Button(action: {
                                showLocationPicker = true
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
                            
                            // Swap Button
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
                        
                        // MARK: - Date Section
                        VStack(spacing: 0) {
                            HStack(spacing: 10) {
                                // Departure Date
                                Button(action: {
                                    showDatePicker = true
                                }) {
                                    HStack {
                                        Image("CalenderIcon")
                                            .frame(width: 20, height: 20)
                                        Text(formatSelectedDate(for: .departure))
                                            .foregroundColor(.gray)
                                            .fontWeight(.medium)
                                            .font(CustomFont.font(.regular))
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                }
                                
                                // Return Date (conditional)
                                Group {
                                    if !isOneWay {
                                        Button(action: {
                                            showDatePicker = true
                                        }) {
                                            HStack {
                                                Image("CalenderIcon")
                                                    .frame(width: 20, height: 20)
                                                Text(formatSelectedDate(for: .return))
                                                    .foregroundColor(.gray)
                                                    .fontWeight(.medium)
                                                    .font(CustomFont.font(.regular))
                                                Spacer()
                                            }
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(12)
                                        }
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
                        
                        // MARK: - Passenger Section
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
                        .buttonStyle(PlainButtonStyle())
                        
                        // MARK: - Update Search Button
                        PrimaryButton(
                            title: "Update Search",
                            font: CustomFont.font(.medium),
                            fontWeight: .bold,
                            textColor: .white,
                            verticalPadding: 20,
                            cornerRadius: 16,
                            action: {
                                // Call the update action
                                onSearchUpdated()
                                
                                // Close the sheet with animation
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            }
                        )
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .background(Color.gray.opacity(0.05))
                
                Spacer()
            }
            .background(Color.white)
            .cornerRadius(16)
            .ignoresSafeArea(.all, edges: .bottom)
            .padding(.top, 60) // Account for safe area
            .onTapGesture {
                // Prevent closing when tapping on the sheet content
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
        .fullScreenCover(isPresented: $showDatePicker) {
            DateSelectionView(
                selectedDates: $selectedDates,
                isRoundTrip: !isOneWay
            ) { updatedDates in
                selectedDates = updatedDates
            }
        }
        .fullScreenCover(isPresented: $showLocationPicker) {
            LocationSelectionView(
                originLocation: $originLocation,
                destinationLocation: $destinationLocation
            ) { selectedLocation, isOrigin, iataCode in
                if isOrigin {
                    originLocation = selectedLocation
                    originIATACode = iataCode
                    print("📍 Origin updated: \(selectedLocation) (\(iataCode))")
                } else {
                    destinationLocation = selectedLocation
                    destinationIATACode = iataCode
                    print("📍 Destination updated: \(selectedLocation) (\(iataCode))")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    enum CalendarDateType {
        case departure
        case `return`
    }
    
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
            // Calculate return date based on departure date + 2 days
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
}

#Preview {
    EditSearchSheet(
        isPresented: .constant(true),
        isOneWay: .constant(false),
        originLocation: .constant("New York"),
        destinationLocation: .constant("London"),
        originIATACode: .constant("NYC"),
        destinationIATACode: .constant("LHR"),
        selectedDates: .constant([Date(), Calendar.current.date(byAdding: .day, value: 7, to: Date())!]),
        travelersCount: .constant("2 Travelers, Economy"),
        adults: .constant(2),
        children: .constant(0),
        infants: .constant(0),
        selectedClass: .constant(.economy),
        onSearchUpdated: {
            print("Search updated")
        }
    )
}

// MARK: - Custom Transition for Top-to-Bottom Sheet
struct TopToBottomTransition: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .offset(y: isPresented ? 0 : -UIScreen.main.bounds.height)
            .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

extension View {
    func topToBottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ZStack {
            self
            
            if isPresented.wrappedValue {
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented.wrappedValue = false
                        }
                    }
                
                // Sheet content
                VStack {
                    content()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Spacer()
                }
                .padding(.top, 60) // Account for safe area
                .modifier(TopToBottomTransition(isPresented: isPresented.wrappedValue))
            }
        }
    }
}

#Preview {
    EditSearchSheet(
        isPresented: .constant(true),
        isOneWay: .constant(false),
        originLocation: .constant("New York"),
        destinationLocation: .constant("London"),
        originIATACode: .constant("NYC"),
        destinationIATACode: .constant("LHR"),
        selectedDates: .constant([Date(), Calendar.current.date(byAdding: .day, value: 7, to: Date())!]),
        travelersCount: .constant("2 Travelers, Economy"),
        adults: .constant(2),
        children: .constant(0),
        infants: .constant(0),
        selectedClass: .constant(.economy),
        onSearchUpdated: {
            print("Search updated")
        }
    )
}
