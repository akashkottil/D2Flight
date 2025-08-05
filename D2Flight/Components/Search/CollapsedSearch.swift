import SwiftUI

struct CollapsedSearch: View {
    // Search parameters for display
    let originCode: String
    let destinationCode: String
    let travelDate: String
    let travelerInfo: String
    let animationNamespace: Namespace.ID
    
    // Action closures
    let onEdit: () -> Void
    let onSearch: () -> Void
    
    var body: some View {
        VStack {
            // Edit button
            Button(action: onEdit) {
                HStack {
                    Image("SearchIcon")
                        .frame(width: 25, height: 25)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(originCode)-\(destinationCode)")
                            Text("•")
                            Text(travelDate)
                        }
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(Color.black)
                        
                        Text(travelerInfo)
                            .font(.system(size: 14))
                            .fontWeight(.regular)
                            .foregroundColor(Color.gray)
                    }
                    
                    Spacer()
                    
                   
                    
                    // Search button with matched geometry effect
                    PrimaryButton(
                        title: "Search",
                        font: CustomFont.font(.medium),
                        fontWeight: .bold,
                        textColor: .white,
                        width: 120,
                        verticalPadding: 15,
                        cornerRadius: 12,
                        action: onSearch
                    )
                    .matchedGeometryEffect(id: "searchButton", in: animationNamespace)
                }
            }
            .buttonStyle(PlainButtonStyle())

        }
//        .padding()
        .padding(.vertical,6)
        .padding(.horizontal,6)
        .background(Color.white)
        
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct CollapsedSearch_Previews: PreviewProvider {
    // Create a Namespace for animation
    @Namespace static private var animationNamespace
    
    static var previews: some View {
        CollapsedSearch(
            originCode: "NYC",
            destinationCode: "LAX",
            travelDate: "July 30, 2025",
            travelerInfo: "1 Adult, 0 Children",
            animationNamespace: animationNamespace,
            onEdit: {
                // Define what happens on edit
                print("Edit tapped")
            },
            onSearch: {
                // Define what happens on search
                print("Search tapped")
            }
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
