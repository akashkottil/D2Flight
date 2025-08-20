import Foundation

// MARK: - Localized Date Formatting Helper
struct LocalizedDateFormatter {
    
    // MARK: - Shared formatters
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    // MARK: - Custom format methods
    
    /// Format date as "E dd MMM" (e.g., "Mon 15 Jan") with localization using custom keys
    static func formatShortDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        // Get weekday index (0 = Sunday, 1 = Monday, etc.)
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        let localizedWeekday = CalendarLocalization.getLocalizedWeekdayName(for: weekdayIndex)
        
        // Get day number
        let dayNumber = calendar.component(.day, from: date)
        
        // Get month using custom localization
        let localizedMonth = CalendarLocalization.getLocalizedMonthName(for: date, isShort: true)
        
        return "\(localizedWeekday) \(dayNumber) \(localizedMonth)"
    }
    
    /// Format date as "E dd, MMM" (e.g., "Mon 15, Jan") with localization using custom keys
    static func formatShortDateWithComma(_ date: Date) -> String {
        let calendar = Calendar.current
        
        // Get weekday index (0 = Sunday, 1 = Monday, etc.)
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        let localizedWeekday = CalendarLocalization.getLocalizedWeekdayName(for: weekdayIndex)
        
        // Get day number
        let dayNumber = calendar.component(.day, from: date)
        
        // Get month using custom localization
        let localizedMonth = CalendarLocalization.getLocalizedMonthName(for: date, isShort: true)
        
        return "\(localizedWeekday) \(dayNumber), \(localizedMonth)"
    }
    
    /// Format travel date range for display
    static func formatTravelDateRange(departureDate: Date, returnDate: Date?, isOneWay: Bool) -> String {
        let departureDateString = formatShortDate(departureDate)
        
        if isOneWay || returnDate == nil {
            return departureDateString
        } else {
            let returnDateString = formatShortDate(returnDate!)
            return "\(departureDateString) - \(returnDateString)"
        }
    }
    
    /// Format single travel date for collapsed search
    static func formatTravelDate(from selectedDates: [Date], isOneWay: Bool) -> String {
        guard let firstDate = selectedDates.first else {
            return formatShortDate(Date()) // Fallback to today
        }
        
        if isOneWay || selectedDates.count == 1 {
            return formatShortDate(firstDate)
        } else if let secondDate = selectedDates.last {
            return "\(formatShortDate(firstDate)) - \(formatShortDate(secondDate))"
        } else {
            return formatShortDate(firstDate)
        }
    }
    
    /// Format date with custom pattern using current locale (fallback for system patterns)
    static func formatWithPattern(_ date: Date, pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
    
    /// Format date with custom pattern but use localized weekdays and months for common patterns
    static func formatWithLocalizedPattern(_ date: Date, pattern: String) -> String {
        // Check if it's a pattern we can localize
        if pattern.contains("E") && pattern.contains("MMM") {
            // This is likely a weekday + month pattern, use our custom localization
            if pattern.contains(",") {
                return formatShortDateWithComma(date)
            } else {
                return formatShortDate(date)
            }
        } else {
            // For other patterns, fall back to system formatter
            return formatWithPattern(date, pattern: pattern)
        }
    }
}

// MARK: - Date Extension for convenience
extension Date {
    
    /// Returns localized short date string (e.g., "Mon 15 Jan") using custom localization
    var localizedShortDateString: String {
        return LocalizedDateFormatter.formatShortDate(self)
    }
    
    /// Returns localized short date string with comma (e.g., "Mon 15, Jan") using custom localization
    var localizedShortDateStringWithComma: String {
        return LocalizedDateFormatter.formatShortDateWithComma(self)
    }
}
