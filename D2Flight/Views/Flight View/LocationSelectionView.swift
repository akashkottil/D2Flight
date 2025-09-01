import SwiftUI

// MARK: - LocationSelectionView
struct LocationSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var originLocation: String
    @Binding var destinationLocation: String
    @StateObject private var viewModel = LocationViewModel()
    
    @State private var originIATACode = ""
    @State private var destinationIATACode = ""
    
    let isFromFlight: Bool
        let isFromHotel: Bool
        let isFromRental: Bool
        let isSameDropOff: Bool
        let serviceType: LocationService
    
    // Updated closure to include IATA code
    var onLocationSelected: (String, Bool, String) -> Void // location, isOrigin, iataCode
    
    init(
            originLocation: Binding<String>,
            destinationLocation: Binding<String>,
            isFromFlight: Bool = false,
            isFromHotel: Bool = false,
            isFromRental: Bool = false,
            isSameDropOff: Bool = true,
            serviceType: LocationService = .flight,
            onLocationSelected: @escaping (String, Bool, String) -> Void
        ) {
            self._originLocation = originLocation
            self._destinationLocation = destinationLocation
            self.isFromFlight = isFromFlight
            self.isFromHotel = isFromHotel
            self.isFromRental = isFromRental
            self.isSameDropOff = isSameDropOff
            self.serviceType = serviceType
            self.onLocationSelected = onLocationSelected
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
            Group {
                if isFromHotel {
                    LocationInput(
                        originLocation: $originLocation,
                        destinationLocation: $destinationLocation,
                        isSelectingOrigin: $viewModel.isSelectingOrigin,
                        searchText: $viewModel.searchText,
                        isFromHotel: true
                    )
                } else if isFromRental {
                    LocationInput(
                        originLocation: $originLocation,
                        destinationLocation: $destinationLocation,
                        isSelectingOrigin: $viewModel.isSelectingOrigin,
                        searchText: $viewModel.searchText,
                        isFromRental: true,
                        isSameDropOff: isSameDropOff
                    )
                } else {
                    // Flight / default
                    LocationInput(
                        originLocation: $originLocation,
                        destinationLocation: $destinationLocation,
                        isSelectingOrigin: $viewModel.isSelectingOrigin,
                        searchText: $viewModel.searchText
                    )
                }
            }


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
                            Text("searching.locations".localized)
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
            viewModel.serviceType = serviceType
            if isFromRental && isSameDropOff {
                viewModel.isSelectingOrigin = true
            } else {
                viewModel.resetToOriginSelection()
            }
            print("📱 LocationSelectionView appeared - isFromRental: \(isFromRental), isSameDropOff: \(isSameDropOff)")
        }
    }
    
    private func selectLocation(_ location: Location) {
        if isFromHotel {
                // ✅ CORRECT: Pass full display name and city name
                let fullDisplayName = location.displayName    // "Malacca, Malaysia"
                let cityName = location.cityName              // "Malacca"
                
                print("🏨 Hotel location selection debug:")
                print("   Full Display Name: \(fullDisplayName)")
                print("   City Name: \(cityName)")
                print("   Country Name: \(location.countryName)")
                
                // Update bindings
                originLocation = fullDisplayName              // ✅ "Malacca, Malaysia"
                originIATACode = cityName                     // ✅ "Malacca"
                
                print("🏨 Hotel location selected: \(fullDisplayName) (\(cityName))")
                onLocationSelected(fullDisplayName, true, cityName)  // ✅ CORRECT
                presentationMode.wrappedValue.dismiss()
                return
            }
        if viewModel.isSelectingOrigin {
            originLocation = location.airportName
            originIATACode = location.iataCode
            print("✈️ Origin selected: \(location.displayName) (\(location.iataCode))")
            onLocationSelected(location.airportName, true, location.iataCode)
            
            if isFromRental && isSameDropOff {
                _ = viewModel.selectLocation(location)
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
        if isFromHotel {
            return "Select hotel location"
        } else if isFromRental {
            if isSameDropOff {
                return "Select pick-up location"
            } else {
                return viewModel.isSelectingOrigin ? "Select pick-up location" : "Select drop-off location"
            }
        } else {
            return viewModel.isSelectingOrigin ? "select.departure.location".localized : "select.destination.location".localized
        }
    }
}

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
                
                // Location Info - Updated Design
                VStack(alignment: .leading, spacing: 4) {
                    // First Line: Full Name or Primary Text
                    HStack {
                        Text(getPrimaryText())
                            .font(CustomFont.font(.medium, weight: .semibold))
                            .foregroundColor(.black)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    
                    // Second Line: Secondary Text based on type
                    HStack {
                        Text(getSecondaryText())
                            .font(CustomFont.font(.regular))
                            .foregroundColor(.gray)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods for Type-Specific Formatting
    
    private func getPrimaryText() -> String {
        switch location.type {
        case "city":
            return location.displayName // Full name as is
            
        case "airport":
            // For airports, the displayName already contains the airport code
            // Just remove duplicate city names from the fullName/displayName
            return removeDuplicateCityNames(from: location.displayName)
            
        case "hotel":
            return location.displayName // Full hotel name
            
        default:
            return location.displayName
        }
    }
    
    private func getSecondaryText() -> String {
        switch location.type {
        case "city":
            // Format: cityName, countryName
            let components = [location.cityName, location.countryName]
                .filter { !$0.isEmpty }
            return components.joined(separator: ", ")
            
        case "airport":
            // Just city name
            return location.cityName
            
        case "hotel":
            // Format: cityName, regionName, countryName
            // Use displayName parsing if regionName is not available directly
            let components = parseHotelSecondaryInfo()
            return components.joined(separator: ", ")
            
        default:
            return location.displayName
        }
    }
    
    // MARK: - Helper Functions
    
    private func removeDuplicateCityNames(from fullName: String) -> String {
        let components = fullName.components(separatedBy: ", ")
        var uniqueComponents: [String] = []
        var seenComponents: Set<String> = []
        
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
            if !seenComponents.contains(trimmed.lowercased()) {
                uniqueComponents.append(trimmed)
                seenComponents.insert(trimmed.lowercased())
            }
        }
        
        return uniqueComponents.joined(separator: ", ")
    }
    
    private func parseHotelSecondaryInfo() -> [String] {
        // For hotels, try to build: cityName, regionName, countryName
        var components: [String] = []
        
        // Add city name if available and not empty
        if !location.cityName.isEmpty {
            components.append(location.cityName)
        }
        
        // For region name, we might need to extract it from displayName
        // since the Location model might not have regionName directly
        if let regionName = extractRegionFromDisplayName() {
            components.append(regionName)
        }
        
        // Add country name if available and not empty
        if !location.countryName.isEmpty {
            components.append(location.countryName)
        }
        
        // Remove duplicates while preserving order
        var uniqueComponents: [String] = []
        var seenComponents: Set<String> = []
        
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
            if !seenComponents.contains(trimmed.lowercased()) && !trimmed.isEmpty {
                uniqueComponents.append(trimmed)
                seenComponents.insert(trimmed.lowercased())
            }
        }
        
        return uniqueComponents
    }
    
    private func extractRegionFromDisplayName() -> String? {
        // Try to extract region from displayName
        // Example: "Hotel Name, City, Region, Country" -> "Region"
        let components = location.displayName.components(separatedBy: ", ")
        
        // For hotels, if we have more than 2 components, the middle ones might be regions
        if components.count >= 3 {
            // Skip first (hotel name) and last (country), take middle as region
            let middleComponents = Array(components[1..<components.count-1])
            
            // Filter out components that match city name or country name to find region
            let regionCandidates = middleComponents.filter { component in
                let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmed.isEmpty &&
                       trimmed.lowercased() != location.cityName.lowercased() &&
                       trimmed.lowercased() != location.countryName.lowercased()
            }
            
            return regionCandidates.first?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
}

// MARK: - Recent Location Row View (Updated to Match LocationRowView)
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
                
                // Location Info - Updated to Match LocationRowView
                VStack(alignment: .leading, spacing: 4) {
                    // First Line: Primary Text (same logic as LocationRowView)
                    HStack {
                        Text(getRecentPrimaryText())
                            .font(CustomFont.font(.medium, weight: .semibold))
                            .foregroundColor(.black)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    
                    // Second Line: Secondary Text (same logic as LocationRowView)
                    HStack {
                        Text(getRecentSecondaryText())
                            .font(CustomFont.font(.regular))
                            .foregroundColor(.gray)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods for Recent Location Formatting
    
    private func getRecentPrimaryText() -> String {
        switch recentLocation.type {
        case "city":
            return recentLocation.displayName
            
        case "airport":
            // For airports, use displayName and remove duplicates
            return removeDuplicateCityNamesForRecent(from: recentLocation.displayName)
            
        case "hotel":
            return recentLocation.displayName
            
        default:
            return recentLocation.displayName
        }
    }
    
    private func getRecentSecondaryText() -> String {
        switch recentLocation.type {
        case "city":
            // Format: cityName, countryName
            let components = [recentLocation.cityName, recentLocation.countryName]
                .filter { !$0.isEmpty }
            return components.joined(separator: ", ")
            
        case "airport":
            // Just city name
            return recentLocation.cityName
            
        case "hotel":
            // Format: cityName, countryName (simplified for recent)
            let components = [recentLocation.cityName, recentLocation.countryName]
                .filter { !$0.isEmpty }
            return components.joined(separator: ", ")
            
        default:
            return recentLocation.displayName
        }
    }
    
    private func removeDuplicateCityNamesForRecent(from fullName: String) -> String {
        let components = fullName.components(separatedBy: ", ")
        var uniqueComponents: [String] = []
        var seenComponents: Set<String> = []
        
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
            if !seenComponents.contains(trimmed.lowercased()) {
                uniqueComponents.append(trimmed)
                seenComponents.insert(trimmed.lowercased())
            }
        }
        
        return uniqueComponents.joined(separator: ", ")
    }
}

// MARK: - Preview
#Preview {
    LocationSelectionView(
        originLocation: .constant("New York, United States"),
        destinationLocation: .constant("")
    ) { _, _, _ in }
}


