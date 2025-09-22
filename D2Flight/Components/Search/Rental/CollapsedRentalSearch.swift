import SwiftUI

struct CollapsedRentalSearch<ButtonContent: View>: View {
    // MARK: - Inputs from RentalView
    let isSameDropOff: Bool
    /// e.g. "NYC" or "New York" – whatever you show in RentalView
    let pickUpText: String
    /// used only when `isSameDropOff == false`
    let dropOffText: String?
    /// already-localized display (“Tue 21 Sep, 09:00 • Thu 23 Sep, 10:00”
    /// or single value for same drop-off)
    let dateTimeText: String
    /// Optional: “1 Adult”, etc.
    let travelerInfo: String?

    // MARK: - Matched-geometry for small CTA/button
    let buttonNamespace: Namespace.ID
    @ViewBuilder var button: () -> ButtonContent

    // MARK: - Actions
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Left area = edit/tap target
            Button(action: onEdit) {
                HStack(spacing: 10) {
                    Image("SearchIcon")
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        // Top line: location(s)
                        if isSameDropOff || (dropOffText?.isEmpty ?? true) {
                            Text(safeLocation(pickUpText))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                        } else {
                            // Different drop-off -> show both
                            Text("\(safeLocation(pickUpText)) - \(safeLocation(dropOffText))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                        }

                        // Second line: date/time
                        Text(dateTimeText.isEmpty ? "tap.to.select".localized : dateTimeText)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(1)

                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

           
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .frame(height: 60) // keep consistent height; adjust if you prefer auto
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Helpers
    private func safeLocation(_ text: String?) -> String {
        let trimmed = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "enter.pick-up.location".localized : trimmed
    }

    private var accessibilitySummary: String {
        let locLine: String = {
            if isSameDropOff || (dropOffText?.isEmpty ?? true) {
                return safeLocation(pickUpText)
            } else {
                return "\(safeLocation(pickUpText)) to \(safeLocation(dropOffText))"
            }
        }()
        let pax = (travelerInfo?.isEmpty == false) ? ", \(travelerInfo!)" : ""
        return "\(locLine), \(dateTimeText)\(pax)"
    }
}


struct CollapsedRentalSearch_Previews: PreviewProvider {
    @Namespace static var ns
    
    static var previews: some View {
        Group {
            // Same drop-off (one location only)
            CollapsedRentalSearch(
                isSameDropOff: true,
                pickUpText: "NYC",
                dropOffText: nil,
                dateTimeText: "Tue 21 Sep, 09:00",
                travelerInfo: "1 Adult",
                buttonNamespace: ns,
                button: {
                    Button(action: {}) {
                        Text("Search")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                },
                onEdit: { print("Edit tapped") }
            )
            .padding()
            .previewDisplayName("Same drop-off")

            // Different drop-off (two locations)
            CollapsedRentalSearch(
                isSameDropOff: false,
                pickUpText: "NYC",
                dropOffText: "LAX",
                dateTimeText: "Tue 21 Sep, 09:00 • Thu 23 Sep, 10:00",
                travelerInfo: "2 Adults",
                buttonNamespace: ns,
                button: {
                    Button(action: {}) {
                        Text("Search")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                },
                onEdit: { print("Edit tapped") }
            )
            .padding()
            .previewDisplayName("Different drop-off")
        }
        .previewLayout(.sizeThatFits)
    }
}

