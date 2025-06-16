import SwiftUI

struct DateTimeSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDates: [Date]
    @Binding var selectedTimes: [Date]
    let isSameDropOff: Bool
    var onDatesSelected: ([Date], [Date]) -> Void
    
    @State private var showTimePicker = false
    @State private var activeTimeSelection: TimeSelectionType?
    
    enum TimeSelectionType {
        case pickup, dropoff
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
    
    // Filter times based on current time if date is today
    private var availableTimeOptions: [String] {
        guard let activeSelection = activeTimeSelection else { return allTimeOptions }
        
        let selectedDate: Date?
        switch activeSelection {
        case .pickup:
            selectedDate = selectedDates.first
        case .dropoff:
            if selectedDates.count > 1 {
                selectedDate = selectedDates.last
            } else if isSameDropOff, let firstDate = selectedDates.first {
                selectedDate = Calendar.current.date(byAdding: .day, value: 2, to: firstDate)
            } else {
                selectedDate = nil
            }
        }
        
        guard let date = selectedDate else { return allTimeOptions }
        
        // Check if selected date is today
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: Date()) {
            let currentHour = calendar.component(.hour, from: Date())
            return allTimeOptions.filter { timeString in
                let hour = Int(timeString.prefix(2)) ?? 0
                return hour > currentHour
            }
        }
        
        return allTimeOptions
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
                
                Text("Select dates & times")
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.trailing, 44)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Weekday Headers
            HStack(spacing: 8) {
                ForEach(["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"], id: \.self) { day in
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
                    isRoundTrip: !isSameDropOff
                )
                
                // Bottom section overlay
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Date and Time selection cards
                        HStack(spacing: 12) {
                            // Pick-up Date and Time
                            DateTimeCard(
                                title: "Pick-up",
                                dateText: formatPickUpDate(),
                                timeText: formatPickUpTime(),
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
                            
                            // Drop-off Date and Time (always shown, but location may be same)
                            DateTimeCard(
                                title: isSameDropOff ? "Drop-off (Same location)" : "Drop-off",
                                dateText: formatDropOffDate(),
                                timeText: formatDropOffTime(),
                                isSelected: selectedDates.count > 1 || isSameDropOff,
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
                                title: activeTimeSelection == .pickup ? "Select Pick-up Time" : "Select Drop-off Time",
                                timeOptions: availableTimeOptions,
                                selectedTime: getCurrentSelectedTime(),
                                onTimeSelected: { timeString in
                                    selectTime(timeString)
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showTimePicker = false
                                        activeTimeSelection = nil
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
                            title: "Apply",
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
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .background(Color.white)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            initializeTimesIfNeeded()
        }
    }
    
    private func initializeTimesIfNeeded() {
        if selectedTimes.isEmpty {
            // Default pick-up time: 9:00 AM
            let pickUpTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            // Default drop-off time: 10:00 AM
            let dropOffTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
            selectedTimes = [pickUpTime, dropOffTime]
        } else if selectedTimes.count == 1 {
            // Ensure we have both times
            let dropOffTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
            selectedTimes.append(dropOffTime)
        }
    }
    
    private func getCurrentSelectedTime() -> String {
        guard let activeSelection = activeTimeSelection else { return "09:00" }
        
        switch activeSelection {
        case .pickup:
            return formatPickUpTime()
        case .dropoff:
            return formatDropOffTime()
        }
    }
    
    private func selectTime(_ timeString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let time = formatter.date(from: timeString) else { return }
        
        guard let activeSelection = activeTimeSelection else { return }
        
        switch activeSelection {
        case .pickup:
            updatePickUpTime(time)
        case .dropoff:
            updateDropOffTime(time)
        }
    }
    
    private func formatPickUpDate() -> String {
        guard let firstDate = selectedDates.first else {
            return "Select date"
        }
        return dateFormatter.string(from: firstDate)
    }
    
    private func formatDropOffDate() -> String {
        if selectedDates.count > 1, let secondDate = selectedDates.last {
            return dateFormatter.string(from: secondDate)
        } else if isSameDropOff, let firstDate = selectedDates.first {
            // For same drop-off, use a default return date (e.g., 2 days later)
            let defaultReturnDate = Calendar.current.date(byAdding: .day, value: 2, to: firstDate) ?? firstDate
            return dateFormatter.string(from: defaultReturnDate)
        }
        return "Select date"
    }
    
    private func formatPickUpTime() -> String {
        guard selectedTimes.count > 0 else { return "09:00" }
        return timeFormatter.string(from: selectedTimes[0])
    }
    
    private func formatDropOffTime() -> String {
        guard selectedTimes.count > 1 else { return "10:00" }
        return timeFormatter.string(from: selectedTimes[1])
    }
    
    private func updatePickUpTime(_ newTime: Date) {
        if selectedTimes.count > 0 {
            selectedTimes[0] = newTime
        } else {
            selectedTimes.append(newTime)
        }
    }
    
    private func updateDropOffTime(_ newTime: Date) {
        if selectedTimes.count > 1 {
            selectedTimes[1] = newTime
        } else if selectedTimes.count == 1 {
            selectedTimes.append(newTime)
        } else {
            // This shouldn't happen, but handle it gracefully
            let pickUpTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            selectedTimes = [pickUpTime, newTime]
        }
    }
}

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

struct TimePickerSection: View {
    let title: String
    let timeOptions: [String]
    let selectedTime: String
    let onTimeSelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Text(title)
                    .font(CustomFont.font(.large, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            // Time Options
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(timeOptions, id: \.self) { time in
                        TimeOptionRow(
                            timeText: time,
                            isSelected: selectedTime == time,
                            onTap: {
                                onTimeSelected(time)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 250)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
    }
}

struct TimeOptionRow: View {
    let timeText: String
    let isSelected: Bool
    let onTap: () -> Void
    
    private var displayTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeText) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "h:mm"
            return displayFormatter.string(from: time)
        }
        return timeText
    }
    
    private var ampmText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeText) {
            let hour = Calendar.current.component(.hour, from: time)
            return hour < 12 ? "AM" : "PM"
        }
        return "PM"
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("\(displayTime) \(ampmText)")
                    .font(CustomFont.font(.medium, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color("Violet") : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(CustomFont.font(.regular, weight: .semibold))
                        .foregroundColor(Color("Violet"))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                isSelected ? Color("Violet").opacity(0.1) : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimePickerSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedTime: Date
    let onTimeSelected: (Date) -> Void
    
    @State private var showTimePicker = true
    
    private let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .font(CustomFont.font(.medium, weight: .medium))
                .foregroundColor(Color("Violet"))
                
                Spacer()
                
                Text("Select Time")
                    .font(CustomFont.font(.large, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Done") {
                    onTimeSelected(selectedTime)
                    presentationMode.wrappedValue.dismiss()
                }
                .font(CustomFont.font(.medium, weight: .semibold))
                .foregroundColor(Color("Violet"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            VStack(spacing: 20) {
                // Time Display Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected Time")
                        .font(CustomFont.font(.regular, weight: .medium))
                        .foregroundColor(.gray)
                    
                    // Time Selector Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showTimePicker.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(hourFormatter.string(from: selectedTime))
                                .font(CustomFont.font(.large, weight: .semibold))
                                .foregroundColor(Color("Violet"))
                            
                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(showTimePicker ? 180 : 0))
                                .foregroundColor(Color("Violet"))
                                .font(CustomFont.font(.regular, weight: .medium))
                                .animation(.easeInOut(duration: 0.3), value: showTimePicker)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("Violet"), lineWidth: 2)
                )
                .cornerRadius(16)
                .padding(.horizontal, 20)
                
                // Time Picker
                if showTimePicker {
                    VStack(spacing: 0) {
                        DatePicker(
                            "",
                            selection: $selectedTime,
                            in: availableTimeRange(),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.3), value: showTimePicker)
                }
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    // 🔒 Disables past times if today is selected
    private func availableTimeRange() -> ClosedRange<Date> {
        let now = Date()
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: selectedTime)
        let today = calendar.startOfDay(for: now)
        
        if selectedDay == today {
            return now...calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        } else {
            let start = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: selectedTime)!
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: selectedTime)!
            return start...end
        }
    }
}

#Preview {
    DateTimeSelectionView(
        selectedDates: .constant([Date()]),
        selectedTimes: .constant([Date(), Date()]),
        isSameDropOff: false
    ) { _, _ in }
}
