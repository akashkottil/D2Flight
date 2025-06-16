import SwiftUI

struct LocationSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var originLocation: String
    @Binding var destinationLocation: String
    @StateObject private var viewModel = LocationViewModel()
    
    @State private var originIATACode = ""
    @State private var destinationIATACode = ""
    
    // NEW: Parameters to identify source and mode
    let isFromRental: Bool
    let isSameDropOff: Bool
    
    // Updated closure to include IATA code
    var onLocationSelected: (String, Bool, String) -> Void // location, isOrigin, iataCode
    
    // Default initializer for FlightView (maintains backward compatibility)
    init(
        originLocation: Binding<String>,
        destinationLocation: Binding<String>,
        onLocationSelected: @escaping (String, Bool, String) -> Void
    ) {
        self._originLocation = originLocation
        self._destinationLocation = destinationLocation
        self.onLocationSelected = onLocationSelected
        self.isFromRental = false
        self.isSameDropOff = true
    }
    
    // New initializer for RentalView
    init(
        originLocation: Binding<String>,
        destinationLocation: Binding<String>,
        isFromRental: Bool,
        isSameDropOff: Bool,
        onLocationSelected: @escaping (String, Bool, String) -> Void
    ) {
        self._originLocation = originLocation
        self._destinationLocation = destinationLocation
        self.onLocationSelected = onLocationSelected
        self.isFromRental = isFromRental
        self.isSameDropOff = isSameDropOff
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image("BlackArrow")
                        .padding(.horizontal)
                }
                
                Text(getHeaderTitle())
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.trailing, 44)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Current Selection Display
            LocationInput(
                originLocation: $originLocation,
                destinationLocation: $destinationLocation,
                isSelectingOrigin: $viewModel.isSelectingOrigin,
                searchText: $viewModel.searchText,
                isFromRental: isFromRental,
                isSameDropOff: isSameDropOff
            )

            Divider()
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(CustomFont.font(.regular))
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            // Content Area
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Section Header (only show if there are results)
                    if !viewModel.getSectionTitle().isEmpty {
                        HStack {
                            Text(viewModel.getSectionTitle())
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.gray)
                            Spacer()
                            
                            // Show clear recent locations button for recent searches
                            if viewModel.shouldShowRecentLocations {
                                Button("Clear") {
                                    RecentLocationsManager.shared.clearRecentLocations()
                                }
                                .font(CustomFont.font(.regular, weight: .medium))
                                .foregroundColor(Color("Violet"))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                    }
                    
                    // Recent Locations Section
                    if viewModel.shouldShowRecentLocations {
                        ForEach(viewModel.recentLocations, id: \.id) { recentLocation in
                            RecentLocationRowView(recentLocation: recentLocation) {
                                selectRecentLocation(recentLocation)
                            }
                        }
                    }
                    
                    // Autocomplete Results Section
                    if viewModel.shouldShowAutocomplete {
                        ForEach(viewModel.locations, id: \.id) { location in
                            LocationRowView(location: location) {
                                selectLocation(location)
                            }
                        }
                    }
                    
                    // Empty State
                    if viewModel.shouldShowEmptyState {
                        let emptyState = viewModel.getEmptyStateMessage()
                        VStack(spacing: 12) {
                            Image(systemName: viewModel.showingRecentLocations ? "clock" : "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text(emptyState.title)
                                .font(CustomFont.font(.medium))
                                .foregroundColor(.gray)
                            
                            Text(emptyState.subtitle)
                                .font(CustomFont.font(.regular))
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 40)
                    }
                    
                    // Loading State
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Searching locations...")
                                .font(CustomFont.font(.regular))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(.bottom, 24)
            }
            
            Spacer()
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .background(Color.gray.opacity(0.05))
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            // For rental same drop-off, start with destination selection disabled
            if isFromRental && isSameDropOff {
                viewModel.isSelectingOrigin = true
            } else {
                viewModel.resetToOriginSelection()
            }
            print("📱 LocationSelectionView appeared - isFromRental: \(isFromRental), isSameDropOff: \(isSameDropOff)")
        }
    }
    
    private func selectLocation(_ location: Location) {
        if viewModel.isSelectingOrigin {
            originLocation = location.airportName
            originIATACode = location.iataCode
            print("✈️ Origin selected: \(location.displayName) (\(location.iataCode))")
            onLocationSelected(location.airportName, true, location.iataCode)
            
            // For rental same drop-off, close immediately after selecting pickup
            if isFromRental && isSameDropOff {
                let shouldClose = viewModel.selectLocation(location)
                presentationMode.wrappedValue.dismiss()
            } else {
                _ = viewModel.selectLocation(location)
            }
        } else {
            destinationLocation = location.airportName
            destinationIATACode = location.iataCode
            print("🎯 Destination selected: \(location.displayName) (\(location.iataCode))")
            onLocationSelected(location.airportName, false, location.iataCode)
            let shouldClose = viewModel.selectLocation(location)
            if shouldClose {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func selectRecentLocation(_ recentLocation: RecentLocation) {
        let location = recentLocation.toLocation()
        selectLocation(location)
    }
    
    private func getHeaderTitle() -> String {
        if isFromRental {
            if isSameDropOff {
                return "Select pick-up location"
            } else {
                return viewModel.isSelectingOrigin ? "Select pick-up location" : "Select drop-off location"
            }
        } else {
            return viewModel.isSelectingOrigin ? "Select departure location" : "Select destination location"
        }
    }
}

// MARK: - Recent Location Row View (unchanged)
struct RecentLocationRowView: View {
    let recentLocation: RecentLocation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Recent location icon (different from regular locations)
                ZStack {
                    Circle()
                        .fill(Color("Violet").opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(Color("Violet"))
                        .font(CustomFont.font(.regular, weight: .medium))
                }
                
                // Location Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if recentLocation.type == "airport" {
                            Text(recentLocation.airportName)
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text("(\(recentLocation.iataCode))")
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.black)
                        } else {
                            Text(recentLocation.cityName)
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        // Empty for now - removed commented code
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Location Row View (unchanged)
struct LocationRowView: View {
    let location: Location
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Location Icon based on type
                Image(location.type == "airport" ? "FlightIcon" : "HotelIcon")
                    .foregroundColor(Color("Violet"))
                    .font(CustomFont.font(.large))
                    .frame(width: 24, height: 24)
                
                // Location Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if location.type == "airport" {
                            Text(location.airportName)
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text("(\(location.iataCode))")
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.black)
                        } else {
                            Text(location.cityName)
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    
                    Text(location.displayName)
                        .font(CustomFont.font(.regular))
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LocationSelectionView(
        originLocation: .constant("New York, United States"),
        destinationLocation: .constant("")
    ) { _, _, _ in }
}
