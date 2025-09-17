import SwiftUI

struct SearchCard: View {
    // Trip type
    @Binding var isOneWay: Bool

    // Location states
    @Binding var originLocation: String
    @Binding var destinationLocation: String
    @Binding var originIATACode: String
    @Binding var destinationIATACode: String

    // Date states
    @Binding var selectedDates: [Date]
    @State private var departureDate: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd MMM"
        return formatter.string(from: Date())
    }()
    @State private var returnDate: String = ""

    // Passenger states
    @Binding var travelersCount: String
    @Binding var showPassengerSheet: Bool
    @Binding var adults: Int
    @Binding var children: Int
    @Binding var infants: Int
    @Binding var selectedClass: TravelClass

    // Navigation states
    @Binding var navigateToLocationSelection: Bool
    @Binding var navigateToDateSelection: Bool

    // Animation state
    @State private var swapButtonRotationAngle: Double = 0

    // Continuous collapse progress (0 = expanded, 1 = collapsed)
    var collapseProgress: CGFloat

    // Namespace (kept for CollapsedSearch compatibility)
    let buttonNamespace: Namespace.ID

    // Action
    let onSearchFlights: () -> Void

    // Date type enum
    enum DateType {
        case departure
        case `return`
    }

    // MARK: - Init
    init(
        isOneWay: Binding<Bool>,
        originLocation: Binding<String>,
        destinationLocation: Binding<String>,
        originIATACode: Binding<String>,
        destinationIATACode: Binding<String>,
        selectedDates: Binding<[Date]>,
        travelersCount: Binding<String>,
        showPassengerSheet: Binding<Bool>,
        adults: Binding<Int>,
        children: Binding<Int>,
        infants: Binding<Int>,
        selectedClass: Binding<TravelClass>,
        navigateToLocationSelection: Binding<Bool>,
        navigateToDateSelection: Binding<Bool>,
        collapseProgress: CGFloat,
        buttonNamespace: Namespace.ID,
        onSearchFlights: @escaping () -> Void
    ) {
        self._isOneWay = isOneWay
        self._originLocation = originLocation
        self._destinationLocation = destinationLocation
        self._originIATACode = originIATACode
        self._destinationIATACode = destinationIATACode
        self._selectedDates = selectedDates
        self._travelersCount = travelersCount
        self._showPassengerSheet = showPassengerSheet
        self._adults = adults
        self._children = children
        self._infants = infants
        self._selectedClass = selectedClass
        self._navigateToLocationSelection = navigateToLocationSelection
        self._navigateToDateSelection = navigateToDateSelection
        self.collapseProgress = collapseProgress
        self.buttonNamespace = buttonNamespace
        self.onSearchFlights = onSearchFlights
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Location Input
            locationSection

            // Date Section
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    dateView(
                        label: formatSelectedDate(for: .departure),
                        icon: "CalenderIcon"
                    )
                    .id("departure_date")

                    Group {
                        if !isOneWay {
                            dateView(
                                label: formatSelectedDate(for: .return),
                                icon: "CalenderIcon"
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8)
                                        .combined(with: .opacity)
                                        .combined(with: .move(edge: .trailing)),
                                    removal: .scale(scale: 0.8)
                                        .combined(with: .opacity)
                                        .combined(with: .move(edge: .trailing))
                                )
                            )
                        }
                    }
                    .frame(maxWidth: !isOneWay ? .infinity : 0)
                    .opacity(!isOneWay ? 1 : 0)
                    .scaleEffect(!isOneWay ? 1 : 0.8)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2),
                        value: isOneWay
                    )
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isOneWay)

            // Passenger Section
            Button(action: { showPassengerSheet = true }) {
                HStack {
                    Image("PassengerIcon")
                        .foregroundColor(.gray)
                        .frame(width: 22)
                    Text(travelersCount)
                        .foregroundColor(.gray)
                        .fontWeight(.medium)
                        .font(CustomFont.font(.regular))
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }

            // MARK: Curtain Reveal Button (continuous, scroll-driven)
            curtainRevealSection
        }
        .onAppear { initializeReturnDate() }
        .onChange(of: selectedDates) { _ in updateDateLabels() }
    }

    // MARK: - Curtain Reveal Section
    private var curtainRevealSection: some View {
        // Constants to blend between expanded and collapsed looks
        let smallWidth: CGFloat  = 120
        let bigCorner: CGFloat   = 16
        let smallCorner: CGFloat = 12
        let bigVPad: CGFloat     = 20
        let smallVPad: CGFloat   = 15
        let p = max(0, min(1, collapseProgress)) // clamp 0…1

        return ZStack {
            // BACK LAYER: the compact search summary (revealed as the button shrinks)
            CollapsedSearch(
                originCode: originIATACode.isEmpty ? "NYC" : originIATACode,
                destinationCode: destinationIATACode.isEmpty ? "LHR" : destinationIATACode,
                travelDate: formatTravelDate(),
                travelerInfo: travelersCount,
                buttonNamespace: buttonNamespace,
                button: { EmptyView() }, // no small button here; we're using a single front button
                onEdit: { navigateToLocationSelection = true }
            )

            // FRONT LAYER: a single button that resizes based on progress
            GeometryReader { proxy in
                let fullWidth      = proxy.size.width
                let currentWidth   = fullWidth - (fullWidth - smallWidth) * p
                let currentVPad    = bigVPad - (bigVPad - smallVPad) * p
                let currentCorner  = bigCorner - (bigCorner - smallCorner) * p

                // Gradual padding only as we collapse (0 → 10)
                let topPad: CGFloat      = CGFloat(10) * p
                let trailingPad: CGFloat = CGFloat(10) * p

                // Dynamic button text based on collapse progress
                let buttonText = p > 0.5 ? "Search" : "search.flights".localized

                // Vertical padding starts at currentVPad, ends at currentVPad - 4
                let adjustedVPad = currentVPad - CGFloat(4) * p

                PrimaryButton(
                    title: buttonText,
                    font: CustomFont.font(.medium),
                    fontWeight: .bold,
                    textColor: .white,
                    verticalPadding: adjustedVPad,
                    cornerRadius: currentCorner,
                    action: onSearchFlights
                )
                .frame(width: currentWidth)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .clipShape(RoundedRectangle(cornerRadius: currentCorner, style: .continuous))
                .padding(.top, topPad)          // apply gradually on collapse
                .padding(.trailing, trailingPad) // apply gradually on collapse
                .animation(.easeInOut(duration: 0.3), value: collapseProgress)
                .animation(.easeInOut(duration: 0.3), value: buttonText) // keep your text change animation
            }
            .frame(height: 60) // keep layout stable
        }
    }


    // MARK: Location section with swap
    private var locationSection: some View {
        ZStack {
            Button(action: { navigateToLocationSelection = true }) {
                VStack(spacing: 1) {
                    HStack {
                        Image("DepartureIcon")
                            .frame(width: 20, height: 20)
                        Text(originLocation.isEmpty ? "enter.departure".localized : originLocation)
                            .foregroundColor(originLocation.isEmpty ? .gray : .black)
                            .fontWeight(originLocation.isEmpty ? .medium : .bold)
                            .font(CustomFont.font(.regular))
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity)

                    Divider()
                        .background(Color.gray.opacity(0.5))
                        .padding(.leading)
                        .padding(.trailing, 70)

                    HStack {
                        Image("DestinationIcon")
                            .frame(width: 20, height: 20)
                        Text(destinationLocation.isEmpty ? "enter.destination".localized : destinationLocation)
                            .foregroundColor(destinationLocation.isEmpty ? .gray : .black)
                            .fontWeight(destinationLocation.isEmpty ? .medium : .bold)
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

            Button(action: {
                let temp = originLocation
                originLocation = destinationLocation
                destinationLocation = temp

                // Also swap IATA codes
                let tempIATA = originIATACode
                originIATACode = destinationIATACode
                destinationIATACode = tempIATA

                withAnimation(.easeInOut(duration: 0.3)) {
                    swapButtonRotationAngle -= 180
                }
            }) {
                Image("SwapIcon")
                    .rotationEffect(.degrees(swapButtonRotationAngle))
            }
            .offset(x: 148)
            .shadow(color: .purple.opacity(0.3), radius: 5)
        }
    }

    // MARK: Date View with Date Selection Integration
    private func dateView(label: String, icon: String) -> some View {
        Button(action: { navigateToDateSelection = true }) {
            HStack {
                Image(icon)
                    .frame(width: 20, height: 20)
                Text(label)
                    .foregroundColor(.gray)
                    .fontWeight(.medium)
                    .font(CustomFont.font(.regular))
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Format Selected Date
    private func formatSelectedDate(for type: DateType) -> String {
        switch type {
        case .departure:
            if let firstDate = selectedDates.first {
                return LocalizedDateFormatter.formatShortDate(firstDate)
            } else {
                return LocalizedDateFormatter.formatShortDate(Date())
            }
        case .return:
            if selectedDates.count > 1, let secondDate = selectedDates.last {
                return LocalizedDateFormatter.formatShortDate(secondDate)
            } else {
                return calculateDefaultReturnDate()
            }
        }
    }

    // MARK: Helper Methods
    private func initializeReturnDate() {
        if returnDate.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "E dd MMM"
            let twoDaysLater = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
            returnDate = formatter.string(from: twoDaysLater)
        }
    }

    private func calculateDefaultReturnDate() -> String {
        let baseDepartureDate: Date = selectedDates.first ?? Date()
        let ret = Calendar.current.date(byAdding: .day, value: 2, to: baseDepartureDate) ?? baseDepartureDate
        return LocalizedDateFormatter.formatShortDate(ret)
    }

    private func updateDateLabels() {
        if let firstDate = selectedDates.first {
            departureDate = LocalizedDateFormatter.formatShortDate(firstDate)
        }
        if selectedDates.count > 1, let secondDate = selectedDates.last {
            returnDate = LocalizedDateFormatter.formatShortDate(secondDate)
        } else {
            returnDate = calculateDefaultReturnDate()
        }
    }

    private func formatTravelDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"

        guard let firstDate = selectedDates.first else {
            return formatter.string(from: Date())
        }
        if !isOneWay && selectedDates.count > 1 {
            return "\(formatter.string(from: firstDate)) - \(formatter.string(from: selectedDates[1]))"
        } else {
            return formatter.string(from: firstDate)
        }
    }
}
