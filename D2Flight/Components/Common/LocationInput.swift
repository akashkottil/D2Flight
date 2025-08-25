import SwiftUI

struct LocationInput: View {
    @Binding var originLocation: String
    @Binding var destinationLocation: String
    @Binding var isSelectingOrigin: Bool
    @Binding var searchText: String
    
    // Separate focus states to avoid enum churn
    @FocusState private var originFocused: Bool
    @FocusState private var destinationFocused: Bool
    
    // Stable per-field text (prevents swapping bindings)
    @State private var originText: String = ""
    @State private var destinationText: String = ""
    
    @State private var swapButtonRotationAngle: Double = 0
    
    // Parameters to control behavior
    let isFromRental: Bool
    let isSameDropOff: Bool
    let isFromHotel: Bool
    
    // Default initializer for FlightView
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
        self.isFromHotel = false
    }
    
    // Rental initializer
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
        self.isFromHotel = false
    }
    
    // Hotel initializer
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
    
    // Placeholders
    private var originPlaceholder: String {
        if isFromHotel { return "enter.hotel.location".localized }
        else if isFromRental { return "enter.pick-up.location".localized }
        else { return "enter.departure".localized }
    }
    
    private var destinationPlaceholder: String {
        if isFromRental { return "enter.drop-off.location".localized }
        else { return "enter.destination".localized }
    }
    
    // Visibility rules
    private var shouldShowDestination: Bool {
        if isFromHotel { return false }
        if isFromRental && isSameDropOff { return false }
        return true
    }
    
    private var shouldShowSwapButton: Bool {
        if isFromHotel { return false }
        if isFromRental && isSameDropOff { return false }
        return true
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 1) {
                // ORIGIN
                HStack {
                    Image("DepartureLightIcon")
                        .resizable()
                        .frame(width: 20, height: 20)
                    
                    TextField(originPlaceholder, text: $originText)
                        .focused($originFocused)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .foregroundColor(originText.isEmpty ? .gray : .black)
                        .fontWeight(originText.isEmpty ? .medium : .semibold)
                        .font(CustomFont.font(.regular))
                    
                    if !originText.isEmpty {
                        Button {
                            originText = ""
                            if originFocused { searchText = "" }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                    Spacer()
                }
                .padding(.vertical, 18)
                .padding(.horizontal)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !originFocused {
                        isSelectingOrigin = true
                        DispatchQueue.main.async { originFocused = true }
                    }
                }
                .onChange(of: originText) { newValue in
                    if originFocused { searchText = newValue }
                }
                
                // DESTINATION (conditional)
                if shouldShowDestination {
                    Divider()
                        .background(Color.gray.opacity(0.5))
                        .padding(.leading)
                        .padding(.trailing, shouldShowSwapButton ? 70 : 0)
                    
                    HStack {
                        Image("DestinationLightIcon")
                            .resizable()
                            .frame(width: 20, height: 20)
                        
                        TextField(destinationPlaceholder, text: $destinationText)
                            .focused($destinationFocused)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .foregroundColor(destinationText.isEmpty ? .gray : .black)
                            .fontWeight(destinationText.isEmpty ? .medium : .semibold)
                            .font(CustomFont.font(.regular))
                        
                        if !destinationText.isEmpty {
                            Button {
                                destinationText = ""
                                if destinationFocused { searchText = "" }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !destinationFocused {
                            isSelectingOrigin = false
                            DispatchQueue.main.async { destinationFocused = true }
                        }
                    }
                    .onChange(of: destinationText) { newValue in
                        if destinationFocused { searchText = newValue }
                    }
                }
            }
            .background(.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Swap (if visible)
            if shouldShowSwapButton {
                Button(action: {
                    let t = originText
                    originText = destinationText
                    destinationText = t
                    
                    if originFocused {
                        searchText = originText
                    } else if destinationFocused {
                        searchText = destinationText
                    }
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        swapButtonRotationAngle -= 180
                    }
                }) {
                    Image("SwapIcon")
                        .rotationEffect(.degrees(swapButtonRotationAngle))
                }
                .offset(x: 135)
                .shadow(color: .purple.opacity(0.3), radius: 5)
            }
        }
        .padding()
        .onAppear {
            // Seed UI text from the bound values
            originText = originLocation
            destinationText = destinationLocation
            
            // Auto-focus origin (async) if applicable
            if isFromHotel || (isFromRental && isSameDropOff) {
                DispatchQueue.main.async { originFocused = true }
            }
        }
        // Keep UI text in sync if parent updates these bindings externally
        .onChange(of: originLocation) { originText = $0 }
        .onChange(of: destinationLocation) { destinationText = $0 }
    }
}
