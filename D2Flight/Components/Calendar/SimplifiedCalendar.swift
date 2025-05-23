//
//  SimplifiedCalendar.swift
//  M2-Flight-Ios
//
//  Simplified calendar component for date selection
//

import SwiftUI

struct SimplifiedCalendar: View {
    @Binding var selectedDates: [Date]
    @State private var currentDate = Date()
    let isRoundTrip: Bool
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 40) {
                // Show current month and next month
                ForEach(0..<2, id: \.self) { monthOffset in
                    if let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: currentDate) {
                        MonthCalendarView(
                            month: monthDate,
                            selectedDates: $selectedDates,
                            isRoundTrip: isRoundTrip
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 180) // Space for bottom section
        }
    }
}

struct MonthCalendarView: View {
    let month: Date
    @Binding var selectedDates: [Date]
    let isRoundTrip: Bool
    
    private let calendar = Calendar.current
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let numberOfDaysInMonth = calendar.component(.day, from: monthInterval.end.addingTimeInterval(-1))
        
        var days: [Date?] = []
        
        // Add empty days for the beginning of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add days of the month
        for day in 1...numberOfDaysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month title
            Text(monthTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                // Days of the month
                ForEach(daysInMonth.indices, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        DayButton(
                            date: date,
                            selectedDates: $selectedDates,
                            isRoundTrip: isRoundTrip
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
}

struct DayButton: View {
    let date: Date
    @Binding var selectedDates: [Date]
    let isRoundTrip: Bool
    
    private let calendar = Calendar.current
    
    private var isSelected: Bool {
        selectedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
    
    private var isPastDate: Bool {
        calendar.compare(date, to: Date(), toGranularity: .day) == .orderedAscending
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: {
            handleDateSelection()
        }) {
            Text(dayNumber)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : (isPastDate ? .gray : .black))
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Color("Violet") : Color.clear)
                )
        }
        .disabled(isPastDate)
    }
    
    private func handleDateSelection() {
        if isRoundTrip {
            // Round trip logic
            if selectedDates.isEmpty {
                // First date
                selectedDates = [date]
            } else if selectedDates.count == 1 {
                // Second date
                let firstDate = selectedDates[0]
                if calendar.isDate(date, inSameDayAs: firstDate) {
                    // Same date clicked, keep as single selection
                    return
                } else {
                    // Add second date, ensure chronological order
                    let sortedDates = [firstDate, date].sorted()
                    selectedDates = sortedDates
                }
            } else {
                // Start fresh with new selection
                selectedDates = [date]
            }
        } else {
            // One way - single date selection
            selectedDates = [date]
        }
    }
}

#Preview {
    SimplifiedCalendar(
        selectedDates: .constant([Date()]),
        isRoundTrip: true
    )
}
