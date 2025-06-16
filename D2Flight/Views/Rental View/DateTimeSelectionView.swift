import SwiftUI

struct DateTimeSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDates: [Date]
    @Binding var selectedTimes: [Date]
    let isSameDropOff: Bool
    var onDatesSelected: ([Date], [Date]) -> Void
    
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
                        .font(.system(size: 14, weight: .medium))
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
                        VStack(spacing: 12) {
                            // Pick-up Date and Time
                            DateTimeCard(
                                title: "Pick-up",
                                dateText: formatPickUpDate(),
                                timeText: formatPickUpTime(),
                                isSelected: !selectedDates.isEmpty,
                                onTimeChange: { newTime in
                                    updatePickUpTime(newTime)
                                }
                            )
                            
                            // Drop-off Date and Time (always shown, but location may be same)
                            DateTimeCard(
                                title: isSameDropOff ? "Drop-off (Same location)" : "Drop-off",
                                dateText: formatDropOffDate(),
                                timeText: formatDropOffTime(),
                                isSelected: selectedDates.count > 1 || isSameDropOff,
                                onTimeChange: { newTime in
                                    updateDropOffTime(newTime)
                                }
                            )
                        }
                        .padding()
                        
                        // Apply button
                        PrimaryButton(
                            title: "Apply",
                            font: .system(size: 18),
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
    let onTimeChange: (Date) -> Void
    
    @State private var showTimePicker = false
    @State private var selectedTime = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            HStack {
                // Date Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Text(dateText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? Color("Violet") : Color("Violet"))
                }
                
                Spacer()
                
                // Time Section
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Time")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        showTimePicker = true
                    }) {
                        Text(timeText)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? Color("Violet") : Color("Violet"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color("Violet"), lineWidth: 1)
                                    .background(Color("Violet").opacity(0.1))
                            )
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
        .sheet(isPresented: $showTimePicker) {
            TimePickerSheet(
                selectedTime: $selectedTime,
                onTimeSelected: { time in
                    onTimeChange(time)
                }
            )
        }
        .onAppear {
            // Initialize selectedTime from timeText
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            if let time = formatter.date(from: timeText) {
                selectedTime = time
            }
        }
    }
}

struct TimePickerSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedTime: Date
    let onTimeSelected: (Date) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding()
                
                Spacer()
                
                PrimaryButton(
                    title: "Done",
                    font: .system(size: 16),
                    fontWeight: .semibold,
                    textColor: .white,
                    verticalPadding: 16,
                    horizontalPadding: 24,
                    cornerRadius: 12
                ) {
                    onTimeSelected(selectedTime)
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            }
            .navigationTitle("Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
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
