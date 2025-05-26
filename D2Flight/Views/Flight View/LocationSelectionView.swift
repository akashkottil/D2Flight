import SwiftUI

struct LocationSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: LocationSearchViewModel
    
    var onLocationSelected: (LocationSearchViewModel) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Location Input Section
            locationInputSection
            
            Divider()
            
            // Search Results or Empty State
            if viewModel.isSearching {
                loadingSection
            } else if viewModel.hasError {
                errorSection
            } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                emptyResultsSection
            } else if !viewModel.searchResults.isEmpty {
                searchResultsSection
            } else {
                recentSearchesSection
            }
            
            Spacer()
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .background(Color.gray.opacity(0.05))
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            // Set initial search text based on current selection type
            viewModel.updateSearchText(viewModel.getCurrentInputText())
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image("BlackArrow")
                    .padding(.horizontal)
            }
            
            Text("Select location")
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.trailing, 44)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Location Input Section
    private var locationInputSection: some View {
        VStack(spacing: 1) {
            // Origin Input
            HStack {
                Image("DepartureLightIcon")
                    .resizable()
                    .frame(width: 20, height: 20)
                
                if viewModel.currentSelectionType == .origin {
                    TextField("Enter Departure", text: $viewModel.searchText)
                        .foregroundColor(.black)
                        .fontWeight(.semibold)
                        .font(.system(size: 14))
                } else {
                    Text(viewModel.originDisplayText)
                        .foregroundColor(viewModel.originSelection.location != nil ? .black : .gray)
                        .fontWeight(viewModel.originSelection.location != nil ? .semibold : .medium)
                        .font(.system(size: 14))
                        .onTapGesture {
                            viewModel.setSelectionType(.origin)
                        }
                }
                
                Spacer()
            }
            .padding(.vertical, 18)
            .padding(.horizontal)
            .background(viewModel.currentSelectionType == .origin ? Color.blue.opacity(0.1) : Color.clear)
            
            Divider()
                .background(Color.gray.opacity(0.5))
                .padding(.leading)
                .padding(.trailing, 70)
            
            // Destination Input
            HStack {
                Image("DestinationLightIcon")
                    .resizable()
                    .frame(width: 20, height: 20)
                
                if viewModel.currentSelectionType == .destination {
                    TextField("Enter Destination", text: $viewModel.searchText)
                        .foregroundColor(.black)
                        .fontWeight(.semibold)
                        .font(.system(size: 14))
                } else {
                    Text(viewModel.destinationDisplayText)
                        .foregroundColor(viewModel.destinationSelection.location != nil ? .black : .gray)
                        .fontWeight(viewModel.destinationSelection.location != nil ? .semibold : .medium)
                        .font(.system(size: 14))
                        .onTapGesture {
                            viewModel.setSelectionType(.destination)
                        }
                }
                
                Spacer()
            }
            .padding(.vertical, 18)
            .padding(.horizontal)
            .background(viewModel.currentSelectionType == .destination ? Color.blue.opacity(0.1) : Color.clear)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            // Swap Button
            Button(action: {
                viewModel.swapLocations()
            }) {
                Image("SwapIcon")
            }
            .offset(x: 135)
            .shadow(color: .purple.opacity(0.3), radius: 5)
        )
        .padding()
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching locations...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    // MARK: - Error Section
    private var errorSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Search Error")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            Text(viewModel.errorMessage)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                viewModel.performSearch(query: viewModel.searchText)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color("Violet"))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    // MARK: - Empty Results Section
    private var emptyResultsSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No locations found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            Text("Try searching with a different term")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    // MARK: - Search Results Section
    private var searchResultsSection: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.searchResults) { location in
                    LocationRowView(location: location) {
                        selectLocation(location)
                    }
                }
            }
            .padding(.top, 24)
        }
    }
    
    // MARK: - Recent Searches Section (Placeholder)
    private var recentSearchesSection: some View {
        VStack(spacing: 16) {
            Text("Recent Searches")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            
            Text("Start typing to search for locations")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }
    
    // MARK: - Helper Methods
    private func selectLocation(_ location: Location) {
        viewModel.selectLocation(location)
        
        // Auto-close if both locations are selected or if destination is selected
        if viewModel.canSearch || viewModel.currentSelectionType == .destination {
            onLocationSelected(viewModel)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Location Row View
struct LocationRowView: View {
    let location: Location
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Location Type Icon
                Image(location.type.iconName)
                    .foregroundColor(Color("Violet"))
                    .font(.system(size: 18))
                    .frame(width: 24, height: 24)
                
                // Location Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if location.type == .airport {
                            Text(location.airportName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text("(\(location.iataCode))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        } else {
                            Text(location.airportName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    
                    Text("\(location.cityName), \(location.countryName)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
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
    @StateObject var viewModel = LocationSearchViewModel()
    
    return LocationSelectionView(viewModel: viewModel) { _ in
        print("Location selected")
    }
}
