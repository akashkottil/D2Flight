

import SwiftUI

struct CollapsedHotelSearch<ButtonContent: View>: View {
    // Display (hotel-friendly)
    let cityCode: String            // e.g. "COK" or "NYC" — shown on the left
    let dateRange: String           // e.g. "Fri 12 Sep, 15:00  •  Sat 13 Sep, 11:00"
    let guestsSummary: String       // e.g. "3 guests, 2 rooms"

    // Matched-geometry namespace for the small button (kept for design parity)
    let buttonNamespace: Namespace.ID

    // Inject the small button (kept, even if you don't render it yet)
    @ViewBuilder var button: () -> ButtonContent

    // Actions
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 8) { // keep original spacing
            // Left area: tap to edit
            Button(action: onEdit) {
                HStack(spacing: 8) {
                    Image("SearchIcon")
                        .frame(width: 25, height: 25)

                    VStack(alignment: .leading, spacing: 2) {
                        // Top line: left (city code) + right (date-range)
                        HStack {
                            Text(cityCode)              // was "\(originCode)-\(destinationCode)"
                            Text(dateRange)             // was "travelDate"
                        }
                        .font(.system(size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)

                        // Bottom line: guests/rooms summary (same style)
                        Text(guestsSummary)            // was "travelerInfo"
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
