import SwiftUI

struct CollapsedSearch<ButtonContent: View>: View {
    // Display
    let originCode: String
    let destinationCode: String
    let travelDate: String
    let travelerInfo: String

    // Matched-geometry namespace for the small button
    let buttonNamespace: Namespace.ID

    // Inject the small button (so identity matches the expanded one)
    @ViewBuilder var button: () -> ButtonContent

    // Actions
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 8) { // Reduced spacing for better integration
            // Left area: edit
            Button(action: onEdit) {
                HStack(spacing: 8) {
                    Image("SearchIcon")
                        .frame(width: 25, height: 25)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("\(originCode)-\(destinationCode)")
                            Text("a".localized)
                            Text(travelDate)
                        }
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)

                        Text(travelerInfo)
                            .font(.system(size: 14))
                            .fontWeight(.regular)
                            .foregroundColor(.gray)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Right-side small search button container with proper alignment
//            VStack {
//                Spacer(minLength: 0)
//                
//                button()
//                    .matchedGeometryEffect(id: "searchButton", in: buttonNamespace)
//                
//                Spacer(minLength: 0)
//            }
//            .frame(width: 120) // Fixed width to match small button
        }
        .padding(.vertical, 8) // Consistent padding
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .frame(height: 60) // Match the main button height exactly
    }
}
