import SwiftUI

struct LocationSelectionViews: View {
    @Binding var originLocation: String
    @Binding var destinationLocation: String

    var body: some View {
        ZStack {
            VStack(spacing: 1) {
                HStack {
                    Image("DepartureLightIcon")
                        .resizable()
                        .frame(width: 20, height: 20)
                    TextField("Enter Departure", text: $originLocation)
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
                    TextField("Enter Destination", text: $destinationLocation)
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
            }) {
                Image("SwapIcon")
            }
            .offset(x: 135)
            .shadow(color: .purple.opacity(0.3), radius: 5)
        }
        .padding()
    }
}


struct LocationInputs_Previews: PreviewProvider {
    @State static var origin = "Kochi"
    @State static var destination = "Kerala"

    static var previews: some View {
        LocationSelectionViews(
            originLocation: $origin,
            destinationLocation: $destination
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

