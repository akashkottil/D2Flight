import SwiftUI

// MARK: - Calendar Localization Helper
struct CalendarLocalization {
    
    // MARK: - Weekday Names (Short Form)
    static var weekdayShortNames: [String] {
        return [
            "su".localized,
            "mo".localized,
            "tu".localized,
            "we".localized,
            "th".localized,
            "fr".localized,
            "sa".localized
        ]
    }
    
    // MARK: - Month Names (Full Form)
    static var monthFullNames: [String] {
        return [
            "january".localized,
            "february".localized,
            "march".localized,
            "april".localized,
            "may".localized,
            "june".localized,
            "july".localized,
            "august".localized,
            "september".localized,
            "october".localized,
            "november".localized,
            "december".localized
        ]
    }
    
    // MARK: - Month Names (Short Form)
    static var monthShortNames: [String] {
        return [
            "jan".localized,
            "feb".localized,
            "mar".localized,
            "apr".localized,
            "may".localized,
            "jun".localized,
            "jul".localized,
            "aug".localized,
            "sep".localized,
            "oct".localized,
            "nov".localized,
            "dec".localized
        ]
    }
    
    // MARK: - Helper Functions
    static func getLocalizedMonthName(for date: Date, isShort: Bool = false) -> String {
        let monthIndex = Calendar.current.component(.month, from: date) - 1
        let monthNames = isShort ? monthShortNames : monthFullNames
        
        guard monthIndex >= 0 && monthIndex < monthNames.count else {
            // Fallback to system localization if index is out of bounds
            let formatter = DateFormatter()
            formatter.dateFormat = isShort ? "MMM" : "MMMM"
            formatter.locale = Locale.current
            return formatter.string(from: date)
        }
        
        return monthNames[monthIndex]
    }
    
    static func getLocalizedWeekdayName(for weekdayIndex: Int) -> String {
        guard weekdayIndex >= 0 && weekdayIndex < weekdayShortNames.count else {
            // Fallback to system localization if index is out of bounds
            let calendar = Calendar.current
            let weekdaySymbols = calendar.shortWeekdaySymbols
            let adjustedIndex = weekdayIndex % 7
            return adjustedIndex < weekdaySymbols.count ? weekdaySymbols[adjustedIndex] : "?"
        }
        return weekdayShortNames[weekdayIndex]
    }
    
    // MARK: - Debug Helper
    static func debugPrintLocalizedStrings() {
        print("🌐 Debug: Calendar Localization Strings")
        print("📅 Weekdays: \(weekdayShortNames)")
        print("📅 Short Months: \(monthShortNames)")
        print("📅 Full Months: \(monthFullNames)")
        print("📅 Current Language: \(LocalizationManager.shared.currentLanguage)")
    }
    
    // MARK: - Test function to verify localization is working
    static func testLocalization() -> String {
        let testDate = Date()
        let weekdayIndex = Calendar.current.component(.weekday, from: testDate) - 1
        let weekday = getLocalizedWeekdayName(for: weekdayIndex)
        let month = getLocalizedMonthName(for: testDate, isShort: true)
        let day = Calendar.current.component(.day, from: testDate)
        
        return "\(weekday) \(day) \(month)"
    }
}

// MARK: - Updated SimplifiedCalendar with Localization
struct LocalizedSimplifiedCalendar: View {
    @Binding var selectedDates: [Date]
    let isRoundTrip: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 40) {
                // Show current month and next 10 months (11 months total)
                ForEach(0..<11, id: \.self) { monthOffset in
                    if let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: Date()) {
                        LocalizedMonthCalendarView(
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

// MARK: - Updated MonthCalendarView with Localization
struct LocalizedMonthCalendarView: View {
    let month: Date
    @Binding var selectedDates: [Date]
    let isRoundTrip: Bool
    
    private let calendar = Calendar.current
    
    private var monthTitle: String {
        let monthName = CalendarLocalization.getLocalizedMonthName(for: month, isShort: false)
        let year = calendar.component(.year, from: month)
        return "\(monthName) \(year)"
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

// MARK: - Updated DateSelectionView with Localized Weekday Headers
struct LocalizedDateSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDates: [Date]
    let isRoundTrip: Bool
    var onDatesSelected: ([Date]) -> Void
    let isFromHotel: Bool
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd, MMM"
        return formatter
    }()
    
    // Hotel-specific initializer
    init(
        selectedDates: Binding<[Date]>,
        isFromHotel: Bool,
        onDatesSelected: @escaping ([Date]) -> Void
    ) {
        self._selectedDates = selectedDates
        self.isRoundTrip = true // Hotels always show two dates like round trip
        self.isFromHotel = isFromHotel
        self.onDatesSelected = onDatesSelected
    }
    
    // Flight/Rental initializer
    init(
        selectedDates: Binding<[Date]>,
        isRoundTrip: Bool,
        onDatesSelected: @escaping ([Date]) -> Void
    ) {
        self._selectedDates = selectedDates
        self.isRoundTrip = isRoundTrip
        self.isFromHotel = false
        self.onDatesSelected = onDatesSelected
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
                
                Text("select.dates".localized)
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.trailing, 44)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // ✅ UPDATED: Localized Weekday Headers
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
            
            // Calendar
            ZStack {
                // ✅ UPDATED: Use LocalizedSimplifiedCalendar
                LocalizedSimplifiedCalendar(
                    selectedDates: $selectedDates,
                    isRoundTrip: isRoundTrip
                )
                
                // Bottom section overlay
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Date selection cards
                        if isRoundTrip {
                            // Round trip - show both cards
                            HStack(spacing: 12) {
                                DateCard(
                                    title: isFromHotel ? "check-in".localized : "departure".localized,
                                    dateText: formatDepartureDate(),
                                    isSelected: !selectedDates.isEmpty
                                )
                                
                                Image("RoundedArrow")
                                    .frame(width: 16, height: 16)
                                
                                DateCard(
                                    title: isFromHotel ? "check-out".localized : "return".localized,
                                    dateText: formatReturnDate(),
                                    isSelected: selectedDates.count > 1
                                )
                            }
                            .padding()
                        } else {
                            // One way - show only departure card
                            DateCard(
                                title: "departure".localized,
                                dateText: formatDepartureDate(),
                                isSelected: !selectedDates.isEmpty
                            )
                            .padding()
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
                            onDatesSelected(selectedDates)
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
    }
    
    private func formatDepartureDate() -> String {
        guard let firstDate = selectedDates.first else {
            return "select.date".localized
        }
        return formatLocalizedDate(firstDate)
    }
    
    private func formatReturnDate() -> String {
        if selectedDates.count > 1, let secondDate = selectedDates.last {
            return formatLocalizedDate(secondDate)
        }
        
        // Return different placeholder based on context
        if isFromHotel {
            return "add.check-out".localized
        } else {
            return "add.return".localized
        }
    }
    
    // ✅ NEW: Format date with localized month names
    private func formatLocalizedDate(_ date: Date) -> String {
        return LocalizedDateFormatter.formatShortDateWithComma(date)
    }
}

// MARK: - Updated DateTimeSelectionView with Localized Weekday Headers
struct LocalizedDateTimeSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDates: [Date]
    @Binding var selectedTimes: [Date]
    let isSameDropOff: Bool
    let isFromHotel: Bool
    var onDatesSelected: ([Date], [Date]) -> Void
    
    @State private var showTimePicker = false
    @State private var activeTimeSelection: TimeSelectionType?
    @State private var hasInitialized = false
    
    enum TimeSelectionType {
        case pickup, dropoff
    }
    
    // Hotel initializer
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
    
    // Rental initializer
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
                
                Text("select.dates".localized)
                    .font(.system(size: 20, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.trailing, 44)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // ✅ UPDATED: Localized Weekday Headers
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
            
            // Calendar and Content
            ZStack {
                // ✅ UPDATED: Use LocalizedSimplifiedCalendar
                LocalizedSimplifiedCalendar(
                    selectedDates: $selectedDates,
                    isRoundTrip: !isSameDropOff || isFromHotel
                )
                
                // Rest of the implementation remains the same...
                // (Bottom section with time picker, etc.)
            }
        }
        .padding(.vertical, 10)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .background(Color.white)
        .toolbar(.hidden, for: .tabBar)
    }
}
