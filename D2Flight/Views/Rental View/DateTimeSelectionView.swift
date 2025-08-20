import SwiftUI

struct DateTimeSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDates: [Date]
    @Binding var selectedTimes: [Date]
    let isSameDropOff: Bool
    let isFromHotel: Bool // NEW: Add hotel mode support
    var onDatesSelected: ([Date], [Date]) -> Void
    
    @State private var showTimePicker = false
    @State private var activeTimeSelection: TimeSelectionType?
    @State private var hasInitialized = false
    
    enum TimeSelectionType {
        case pickup, dropoff
    }
    
    // NEW: Add hotel-specific initializer
    init(
        selectedDates: Binding<[Date]>,
        selectedTimes: Binding<[Date]>,
        isFromHotel: Bool,
        onDatesSelected: @escaping ([Date], [Date]) -> Void
    ) {
        self._selectedDates = selectedDates
        self._selectedTimes = selectedTimes
        self.isSameDropOff = false // Not applicable for hotel
        self.isFromHotel = isFromHotel
        self.onDatesSelected = onDatesSelected
    }
    
    // Keep existing rental initializer
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
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd, MMM"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    // Generate all 24 hours
    private var allTimeOptions: [String] {
        var times: [String] = []
        for hour in 0..<24 {
            times.append(String(format: "%02d:00", hour))
        }
        return times
    }
    
    // UPDATED: Filter times based on current time and validation
    private var availableTimeOptions: [String] {
        guard let activeSelection = activeTimeSelection else { return allTimeOptions }
        
        let selectedDate: Date?
        switch activeSelection {
        case .pickup:
            selectedDate = selectedDates.first
        case .dropoff:
            if selectedDates.count > 1 {
                selectedDate = selectedDates.last
            } else if (isSameDropOff || isFromHotel), let firstDate = selectedDates.first {
                selectedDate = firstDate // For same drop-off or hotel, use same date
            } else {
                selectedDate = nil
            }
        }
        
        guard let date = selectedDate else { return allTimeOptions }
        
        let calendar = Calendar.current
        var filteredTimes = allTimeOptions
        
        // Filter based on current time if date is today
        if calendar.isDate(date, inSameDayAs: Date()) {
            let currentHour = calendar.component(.hour, from: Date())
            filteredTimes = allTimeOptions.filter { timeString in
                let hour = Int(timeString.prefix(2)) ?? 0
                return hour > currentHour
            }
        }
        
        // UPDATED: Additional validation for checkout/dropoff time
        if activeSelection == .dropoff {
            // Check if both dates are the same
            let pickupDate = selectedDates.first ?? Date()
            let dropoffDate = selectedDates.count > 1 ? selectedDates[1] : pickupDate
            
            if calendar.isDate(pickupDate, inSameDayAs: dropoffDate) {
                // Same day: dropoff/checkout time must be after pickup/checkin time
                if let pickupTime = selectedTimes.first {
                    let pickupHour = calendar.component(.hour, from: pickupTime)
                    filteredTimes = filteredTimes.filter { timeString in
                        let hour = Int(timeString.prefix(2)) ?? 0
                        return hour > pickupHour
                    }
                }
            }
        }
        
        return filteredTimes
    }
    
    // UPDATED: Dynamic titles based on context
    private var headerTitle: String {
        if isFromHotel {
            return "select.dates".localized
        } else {
            return "select.dates".localized
        }
    }
    
    private var firstCardTitle: String {
        if isFromHotel {
            return "Check-in"
        } else {
            return "Pick-up"
        }
    }
    
    private var secondCardTitle: String {
        if isFromHotel {
            return "Check-out"
        } else if isSameDropOff {
            return "Drop-off (Same location)"
        } else {
            return "Drop-off"
        }
    }
    
    private var timePickerTitle: String {
        guard let activeSelection = activeTimeSelection else { return "" }
        
        switch activeSelection {
        case .pickup:
            return isFromHotel ? "Select Check-in Time" : "Select Pick-up Time"
        case .dropoff:
            return isFromHotel ? "Select Check-out Time" : "Select Drop-off Time"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
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
            
            // Weekday Headers
            HStack(spacing: 8) {
                ForEach(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"], id: \.self) { day in
                    Text(day)
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
            
            // Calendar and Content
            ZStack {
                SimplifiedCalendar(
                    selectedDates: $selectedDates,
                    isRoundTrip: !isSameDropOff || isFromHotel // Hotel always shows two dates
                )
                
                // Bottom section overlay
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Date and Time selection cards
                        HStack(spacing: 12) {
                            // First Card (Check-in/Pick-up)
                            DateTimeCard(
                                title: firstCardTitle,
                                dateText: formatFirstDate(),
                                timeText: formatFirstTime(),
                                isSelected: !selectedDates.isEmpty,
                                onTimeTap: {
                                    activeTimeSelection = .pickup
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showTimePicker = true
                                    }
                                }
                            )
                            
                            Image("RoundedArrow")
                                .frame(width: 16, height: 16)
                            
                            // Second Card (Check-out/Drop-off)
                            DateTimeCard(
                                title: secondCardTitle,
                                dateText: formatSecondDate(),
                                timeText: formatSecondTime(),
                                isSelected: selectedDates.count > 1 || isSameDropOff || isFromHotel,
                                onTimeTap: {
                                    activeTimeSelection = .dropoff
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showTimePicker = true
                                    }
                                }
                            )
                        }
                        .padding()
                        
                        // Time Picker Section
                        if showTimePicker {
                            TimePickerSection(
                                title: timePickerTitle,
                                timeOptions: availableTimeOptions,
                                selectedTime: getCurrentSelectedTime(),
                                onTimeSelected: { timeString in
                                    selectTime(timeString)
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
                        
                        // Apply button
                        PrimaryButton(
                            title: "apply".localized,
                            font: CustomFont.font(.large),
                            fontWeight: .bold,
                            textColor: .white,
                            verticalPadding: 18,
                            horizontalPadding: 24,
                            cornerRadius: 16
                        ) {
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
        .padding(.vertical,10)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .background(Color.white)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if !hasInitialized {
                initializeSmartDefaults()
                hasInitialized = true
            }
        }
    }
    
    // UPDATED: Smart default initialization for both rental and hotel
    private func initializeSmartDefaults() {
        let calendar = Calendar.current
        let now = Date()
        
        if isFromHotel {
            // Hotel: Today for check-in, tomorrow for check-out
            print("🏨 Initializing for HOTEL")
            
            let checkinDate = now
            let checkoutDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
            
            selectedDates = [checkinDate, checkoutDate]
            
            // Default times: 3:00 PM check-in, 11:00 AM check-out
            let checkinTime = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now
            let checkoutTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now) ?? now
            
            selectedTimes = [checkinTime, checkoutTime]
            
            print("   📅 Hotel dates: \(selectedDates)")
            print("   ⏰ Hotel times: \(selectedTimes)")
            
        } else if isSameDropOff {
            // Same drop-off: Current date, current time + 2 hours for drop-off
            print("🚗 Initializing for SAME drop-off")
            
            selectedDates = [now, now]
            
            let currentHour = calendar.component(.hour, from: now)
            let currentMinute = calendar.component(.minute, from: now)
            
            let pickupTime: Date
            if currentMinute > 0 {
                pickupTime = calendar.date(bySettingHour: currentHour + 1, minute: 0, second: 0, of: now) ?? now
            } else {
                pickupTime = calendar.date(bySettingHour: currentHour, minute: 0, second: 0, of: now) ?? now
            }
            
            let dropoffTime = calendar.date(byAdding: .hour, value: 2, to: pickupTime) ?? pickupTime
            
            selectedTimes = [pickupTime, dropoffTime]
            
            print("   📅 Same drop-off dates: \(selectedDates)")
            print("   ⏰ Same drop-off times: \(selectedTimes)")
            
        } else {
            // Different drop-off: 2 days later
            print("🚗 Initializing for DIFFERENT drop-off")
            
            let pickupDate = now
            let dropoffDate = calendar.date(byAdding: .day, value: 2, to: now) ?? now
            
            selectedDates = [pickupDate, dropoffDate]
            
            let pickupTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
            let dropoffTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now
            
            selectedTimes = [pickupTime, dropoffTime]
            
            print("   📅 Different drop-off dates: \(selectedDates)")
            print("   ⏰ Different drop-off times: \(selectedTimes)")
        }
    }
    
    private func getCurrentSelectedTime() -> String {
        guard let activeSelection = activeTimeSelection else { return "09:00" }
        
        switch activeSelection {
        case .pickup:
            return formatFirstTime()
        case .dropoff:
            return formatSecondTime()
        }
    }
    
    private func selectTime(_ timeString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: timeString) else { return }
        
        guard let activeSelection = activeTimeSelection else { return }
        
        switch activeSelection {
        case .pickup:
            updateFirstTime(time)
        case .dropoff:
            updateSecondTime(time)
        }
    }
    
    private func formatFirstDate() -> String {
        guard let firstDate = selectedDates.first else {
            return "select.date".localized
        }
        return dateFormatter.string(from: firstDate)
    }
    
    private func formatSecondDate() -> String {
        if selectedDates.count > 1, let secondDate = selectedDates.last {
            return dateFormatter.string(from: secondDate)
        } else if (isSameDropOff || isFromHotel), let firstDate = selectedDates.first {
            // For same drop-off or hotel, show appropriate date
            if isFromHotel {
                // Hotel: show tomorrow as default checkout
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: firstDate) ?? firstDate
                return dateFormatter.string(from: tomorrow)
            } else {
                // Same drop-off: show the same date
                return dateFormatter.string(from: firstDate)
            }
        }
        return "select.date".localized
    }
    
    private func formatFirstTime() -> String {
        guard selectedTimes.count > 0 else {
            return isFromHotel ? "15:00" : "09:00" // 3 PM for hotel, 9 AM for rental
        }
        return timeFormatter.string(from: selectedTimes[0])
    }
    
    private func formatSecondTime() -> String {
        guard selectedTimes.count > 1 else {
            return isFromHotel ? "11:00" : "10:00" // 11 AM checkout, 10 AM dropoff
        }
        return timeFormatter.string(from: selectedTimes[1])
    }
    
    private func updateFirstTime(_ newTime: Date) {
        if selectedTimes.count > 0 {
            selectedTimes[0] = newTime
        } else {
            selectedTimes.append(newTime)
        }
    }
    
    private func updateSecondTime(_ newTime: Date) {
        if selectedTimes.count > 1 {
            selectedTimes[1] = newTime
        } else if selectedTimes.count == 1 {
            selectedTimes.append(newTime)
        } else {
            let defaultFirstTime = Calendar.current.date(bySettingHour: isFromHotel ? 15 : 9, minute: 0, second: 0, of: Date()) ?? Date()
            selectedTimes = [defaultFirstTime, newTime]
        }
    }
}

// MARK: - Updated DateTimeCard (no changes needed, but showing for completeness)
struct DateTimeCard: View {
    let title: String
    let dateText: String
    let timeText: String
    let isSelected: Bool
    let onTimeTap: () -> Void
    
    private var ampmText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeText) {
            let hour = Calendar.current.component(.hour, from: time)
            return hour < 12 ? "am" : "pm"
        }
        return "pm"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .center) {
                // Date Section
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateText)
                        .font(CustomFont.font(.medium, weight: .semibold))
                        .foregroundColor(isSelected ? Color("Violet") : Color("Violet"))
                }
                
                // Time Section
                VStack(alignment: .trailing, spacing: 4) {
                    Button(action: onTimeTap) {
                        HStack {
                            Text(timeText)
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(isSelected ? Color("Violet") : Color("Violet"))
                                .padding(.vertical, 8)
                            
                            Text(ampmText)
                                .font(CustomFont.font(.regular, weight: .medium))
                                .foregroundColor(Color("Violet"))
                            
                            Image(systemName: "chevron.right")
                                .font(CustomFont.font(.regular, weight: .medium))
                                .foregroundColor(Color("Violet"))
                        }
                    }
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

// MARK: - TimePickerSection (no changes needed)
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
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let date = formatter.date(from: time) else { return time }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "h:mm a"
        return displayFormatter.string(from: date)
    }
}
