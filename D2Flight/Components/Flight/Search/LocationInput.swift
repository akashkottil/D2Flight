import SwiftUI

struct LocationInput: View {
    @ObservedObject var viewModel: LocationSearchViewModel
    
    var body: some View {
        ZStack {
            VStack(spacing: 1) {
                // Origin Input Row
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

                // Divider
                Divider()
                    .background(Color.gray.opacity(0.5))
                    .padding(.leading)
                    .padding(.trailing, 70)
                    
                // Destination Input Row
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
            .background(.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Swap Button
            Button(action: {
                viewModel.swapLocations()
            }) {
                Image("SwapIcon")
            }
            .offset(x: 135)
            .shadow(color: .purple.opacity(0.3), radius: 5)
        }
        .padding()
    }
}

// MARK: - Preview
struct LocationInput_Previews: PreviewProvider {
    @StateObject static var viewModel = LocationSearchViewModel()

    static var previews: some View {
        LocationInput(viewModel: viewModel)
            .padding()
            .previewLayout(.sizeThatFits)
            .onAppear {
                // Set some sample data for preview
                viewModel.originSelection = LocationSelection(location: Location(
                    iataCode: "COK",
                    airportName: "Kochi",
                    type: .city,
                    displayName: "Kochi, Kerala, India",
                    cityName: "Kochi",
                    countryName: "India",
                    countryCode: "IN",
                    imageUrl: "",
                    coordinates: Coordinates(latitude: "9.9312", longitude: "76.2673")
                ))
            }
    }
}
