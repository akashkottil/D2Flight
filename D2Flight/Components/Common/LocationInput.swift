import SwiftUI

struct LocationInput: View {
    @Binding var originLocation: String
    @Binding var destinationLocation: String
    @Binding var isSelectingOrigin: Bool
    @Binding var searchText: String
    
    @FocusState private var focusedField: Field?
    
    @State private var swapButtonRotationAngle: Double = 0
    
    // NEW: Parameters to control rental-specific behavior
    let isFromRental: Bool
    let isSameDropOff: Bool
    let isFromHotel: Bool
    
    enum Field {
        case origin, destination
    }
    
    // Default initializer for FlightView (maintains backward compatibility)
    init(
        originLocation: Binding<String>,
        destinationLocation: Binding<String>,
        isSelectingOrigin: Binding<Bool>,
        searchText: Binding<String>
    ) {
        self._originLocation = originLocation
        self._destinationLocation = destinationLocation
        self._isSelectingOrigin = isSelectingOrigin
        self._searchText = searchText
        self.isFromRental = false
        self.isSameDropOff = true
        self.isFromHotel = false // ADD this line
    }
    
    // New initializer for RentalView
    init(
        originLocation: Binding<String>,
        destinationLocation: Binding<String>,
        isSelectingOrigin: Binding<Bool>,
        searchText: Binding<String>,
        isFromRental: Bool,
        isSameDropOff: Bool
    ) {
        self._originLocation = originLocation
        self._destinationLocation = destinationLocation
        self._isSelectingOrigin = isSelectingOrigin
        self._searchText = searchText
        self.isFromRental = isFromRental
        self.isSameDropOff = isSameDropOff
        self.isFromHotel = false // ADD this line
    }
    
    // NEW: Hotel initializer
    init(
        originLocation: Binding<String>,
        destinationLocation: Binding<String>,
        isSelectingOrigin: Binding<Bool>,
        searchText: Binding<String>,
        isFromHotel: Bool
    ) {
        self._originLocation = originLocation
        self._destinationLocation = destinationLocation
        self._isSelectingOrigin = isSelectingOrigin
        self._searchText = searchText
        self.isFromRental = false
        self.isSameDropOff = true
        self.isFromHotel = isFromHotel
    }
    
    // Computed properties for dynamic text based on source
    private var originPlaceholder: String {
        if isFromHotel {
            return "Enter Hotel Location"
        } else if isFromRental {
            return "Enter Pick-up Location"
        } else {
            return "Enter Departure"
        }
    }
    
    private var destinationPlaceholder: String {
        if isFromRental {
            return "Enter Drop-off Location"
        } else {
            return "Enter Destination"
        }
    }
    
    // Determine if destination section should be shown
    private var shouldShowDestination: Bool {
        if isFromHotel {
            return false // Hotel only shows origin (location)
        } else if isFromRental && isSameDropOff {
            return false // Hide destination for rental same drop-off
        }
        return true // Show for flight view and rental different drop-off
    }
    
    // Determine if swap button should be shown
    private var shouldShowSwapButton: Bool {
        if isFromHotel {
            return false // No swap for hotel
        } else if isFromRental && isSameDropOff {
            return false // Hide swap button for rental same drop-off
        }
        return true // Show for flight view and rental different drop-off
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 1) {
                // Origin/Pick-up section (always visible)
                HStack {
                    Image("DepartureLightIcon")
                        .resizable()
                        .frame(width: 20, height: 20)
                    TextField(originPlaceholder, text: isSelectingOrigin ? $searchText : $originLocation)
                        .focused($focusedField, equals: .origin)
                        .onChange(of: focusedField) { newValue in
                            if newValue == .origin {
                                isSelectingOrigin = true
                                searchText = originLocation
                            }
                        }
                        .foregroundColor(originLocation.isEmpty ? .gray : .black)
                        .fontWeight(originLocation.isEmpty ? .medium : .semibold)
                        .font(CustomFont.font(.regular))
                    
                    // Clear button for origin
                    if !(isSelectingOrigin ? searchText.isEmpty : originLocation.isEmpty) {
                        Button(action: {
                            if isSelectingOrigin {
                                searchText = ""
                            } else {
                                originLocation = ""
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                    Spacer()
                }
                .padding(.vertical, 18)
                .padding(.horizontal)
                
                // Destination section (conditionally visible)
                if shouldShowDestination {
                    Divider()
                        .background(Color.gray.opacity(0.5))
                        .padding(.leading)
                        .padding(.trailing, shouldShowSwapButton ? 70 : 0)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    
                    HStack {
                        Image("DestinationLightIcon")
                            .resizable()
                            .frame(width: 20, height: 20)
                        TextField(destinationPlaceholder, text: !isSelectingOrigin ? $searchText : $destinationLocation)
                            .focused($focusedField, equals: .destination)
                            .onChange(of: focusedField) { newValue in
                                if newValue == .destination {
                                    isSelectingOrigin = false
                                    searchText = destinationLocation
                                }
                            }
                            .foregroundColor(destinationLocation.isEmpty ? .gray : .black)
                            .fontWeight(destinationLocation.isEmpty ? .medium : .semibold)
                            .font(CustomFont.font(.regular))
                        
                        // Clear button for destination
                        if !(!isSelectingOrigin ? searchText.isEmpty : destinationLocation.isEmpty) {
                            Button(action: {
                                if !isSelectingOrigin {
                                    searchText = ""
                                } else {
                                    destinationLocation = ""
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .background(.gray.opacity(0.1))
            .cornerRadius(12)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: shouldShowDestination)
            
            // 🔄 Swap Button (conditionally visible)
            if shouldShowSwapButton {
                Button(action: {
                    let temp = originLocation
                    originLocation = destinationLocation
                    destinationLocation = temp
                    
                    // Update searchText to match current field
                    if isSelectingOrigin {
                        searchText = originLocation
                    } else {
                        searchText = destinationLocation
                    }
                    
                    // 🔁 Rotate swap icon
                    withAnimation(.easeInOut(duration: 0.3)) {
                        swapButtonRotationAngle -= 180
                    }
                }) {
                    Image("SwapIcon")
                        .rotationEffect(.degrees(swapButtonRotationAngle))
                }
                .offset(x: 135)
                .shadow(color: .purple.opacity(0.3), radius: 5)
                .transition(.opacity.combined(with: .scale))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: shouldShowSwapButton)
            }
        }
        .padding()
        .onAppear {
            // Set focus based on mode
            if isFromHotel || (isFromRental && isSameDropOff) {
                focusedField = .origin // Only focus on origin for hotel or same drop-off
            } else {
                focusedField = .origin // Default behavior
            }
        }
    }
}
