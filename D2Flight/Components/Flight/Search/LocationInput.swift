import SwiftUI

struct LocationInput: View {
    @Binding var originLocation: String
    @Binding var destinationLocation: String
    @Binding var isSelectingOrigin: Bool
    @Binding var searchText: String
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case origin, destination
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 1) {
                HStack {
                    Image("DepartureLightIcon")
                        .resizable()
                        .frame(width: 20, height: 20)
                    TextField("Enter Departure", text: isSelectingOrigin ? $searchText : $originLocation)
                        .focused($focusedField, equals: .origin)
                        .onChange(of: focusedField) { newValue in
                            if newValue == .origin {
                                isSelectingOrigin = true
                                searchText = originLocation
                            }
                        }
                        .foregroundColor(originLocation.isEmpty ? .gray : .black)
                        .fontWeight(originLocation.isEmpty ? .medium : .semibold)
                        .font(.system(size: 14))
                    Spacer()
                }
                .padding(.vertical, 18)
                .padding(.horizontal)
                
                Divider()
                    .background(Color.gray.opacity(0.5))
                    .padding(.leading)
                    .padding(.trailing, 70)
                
                HStack {
                    Image("DestinationLightIcon")
                        .resizable()
                        .frame(width: 20, height: 20)
                    TextField("Enter Destination", text: !isSelectingOrigin ? $searchText : $destinationLocation)
                        .focused($focusedField, equals: .destination)
                        .onChange(of: focusedField) { newValue in
                            if newValue == .destination {
                                isSelectingOrigin = false
                                searchText = destinationLocation
                            }
                        }
                        .foregroundColor(destinationLocation.isEmpty ? .gray : .black)
                        .fontWeight(destinationLocation.isEmpty ? .medium : .semibold)
                        .font(.system(size: 14))
                    Spacer()
                }
                .padding(.vertical, 18)
                .padding(.horizontal)
            }
            .background(.gray.opacity(0.1))
            .cornerRadius(12)
            
            Button(action: {
                let temp = originLocation
                originLocation = destinationLocation
                destinationLocation = temp
                
                // Update searchText to match the currently selected field after swap
                if isSelectingOrigin {
                    searchText = originLocation
                } else {
                    searchText = destinationLocation
                }
            }) {
                Image("SwapIcon")
            }


            .offset(x: 135)
            .shadow(color: .purple.opacity(0.3), radius: 5)
        }
        .padding()
        .onAppear {
            // Set initial focus to origin when view appears
            focusedField = .origin
        }
    }
}
