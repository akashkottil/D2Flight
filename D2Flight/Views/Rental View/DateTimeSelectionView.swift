import SwiftUI

// MARK: - DateTimeSelectionView

struct DateTimeSelectionView: View {
    @Environment(\.presentationMode) var presentationMode

    // External state
    @Binding var selectedDates: [Date]      // [0]: pickup date, [1]: dropoff date (optional)
    @Binding var selectedTimes: [Date]      // [0]: pickup time, [1]: dropoff time (optional)
    let isSameDropOff: Bool                 // rentals: same vs different drop-off
    let isFromHotel: Bool                   // hotels keep fixed 2-date behavior
    var onDatesSelected: ([Date], [Date]) -> Void

    // Local UI state
    @State private var showTimePicker = false
    @State private var activeTimeSelection: TimeSelectionType?
    @State private var hasInitialized = false

    enum TimeSelectionType { case pickup, dropoff }

    // MARK: - Initializers (kept shape)

    init(
        selectedDates: Binding<[Date]>,
        selectedTimes: Binding<[Date]>,
        isFromHotel: Bool,
        onDatesSelected: @escaping ([Date], [Date]) -> Void
    ) {
        self._selectedDates = selectedDates
        self._selectedTimes = selectedTimes
        self.isSameDropOff = false
        self.isFromHotel = isFromHotel
        self.onDatesSelected = onDatesSelected
    }

    init(
        selectedDates: Binding<[Date]>,
        selectedTimes: Binding<[Date]>,
        isSameDropOff: Bool,
        onDatesSelected: @escaping ([Date], [Date]) -> Void
    ) {
        self._selectedDates = selectedDates
        self._selectedTimes = selectedTimes
        self.isSameDropOff = isSameDropOff
        self.isFromHotel = false
        self.onDatesSelected = onDatesSelected
    }

    // MARK: - Formatters / options

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var allTimeOptions: [String] {
        (0..<24).map { String(format: "%02d:00", $0) }
    }

    // MARK: - Core rule helpers

    /// Minimum allowed drop-off time = pickup + 1 hour
    private func minDropoff(from pickup: Date) -> Date {
        Calendar.current.date(byAdding: .hour, value: 1, to: pickup) ?? pickup
    }

    /// Which date to show on the second card:
    /// - if a second date exists → use it
    /// - else mirror the first date (for rentals same-drop & single-date selection)
    private func dropoffLogicalDate() -> Date? {
        guard let first = selectedDates.first else { return nil }
        return selectedDates.count > 1 ? selectedDates[1] : first
    }

    /// Ensure second **time** (and date if needed) is valid whenever pickup changes or before editing.
    private func ensureDropoffDefaultsRespectingOneHourRule() {
        guard let pickupTime = selectedTimes.first else { return }

        var minDrop = minDropoff(from: pickupTime)

        // If +1h crosses to next day → ensure drop-off DATE is next day
        if let firstDate = selectedDates.first,
           !Calendar.current.isDate(pickupTime, inSameDayAs: minDrop) {
            let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: firstDate) ?? firstDate
            if selectedDates.count == 1 { selectedDates.append(nextDay) }
            else { selectedDates[1] = nextDay }
        }

        // Ensure we have a second TIME and that it's >= pickup + 1h
        if selectedTimes.count < 2 {
            selectedTimes.append(minDrop)
        } else if selectedTimes[1] < minDrop {
            selectedTimes[1] = minDrop
        }
    }

    // MARK: - Time options (drop-off filtering)

    private var availableTimeOptions: [String] {
        guard let active = activeTimeSelection else { return allTimeOptions }

        // Which date is the picker working on?
        let targetDate: Date? = {
            switch active {
            case .pickup:
                return selectedDates.first
            case .dropoff:
                if selectedDates.count > 1 { return selectedDates[1] }
                // same drop-off single-date scenario → use the first date (mirrored)
                return selectedDates.first
            }
        }()

        guard let date = targetDate else { return allTimeOptions }

        let cal = Calendar.current
        var filtered = allTimeOptions

        // Keep: hide past hours if date is today
        if cal.isDate(date, inSameDayAs: Date()) {
            let currentHour = cal.component(.hour, from: Date())
            filtered = filtered.filter { hStr in
                (Int(hStr.prefix(2)) ?? 0) > currentHour
            }
        }

        // New/Adjusted: for drop-off on the same day as pickup → enforce >= pickup + 1h
        if active == .dropoff, let pickupTime = selectedTimes.first {
            let minDrop = minDropoff(from: pickupTime)

            if let dropDate = dropoffLogicalDate(),
               cal.isDate(dropDate, inSameDayAs: pickupTime) {
                let minHour = cal.component(.hour, from: minDrop)
                filtered = filtered.filter { hStr in
                    (Int(hStr.prefix(2)) ?? 0) >= minHour
                }
            }
        }

        return filtered
    }

    // MARK: - Titles / strings

    private var headerTitle: String {
        isFromHotel ? "select.dates".localized : "select.dates".localized
    }
    private var firstCardTitle: String {
        isFromHotel ? "check-in".localized : "pick-up".localized
    }
    private var secondCardTitle: String {
        if isFromHotel { return "check-out".localized }
        return isSameDropOff ? "drop-off.same.location".localized : "drop-off".localized
    }
    private var timePickerTitle: String {
        guard let active = activeTimeSelection else { return "" }
        switch active {
        case .pickup:  return isFromHotel ? "select.check-in.time".localized  : "select.pick-up.time".localized
        case .dropoff: return isFromHotel ? "select.check-out.time".localized : "select.drop-off.time".localized
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image("BlackArrow")
                        .padding(.horizontal)
                }
                Text(headerTitle)
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.trailing, 44)
                Spacer()
            }
            .padding()

            Divider()

            // Localized weekday headers (kept)
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    Text(CalendarLocalization.getLocalizedWeekdayName(for: index))
                        .font(CustomFont.font(.regular, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.1))
                        )
                }
            }
            .padding(.top)
            .padding(.horizontal, 20)

            // Calendar + bottom overlay
            ZStack {
                // IMPORTANT: allow selecting 1 or 2 dates for rentals (including same drop-off).
                // Hotels remain range selection as before.
                LocalizedSimplifiedCalendar(
                    selectedDates: $selectedDates,
                    // Always allow range selection so user can optionally pick a 2nd date on same-drop too.
                    isRoundTrip: isFromHotel ? true : true
                )

                // Bottom overlay
                VStack {
                    Spacer()

                    VStack(spacing: 16) {
                        // === Date & Time Cards (Second Card always visible) ===
                        HStack(spacing: 12) {
                            // First Card (Pick-up / Check-in)
                            DateTimeCard(
//                                title: firstCardTitle,
                                dateText: formatFirstDate(),
                                timeText: formatFirstTime(),
                                isSelected: !selectedDates.isEmpty,
                                onTimeTap: {
                                    activeTimeSelection = .pickup
                                    withAnimation(.easeInOut(duration: 0.3)) { showTimePicker = true }
                                }
                            )

                            Image("RoundedArrow")
                                .frame(width: 16, height: 16)

                            // Second Card (Drop-off / Check-out) — stays visible
                            DateTimeCard(
//                                title: secondCardTitle,
                                // If user picked only one date, show the same date on the second card.
                                dateText: formatSecondDateDisplay(),
                                // If user hasn't chosen a second time, display (pickup + 1h)
                                timeText: formatSecondTimeDisplay(),
                                isSelected: selectedTimes.indices.contains(1),
                                onTimeTap: {
                                    // Make sure defaults are valid before opening time picker
                                    ensureDropoffDefaultsRespectingOneHourRule()
                                    activeTimeSelection = .dropoff
                                    withAnimation(.easeInOut(duration: 0.3)) { showTimePicker = true }
                                }
                            )
                        }
                        .padding()

                        // Time picker wheel (unchanged visuals)
                        if showTimePicker {
                            TimePickerSection(
                                title: timePickerTitle,
                                timeOptions: availableTimeOptions,
                                selectedTime: getCurrentSelectedTime(),
                                onTimeSelected: { timeString in
                                    selectTime(timeString)
                                    // close after a short delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showTimePicker = false
                                            activeTimeSelection = nil
                                        }
                                    }
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                            .animation(.easeInOut(duration: 0.3), value: showTimePicker)
                        }

                        // Apply button (kept)
                        PrimaryButton(
                            title: "apply".localized,
                            font: CustomFont.font(.large),
                            fontWeight: .bold,
                            textColor: .white,
                            verticalPadding: 18,
                            horizontalPadding: 24,
                            cornerRadius: 16
                        ) {
                            // Final pass: ensure the rule & mirror-date display are consistent
                            ensureDropoffDefaultsRespectingOneHourRule()
                            onDatesSelected(selectedDates, selectedTimes)
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.horizontal, 24)
                    }
                    .background(
                        Rectangle()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: -5)
                    )
                }
            }
        }
        .padding(.vertical, 10)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .background(Color.white)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if !hasInitialized {
                initializeSmartDefaults()          // keep your existing defaults
                hasInitialized = true
                // and ensure second card respects the 1h rule on open
                ensureDropoffDefaultsRespectingOneHourRule()
            }
        }
        // Keep second card valid if pickup changes
        .onChange(of: selectedTimes.first) { _, _ in ensureDropoffDefaultsRespectingOneHourRule() }
        .onChange(of: selectedDates.first) { _, _ in ensureDropoffDefaultsRespectingOneHourRule() }
    }

    // MARK: - Your existing smart defaults (unchanged visuals)

    private func initializeSmartDefaults() {
        let calendar = Calendar.current
        let now = Date()

        if isFromHotel {
            // Hotel: Today → Tomorrow, 15:00 → 11:00 (kept)
            let checkinDate = now
            let checkoutDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            selectedDates = [checkinDate, checkoutDate]
            let checkinTime = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now
            let checkoutTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now) ?? now
            selectedTimes = [checkinTime, checkoutTime]
        } else if isSameDropOff {
            // Same drop-off: same-day defaults (kept), but we'll enforce +1h for drop-off via ensure...
            selectedDates = [now]
            let currentHour = calendar.component(.hour, from: now)
            let currentMinute = calendar.component(.minute, from: now)
            let pickupTime: Date = (currentMinute > 0)
                ? (calendar.date(bySettingHour: currentHour + 1, minute: 0, second: 0, of: now) ?? now)
                : (calendar.date(bySettingHour: currentHour, minute: 0, second: 0, of: now) ?? now)
            selectedTimes = [pickupTime]
        } else {
            // Different drop-off: +2 days, 09:00 → 10:00 (kept)
            let pickupDate = now
            let dropoffDate = calendar.date(byAdding: .day, value: 2, to: now) ?? now
            selectedDates = [pickupDate, dropoffDate]
            let pickupTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
            let dropoffTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now
            selectedTimes = [pickupTime, dropoffTime]
        }
    }

    // MARK: - Current wheel selection

    private func getCurrentSelectedTime() -> String {
        guard let active = activeTimeSelection else { return "09:00" }
        switch active {
        case .pickup:  return formatFirstTime()
        case .dropoff: return formatSecondTimeDisplayRaw()
        }
    }

    // MARK: - Apply selected time

    private func selectTime(_ timeString: String) {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        guard let time = f.date(from: timeString) else { return }
        guard let active = activeTimeSelection else { return }
        switch active {
        case .pickup:  updateFirstTime(time)
        case .dropoff: updateSecondTime(time)
        }
        // Safeguard: re-ensure the rule after manual edits
        ensureDropoffDefaultsRespectingOneHourRule()
    }

    // MARK: - Date texts

    private func formatFirstDate() -> String {
        guard let firstDate = selectedDates.first else { return "select.date".localized }
        return LocalizedDateFormatter.formatShortDateWithComma(firstDate)
    }

    /// Shows the second date if picked; otherwise mirrors the first date (for rentals same-drop single-date).
    private func formatSecondDateDisplay() -> String {
        if selectedDates.count > 1, let second = selectedDates.last {
            return LocalizedDateFormatter.formatShortDateWithComma(second)
        } else if let first = selectedDates.first {
            // Same drop-off single-date: mirror first date
            return LocalizedDateFormatter.formatShortDateWithComma(first)
        }
        return "select.date".localized
    }

    // MARK: - Time texts

    private func formatFirstTime() -> String {
        guard selectedTimes.indices.contains(0) else {
            return isFromHotel ? "15:00" : "09:00"
        }
        return timeFormatter.string(from: selectedTimes[0])
    }

    /// If user hasn’t chosen a second time or chose an invalid one, display pickup+1h.
    private func formatSecondTimeDisplay() -> String {
        guard let pickup = selectedTimes.first else { return isFromHotel ? "11:00" : "10:00" }
        let minDrop = minDropoff(from: pickup)
        if selectedTimes.indices.contains(1), selectedTimes[1] >= minDrop {
            return timeFormatter.string(from: selectedTimes[1])
        }
        return timeFormatter.string(from: minDrop)
    }

    /// Raw current second time (for picker selection binding). If missing, use pickup+1h.
    private func formatSecondTimeDisplayRaw() -> String {
        guard let pickup = selectedTimes.first else { return "10:00" }
        let minDrop = minDropoff(from: pickup)
        let value = (selectedTimes.indices.contains(1) && selectedTimes[1] >= minDrop) ? selectedTimes[1] : minDrop
        return timeFormatter.string(from: value)
    }

    // MARK: - Mutators

    private func updateFirstTime(_ newTime: Date) {
        if selectedTimes.indices.contains(0) { selectedTimes[0] = newTime }
        else { selectedTimes.append(newTime) }
    }

    private func updateSecondTime(_ newTime: Date) {
        if selectedTimes.indices.contains(1) { selectedTimes[1] = newTime }
        else if selectedTimes.count == 1 { selectedTimes.append(newTime) }
        else {
            let defaultFirst = Calendar.current.date(bySettingHour: isFromHotel ? 15 : 9, minute: 0, second: 0, of: Date()) ?? Date()
            selectedTimes = [defaultFirst, newTime]
        }
    }
}

// MARK: - DateTimeCard (same visuals/structure)

struct DateTimeCard: View {
//    let title: String
    let dateText: String
    let timeText: String
    let isSelected: Bool
    let onTimeTap: () -> Void

    private var ampmText: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        if let t = f.date(from: timeText) {
            let hour = Calendar.current.component(.hour, from: t)
            return hour < 12 ? "am".localized : "pm".localized
        }
        return "pm".localized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
//            Text(title.uppercased())
//                .font(CustomFont.font(.small, weight: .bold))
//                .foregroundColor(Color.gray)

            VStack(alignment: .leading, spacing: 8) {
                // Date
                Text(dateText)
                    .font(CustomFont.font(.medium, weight: .semibold))
                    .foregroundColor(Color("Violet"))

                // Time (tap to edit)
                Button(action: onTimeTap) {
                    HStack(spacing: 6) {
                        Text(timeText)
                            .font(CustomFont.font(.medium, weight: .semibold))
                            .foregroundColor(Color("Violet"))
                        Text(ampmText)
                            .font(CustomFont.font(.regular, weight: .medium))
                            .foregroundColor(Color("Violet"))
                        Image(systemName: "chevron.right")
                            .font(CustomFont.font(.regular, weight: .medium))
                            .foregroundColor(Color("Violet"))
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color("Violet") : Color.gray.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(16)
    }
}

// MARK: - TimePickerSection (unchanged visuals)

struct TimePickerSection: View {
    let title: String
    let timeOptions: [String]
    let selectedTime: String
    let onTimeSelected: (String) -> Void

    @State private var tempSelectedTime: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(CustomFont.font(.large, weight: .semibold))
                .padding(.top, 12)
                .padding(.bottom, 8)

            Picker(selection: Binding(
                get: { selectedTime },
                set: { newValue in
                    tempSelectedTime = newValue
                    onTimeSelected(newValue)
                }
            ), label: Text("")) {
                ForEach(timeOptions, id: \.self) { time in
                    Text(formattedDisplay(time))
                        .tag(time)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 150)
            .clipped()
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func formattedDisplay(_ time: String) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        guard let d = f.date(from: time) else { return time }
        let out = DateFormatter(); out.dateFormat = "h:mm a"
        return out.string(from: d)
    }
}
