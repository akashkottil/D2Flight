//
//  RentalSearchCard.swift
//  D2Flight
//
//  Created by Akash Kottil on 20/09/25.
//


import SwiftUI

struct RentalSearchCard: View {
    // Trip type (same/different drop-off)
    @Binding var isSameDropOff: Bool

    // Location states
    @Binding var pickUpLocation: String
    @Binding var dropOffLocation: String
    @Binding var pickUpIATACode: String
    @Binding var dropOffIATACode: String

    // Date & Time states
    @Binding var selectedDates: [Date]
    @Binding var selectedTimes: [Date]

    // Navigation states
    @Binding var navigateToLocationSelection: Bool
    @Binding var navigateToDateTimeSelection: Bool

    // Animation state for swap
    @State private var swapButtonRotationAngle: Double = 0

    // Continuous collapse progress (0 = expanded, 1 = collapsed)
    var collapseProgress: CGFloat

    // Namespace (kept for CollapsedRentalSearch compatibility)
    let buttonNamespace: Namespace.ID

    // Actions
    let onSearchRentals: () -> Void
    let onExpandSearchCard: () -> Void

    // MARK: - Body
    var body: some View {
        // Clamp once
        let p = clamp(collapseProgress)

        // Staged fades (Location → DateTime)
        let dateFade = 1 - easeInOut(stage(p, 0.15, 0.60))
        let locFade  = 1 - easeInOut(stage(p, 0.30, 0.80)) // slightly earlier to settle sooner in "same" mode

        // Mode-aware total lift (how far the chip + button should travel up)
        // Smaller for Same drop-off because there's no second location row.
        let totalLiftSame: CGFloat = 120    // tune ± a few pts if needed
        let totalLiftDiff: CGFloat = 148   // matches visual you already liked

        let targetLift = isSameDropOff ? totalLiftSame : totalLiftDiff

        // Smooth single-curve lift and CLAMP it so it doesn't cross into the tab row
        let yLift = -min(easeInOut(p) * targetLift, targetLift)

        // Keep your nice shrinking of vertical gaps
        let stackSpacing = 6 - 4 * p


        return VStack(alignment: .leading, spacing: stackSpacing) {

            // Location Input
            locationSection
                .opacity(locFade)
                .scaleEffect(0.96 + 0.04 * locFade)
                .allowsHitTesting(locFade > 0.2)
                .animation(.easeInOut(duration: 0.25), value: collapseProgress)

            // DateTime (single combined row for rentals)
            dateTimeRow(
                label: dateTimeDisplayText(),
                icon: "CalenderIcon"
            )
            .id("rental_datetime")
            .opacity(dateFade)
            .scaleEffect(0.96 + 0.04 * dateFade)
            .animation(.easeInOut(duration: 0.25), value: collapseProgress)

            curtainRevealSection
                .offset(y: yLift)
                // A tiny top guard in collapsed state helps avoid hairline overlaps on dense devices
                .padding(.top, p > 0.7 ? (isSameDropOff ? 6 : 0) : 0)
                .animation(.easeInOut(duration: 0.25), value: collapseProgress)

        }
    }

    // MARK: - Curtain Reveal
    private var curtainRevealSection: some View {
        let smallWidth: CGFloat  = 120
        let bigCorner: CGFloat   = 16
        let smallCorner: CGFloat = 12
        let bigVPad: CGFloat     = 20
        let smallVPad: CGFloat   = 15
        let p = clamp(collapseProgress)

        return ZStack {
            if p > 0.7 {
                CollapsedRentalSearch(
                    isSameDropOff: isSameDropOff,
                    pickUpText: pickUpLocation.isEmpty ? "enter.pick-up.location".localized : pickUpLocation,
                    dropOffText: isSameDropOff ? nil : (dropOffLocation.isEmpty ? nil : dropOffLocation),
                    dateTimeText: dateTimeDisplayText(),
                    travelerInfo: nil, // set if you later add passengers to rental
                    buttonNamespace: buttonNamespace,
                    button: { EmptyView() },
                    onEdit: onExpandSearchCard
                )
            }

            GeometryReader { proxy in
                let fullWidth      = proxy.size.width
                let currentWidth   = fullWidth - (fullWidth - smallWidth) * p
                let currentVPad    = bigVPad - (bigVPad - smallVPad) * p
                let currentCorner  = bigCorner - (bigCorner - smallCorner) * p
                let topPad: CGFloat      = CGFloat(10) * p
                let trailingPad: CGFloat = CGFloat(10) * p
                let buttonText = p > 0.5 ? "Search" : "search.rentals".localized
                let adjustedVPad = currentVPad - CGFloat(4) * p

                PrimaryButton(
                    title: buttonText,
                    font: CustomFont.font(.medium),
                    fontWeight: .bold,
                    textColor: .white,
                    verticalPadding: adjustedVPad,
                    cornerRadius: currentCorner,
                    action: onSearchRentals
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

    // MARK: - Location section with swap (matches RentalView styling)
    private var locationSection: some View {
        ZStack {
            Button(action: { navigateToLocationSelection = true }) {
                VStack(spacing: 1) {
                    // Pick-up
                    HStack {
                        Image("DepartureIcon")
                            .frame(width: 20, height: 20)
                        Text(pickUpLocation.isEmpty ? "enter.pick-up.location".localized : pickUpLocation)
                            .foregroundColor(pickUpLocation.isEmpty ? .gray : .black)
                            .fontWeight(pickUpLocation.isEmpty ? .medium : .bold)
                            .font(CustomFont.font(.regular))
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity)

                    // Drop-off (only when different)
                    if !isSameDropOff {
                        Divider()
                            .background(Color.gray.opacity(0.5))
                            .padding(.leading)
                            .padding(.trailing, 70)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))

                        HStack {
                            Image("DestinationIcon")
                                .frame(width: 20, height: 20)
                            Text(dropOffLocation.isEmpty ? "enter.drop-off.location".localized : dropOffLocation)
                                .foregroundColor(dropOffLocation.isEmpty ? .gray : .black)
                                .fontWeight(dropOffLocation.isEmpty ? .medium : .bold)
                                .font(CustomFont.font(.regular))
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.vertical, 18)
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .bottom))
                        ))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color.white)
            .cornerRadius(12)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSameDropOff)

            // Swap visible only for different drop-off
            if !isSameDropOff {
                Button(action: {
                    let temp = pickUpLocation
                    pickUpLocation = dropOffLocation
                    dropOffLocation = temp

                    let tempIATA = pickUpIATACode
                    pickUpIATACode = dropOffIATACode
                    dropOffIATACode = tempIATA

                    withAnimation(.easeInOut(duration: 0.3)) {
                        swapButtonRotationAngle -= 180
                    }
                }) {
                    Image("SwapIcon")
                        .rotationEffect(.degrees(swapButtonRotationAngle))
                }
                .offset(x: 148)
                .shadow(color: .purple.opacity(0.3), radius: 5)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.8)),
                    removal: .opacity.combined(with: .scale(scale: 0.8))
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: !isSameDropOff)
            }
        }
    }

    // MARK: - DateTime Row
    private func dateTimeRow(label: String, icon: String) -> some View {
        Button(action: { navigateToDateTimeSelection = true }) {
            HStack {
                Image(icon)
                    .resizable()
                    .frame(width: 22, height: 22)
                Text(label)
                    .foregroundColor(.gray)
                    .fontWeight(.medium)
                    .font(.system(size: 13))
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - DateTime helpers (mirrors RentalView formatting)
    private func dateTimeDisplayText() -> String {
        if selectedDates.isEmpty || selectedTimes.isEmpty {
            return "tap.to.select".localized
        }
        let pickup = combineDateAndTime(date: selectedDates[0], time: selectedTimes[0])
        let dropoff = (selectedDates.count > 1 && selectedTimes.count > 1)
            ? combineDateAndTime(date: selectedDates[1], time: selectedTimes[1])
            : pickup

        let isSameDay = Calendar.current.isDate(pickup, inSameDayAs: dropoff)
        if isSameDropOff || isSameDay {
            return formatLocalizedDateTime(pickup)
        } else {
            return "\(formatLocalizedDateTime(pickup)) • \(formatLocalizedDateTime(dropoff))"
        }
    }

    private func formatLocalizedDateTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        let localizedWeekday = CalendarLocalization.getLocalizedWeekdayName(for: weekdayIndex)
        let dayNumber = calendar.component(.day, from: date)
        let localizedMonth = CalendarLocalization.getLocalizedMonthName(for: date, isShort: true)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return "\(localizedWeekday) \(dayNumber) \(localizedMonth), \(String(format: "%02d:%02d", hour, minute))"
    }

    private func combineDateAndTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let d = calendar.dateComponents([.year, .month, .day], from: date)
        let t = calendar.dateComponents([.hour, .minute], from: time)
        var c = DateComponents()
        c.year = d.year; c.month = d.month; c.day = d.day
        c.hour = t.hour; c.minute = t.minute
        return calendar.date(from: c) ?? date
    }

    // MARK: - Math helpers
    private func clamp(_ x: CGFloat, _ a: CGFloat = 0, _ b: CGFloat = 1) -> CGFloat { min(max(x, a), b) }
    private func stage(_ p: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        guard a != b else { return p >= b ? 1 : 0 }
        return clamp((p - a) / (b - a))
    }
    private func easeInOut(_ x: CGFloat) -> CGFloat {
        let t = clamp(x)
        return t * t * (3 - 2 * t)
    }
}
