

import SwiftUI

struct CollapsedHotelSearch<ButtonContent: View>: View {
    // Display (hotel-friendly)
    let cityCode: String
    let dateRange: String
    let guestsSummary: String
    
    let buttonNamespace: Namespace.ID

    @ViewBuilder var button: () -> ButtonContent

    // Actions
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onEdit) {
                HStack(spacing: 8) {
                    Image("SearchIcon")
                        .frame(width: 25, height: 25)

                    VStack(alignment: .leading, spacing: 2) {
                        
                        HStack {
                            Text(cityCode)
                            Text(dateRange)
                        }
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)

                        
                        Text(guestsSummary)           
                            .font(.system(size: 14))
                            .fontWeight(.regular)
                            .foregroundColor(.gray)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Right-side small search button (kept commented to preserve design intent)
//            VStack {
//                Spacer(minLength: 0)
//                button()
//                    .matchedGeometryEffect(id: "searchButton", in: buttonNamespace)
//                Spacer(minLength: 0)
//            }
//            .frame(width: 120)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .frame(height: 60)
    }
}

struct CollapsedHotelSearch_Previews: PreviewProvider {
    @Namespace static var ns
    static var previews: some View {
        CollapsedHotelSearch(
            cityCode: "SYD",
            dateRange: "Fri 20 Sep, 15:00 • Sat 21 Sep, 11:00",
            guestsSummary: "2 guests, 1 room",
            buttonNamespace: ns,
            button: { EmptyView() },
            onEdit: { }
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}
