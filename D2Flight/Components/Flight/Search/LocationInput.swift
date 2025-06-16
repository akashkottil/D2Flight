import SwiftUI

struct LocationInput: View {
    @Binding var originLocation: String
    @Binding var destinationLocation: String
    @Binding var isSelectingOrigin: Bool
    @Binding var searchText: String
    
    @FocusState private var focusedField: Field?
    
    @State private var swapButtonRotationAngle: Double = 0
    
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
                        .font(CustomFont.font(.regular))
                    // Clear button, visible only if the text is not empty
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
                        .font(CustomFont.font(.regular))
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
            }
            .background(.gray.opacity(0.1))
            .cornerRadius(12)
            
            // 🔄 Swap Button with Rotation Animation
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
                    .rotationEffect(.degrees(swapButtonRotationAngle)) // 🌀 Animate rotation
            }
            .offset(x: 135)
            .shadow(color: .purple.opacity(0.3), radius: 5)
            
        }
        .padding()
        .onAppear {
            focusedField = .origin
        }
    }
}
