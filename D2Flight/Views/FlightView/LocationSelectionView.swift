

import SwiftUI

struct LocationSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var originLocation: String
    @Binding var destinationLocation: String
    @State private var searchText = ""
    @State private var isOriginSelection = true
    
    // Sample airport data - replace with real data later
    private let airports = [
        Airport(code: "LHR", name: "Heathrow", city: "England", country: "United Kingdom", type: .major),
        Airport(code: "STN", name: "Stansted", city: "England", country: "United Kingdom", type: .major),
        Airport(code: "LGW", name: "England", city: "England", country: "United Kingdom", type: .city),
        Airport(code: "LHR", name: "Heathrow", city: "England", country: "United Kingdom", type: .city),
        Airport(code: "LON", name: "London", city: "England", country: "United Kingdom", type: .city)
    ]
    
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
                
                Text("Select location")
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.trailing, 44)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Location Input Section
            VStack(spacing: 1) {
                // Origin Location
                Button(action: {
                    isOriginSelection = true
                }) {
                    HStack {
                        Image(systemName: "location.circle")
                            .foregroundColor(.gray)
                            .frame(width: 20, height: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if originLocation.isEmpty {
                                Text("New York, United States")
                                    .foregroundColor(.gray)
                                    .fontWeight(.medium)
                                    .font(.system(size: 14))
                            } else {
                                Text(originLocation)
                                    .foregroundColor(.black)
                                    .fontWeight(.bold)
                                    .font(.system(size: 14))
                            }
                        }
                        
                        Spacer()
                        
                        // Swap button
                        Button(action: {
                            let temp = originLocation
                            originLocation = destinationLocation
                            destinationLocation = temp
                        }) {
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(Color("Violet"))
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color("Violet").opacity(0.1))
                                )
                        }
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal)
                    .background(isOriginSelection ? Color("Violet").opacity(0.05) : Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.leading, 52)
                
                // Destination Location
                Button(action: {
                    isOriginSelection = false
                }) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.gray)
                            .frame(width: 20, height: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if destinationLocation.isEmpty {
                                Text("Drop-off location")
                                    .foregroundColor(.gray)
                                    .fontWeight(.medium)
                                    .font(.system(size: 14))
                            } else {
                                Text(destinationLocation)
                                    .foregroundColor(.black)
                                    .fontWeight(.bold)
                                    .font(.system(size: 14))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal)
                    .background(!isOriginSelection ? Color("Violet").opacity(0.05) : Color.clear)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Search Results
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredAirports, id: \.id) { airport in
                        AirportRowView(airport: airport) {
                            selectLocation(airport)
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
    }
    
    private var filteredAirports: [Airport] {
        if searchText.isEmpty {
            return airports
        } else {
            return airports.filter { airport in
                airport.name.localizedCaseInsensitiveContains(searchText) ||
                airport.city.localizedCaseInsensitiveContains(searchText) ||
                airport.code.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func selectLocation(_ airport: Airport) {
        let locationString = "\(airport.city), \(airport.country)"
        
        if isOriginSelection {
            originLocation = locationString
        } else {
            destinationLocation = locationString
        }
        
        onLocationSelected(locationString, isOriginSelection)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Airport Row View
struct AirportRowView: View {
    let airport: Airport
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Airport Icon
                Image(systemName: airport.type.iconName)
                    .foregroundColor(Color("Violet"))
                    .font(.system(size: 18))
                    .frame(width: 24, height: 24)
                
                // Airport Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if airport.type == .major {
                            Text(airport.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text("(\(airport.code))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        } else {
                            Text(airport.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                    }
                    
                    Text("\(airport.city), \(airport.country)")
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

// MARK: - Supporting Models
struct Airport: Identifiable {
    let id = UUID()
    let code: String
    let name: String
    let city: String
    let country: String
    let type: AirportType
}

enum AirportType {
    case major
    case city
    
    var iconName: String {
        switch self {
        case .major:
            return "airplane"
        case .city:
            return "building.2"
        }
    }
}

#Preview {
    LocationSelectionView(
        originLocation: .constant("New York, United States"),
        destinationLocation: .constant("")
    ) { _, _ in }
}
