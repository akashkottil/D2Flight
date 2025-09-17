import SwiftUI

struct CollapsedSearch<ButtonContent: View>: View  {
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
        HStack(spacing: 12) {
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

            // Right-side small search button (separate, not nested)
            button()
                .matchedGeometryEffect(id: "searchButton", in: buttonNamespace)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
