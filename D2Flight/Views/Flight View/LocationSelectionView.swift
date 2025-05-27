import SwiftUI

struct LocationSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var originLocation: String
    @Binding var destinationLocation: String
    @StateObject private var viewModel = LocationViewModel()
    
    
    
    var onLocationSelected: (String, Bool) -> Void // location, isOrigin
    
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
                
                Text(viewModel.getCurrentTitle())
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
            searchText: $viewModel.searchText
            )



            Divider()
            
            // Search Input
//            HStack {
//                Image(viewModel.isSelectingOrigin ? "DepartureLightIcon" : "DestinationLightIcon")
//                    .resizable()
//                    .frame(width: 20, height: 20)
//                
//                TextField(viewModel.getCurrentPlaceholder(), text: $viewModel.searchText)
//                    .font(.system(size: 16))
//                    .textFieldStyle(PlainTextFieldStyle())
//                
//                if viewModel.isLoading {
//                    ProgressView()
//                        .scaleEffect(0.8)
//                }
//            }
//            .padding()
//            .background(Color.gray.opacity(0.1))
//            .cornerRadius(8)
//            .padding(.horizontal)
//            .padding(.top)
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            // Search Results
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.locations.isEmpty && !viewModel.searchText.isEmpty && !viewModel.isLoading {
                        // No results found
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text("No locations found")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            
                            Text("Try searching with a different keyword")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(viewModel.locations, id: \.id) { location in
                            LocationRowView(location: location) {
                                selectLocation(location)
                            }
                        }
                    }
                }
                .padding(.top, 24)
            }
            
            Spacer()
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .background(Color.gray.opacity(0.05))
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.resetToOriginSelection()
        }
    }
    
    private func selectLocation(_ location: Location) {
        if viewModel.isSelectingOrigin {
            originLocation = location.displayName
            viewModel.isSelectingOrigin = false
            viewModel.searchText = destinationLocation // Prepare destination search text (can be empty or last typed)
        } else {
            destinationLocation = location.displayName
            onLocationSelected(destinationLocation, false)
            presentationMode.wrappedValue.dismiss()
        }
    }

}

// MARK: - Location Row View (Updated)
struct LocationRowView: View {
    let location: Location
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Location Icon based on type
                Image(location.type == "airport" ? "FlightIcon" : "HotelIcon")
                    .foregroundColor(Color("Violet"))
                    .font(.system(size: 18))
                    .frame(width: 24, height: 24)
                
                // Location Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if location.type == "airport" {
                            Text(location.airportName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text("(\(location.iataCode))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        } else {
                            Text(location.cityName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    
                    Text(location.displayName)
                        .font(.system(size: 14))
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
    ) { _, _ in }
}


