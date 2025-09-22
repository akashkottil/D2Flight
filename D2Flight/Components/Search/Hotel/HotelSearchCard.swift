import SwiftUI

struct HotelSearchCard: View {
    // Location (single input)
    @Binding var hotelLocation: String
    @Binding var hotelIATACode: String

    // Dates + Times (two picks)
    @Binding var selectedDates: [Date]      // [checkin, checkout]
    @Binding var selectedTimes: [Date]      // [checkinTime, checkoutTime]

    // Guests / Rooms
    @Binding var guestsCount: String
    @Binding var showPassengerSheet: Bool
    @Binding var adults: Int
    @Binding var children: Int
    @Binding var rooms: Int

    // Navigation
    @Binding var navigateToLocationSelection: Bool
    @Binding var navigateToDateTimeSelection: Bool

    // Animation
    var collapseProgress: CGFloat
    let buttonNamespace: Namespace.ID

    // Actions
    let onSearchHotels: () -> Void
    let onExpandSearchCard: () -> Void

    var body: some View {
        let p = clamp(collapseProgress)
        let dateFade = 1 - easeInOut(stage(p, 0.10, 0.60))
        let locFade  = 1 - easeInOut(stage(p, 0.30, 0.85))
        let paxFade  = 1 - easeInOut(stage(p, 0.00, 0.35))

        let liftFromDates:    CGFloat = 64
        let liftFromLocation: CGFloat = 84
        let liftFromPax:      CGFloat = 56

        let yLift =
            (-easeInOut(stage(p, 0.15, 0.60)) * liftFromDates) +
            (-easeInOut(stage(p, 0.35, 0.85)) * liftFromLocation) +
            (-easeInOut(stage(p, 0.00, 0.35)) * liftFromPax)
        
        // Add a gentle downshift only near-collapsed → collapsed
        let collapsedTopInset: CGFloat = 24 * easeInOut(stage(p, 0.70, 1.00))

        let stackSpacing = 6 - 4 * p

        return VStack(alignment: .leading, spacing: stackSpacing) {

            // Location (single)
            locationSection
                .opacity(locFade)
                .scaleEffect(0.96 + 0.04 * locFade)
                .allowsHitTesting(locFade > 0.2)
                .animation(.easeInOut(duration: 0.25), value: collapseProgress)

            // Check-in / Check-out
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    dateTimeView(
                        label: formatSelectedDateTime(for: .checkin),
                        icon: "CalenderIcon",
                        title: "check-in".localized
                    )
                    .id("checkin_date")

                    dateTimeView(
                        label: formatSelectedDateTime(for: .checkout),
                        icon: "CalenderIcon",
                        title: "check-out".localized
                    )
                    .id("checkout_date")
                }
            }
            .opacity(dateFade)
            .scaleEffect(0.96 + 0.04 * dateFade)
            .animation(.easeInOut(duration: 0.25), value: collapseProgress)

            // Guests & rooms
            Button(action: { showPassengerSheet = true }) {
                HStack {
                    Image("PassengerIcon")
                        .foregroundColor(.gray)
                        .frame(width: 22)
                    Text(guestsCount)
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                        .font(CustomFont.font(.regular))
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            .opacity(paxFade)
            .scaleEffect(0.96 + 0.04 * paxFade)
            .allowsHitTesting(paxFade > 0.2)
            .animation(.easeInOut(duration: 0.25), value: collapseProgress)

            // Curtain / Search button (+ CollapsedHotelSearch just like flights)
            curtainRevealSection
                .offset(y: yLift + collapsedTopInset)
                .animation(.easeInOut(duration: 0.25), value: collapseProgress)
        }
    }

    // MARK: - Location
    private var locationSection: some View {
        Button(action: { navigateToLocationSelection = true }) {
            VStack(spacing: 1) {
                HStack {
                    Image("DepartureIcon")
                        .frame(width: 20, height: 20)
                    Text(hotelLocation.isEmpty ? "enter.hotel.location".localized : hotelLocation)
                        .foregroundColor(hotelLocation.isEmpty ? .gray : .black)
                        .fontWeight(hotelLocation.isEmpty ? .medium : .bold)
                        .font(CustomFont.font(.regular))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 18)
                .padding(.horizontal)
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - Date/time input
    private func dateTimeView(label: String, icon: String, title: String) -> some View {
        Button(action: { navigateToDateTimeSelection = true }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(icon)
                        .frame(width: 16, height: 16)
                    Text(label)
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                        .font(CustomFont.font(.regular))
                    Spacer()
                }
            }
            .padding(.leading)
            .padding(.vertical)
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Curtain / Search button (now shows CollapsedHotelSearch when collapsed)
    private var curtainRevealSection: some View {
        let smallWidth: CGFloat  = 120
        let bigCorner: CGFloat   = 16
        let smallCorner: CGFloat = 12
        let bigVPad: CGFloat     = 20
        let smallVPad: CGFloat   = 15
        let p = clamp(collapseProgress)

        return ZStack {
            if p > 0.7 {
                let collapsedTopInset = 20 * easeInOut(stage(p, 0.70, 1.00))
                CollapsedHotelSearch(
                    cityCode: hotelIATACode.isEmpty ? "NYC" : hotelIATACode,
                    dateRange: formatCollapsedDateRange(),
                    guestsSummary: guestsCount,
                    buttonNamespace: buttonNamespace,
                    button: { EmptyView() },
                    onEdit: onExpandSearchCard
                )
                .padding(.top, collapsedTopInset)   // 👈 extra top padding only in collapsed state
            }


            GeometryReader { proxy in
                let fullWidth      = proxy.size.width
                let currentWidth   = fullWidth - (fullWidth - smallWidth) * p
                let currentVPad    = bigVPad - (bigVPad - smallVPad) * p
                let currentCorner  = bigCorner - (bigCorner - smallCorner) * p
                let topPad: CGFloat      = CGFloat(20) * p
                let trailingPad: CGFloat = CGFloat(10) * p
                let buttonText = p > 0.5 ? "Search" : "search.hotels".localized
                let adjustedVPad = currentVPad - CGFloat(4) * p

                PrimaryButton(
                    title: buttonText,
                    font: CustomFont.font(.medium),
                    fontWeight: .bold,
                    textColor: .white,
                    verticalPadding: adjustedVPad,
                    cornerRadius: currentCorner,
                    action: onSearchHotels
                )
                .frame(width: currentWidth)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .clipShape(RoundedRectangle(cornerRadius: currentCorner, style: .continuous))
                .padding(.top, topPad)
                .padding(.trailing, trailingPad)
                .transition(.move(edge: .trailing))
                .animation(.easeInOut(duration: 0.02), value: collapseProgress)
            }
            .frame(height: 60)
        }
    }

    // MARK: - Localized date/time formatting (mirrors HotelView)
    enum HotelDateType { case checkin, checkout }

    private func formatSelectedDateTime(for type: HotelDateType) -> String {
        switch type {
        case .checkin:
            if selectedDates.count > 0 && selectedTimes.count > 0 {
                let combined = combineDateAndTime(date: selectedDates[0], time: selectedTimes[0])
                return formatLocalizedDateTime(combined)
            }
            return calculateDefaultCheckinDateTime()

        case .checkout:
            if selectedDates.count > 1 && selectedTimes.count > 1 {
                let combined = combineDateAndTime(date: selectedDates[1], time: selectedTimes[1])
                return formatLocalizedDateTime(combined)
            }
            return calculateDefaultCheckoutDateTime()
        }
    }

    // 👉 Single-line range used by CollapsedHotelSearch (e.g., "Fri 20 Sep, 15:00 • Sat 21 Sep, 11:00")
    private func formatCollapsedDateRange() -> String {
        let inLabel  = formatSelectedDateTime(for: .checkin)
        let outLabel = formatSelectedDateTime(for: .checkout)
        return "\(inLabel) • \(outLabel)"
    }

    private func formatLocalizedDateTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        let localizedWeekday = CalendarLocalization.getLocalizedWeekdayName(for: weekdayIndex)
        let day = calendar.component(.day, from: date)
        let localizedMonth = CalendarLocalization.getLocalizedMonthName(for: date, isShort: true)
        let hour = calendar.component(.hour, from: date)
        let min = calendar.component(.minute, from: date)
        return "\(localizedWeekday) \(day) \(localizedMonth), \(String(format: "%02d:%02d", hour, min))"
    }

    private func calculateDefaultCheckinDateTime() -> String {
        let today = Date()
        let defaultTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: today) ?? today
        return formatLocalizedDateTime(defaultTime)
    }

    private func calculateDefaultCheckoutDateTime() -> String {
        let base = selectedDates.first ?? Date()
        let checkout = Calendar.current.date(byAdding: .day, value: 1, to: base) ?? base
        let defaultTime = Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: checkout) ?? checkout
        return formatLocalizedDateTime(defaultTime)
    }

    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let cal = Calendar.current
        let d = cal.dateComponents([.year, .month, .day], from: date)
        let t = cal.dateComponents([.hour, .minute], from: time)
        var c = DateComponents()
        c.year = d.year; c.month = d.month; c.day = d.day
        c.hour = t.hour; c.minute = t.minute
        return cal.date(from: c) ?? date
    }

    // MARK: - Math helpers
    private func clamp(_ x: CGFloat, _ a: CGFloat = 0, _ b: CGFloat = 1) -> CGFloat { min(max(x, a), b) }
    private func stage(_ p: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        guard a != b else { return p >= b ? 1 : 0 }
        return clamp((p - a) / (b - a))
    }
    private func easeInOut(_ x: CGFloat) -> CGFloat {
        let t = clamp(x); return t * t * (3 - 2 * t)
    }
}
