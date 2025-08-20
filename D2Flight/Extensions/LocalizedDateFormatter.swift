

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
    
    /// Format date as "E dd MMM" (e.g., "Mon 15 Jan") with localization
    static func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        // Get localized day and month
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale.current
        dayFormatter.dateFormat = "E" // Short weekday
        let localizedDay = dayFormatter.string(from: date)
        
        let dayNumber = Calendar.current.component(.day, from: date)
        
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale.current
        monthFormatter.dateFormat = "MMM" // Short month
        let localizedMonth = monthFormatter.string(from: date)
        
        return "\(localizedDay) \(dayNumber) \(localizedMonth)"
    }
    
    /// Format date as "E dd, MMM" (e.g., "Mon 15, Jan") with localization
    static func formatShortDateWithComma(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        // Get localized day and month
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale.current
        dayFormatter.dateFormat = "E" // Short weekday
        let localizedDay = dayFormatter.string(from: date)
        
        let dayNumber = Calendar.current.component(.day, from: date)
        
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale.current
        monthFormatter.dateFormat = "MMM" // Short month
        let localizedMonth = monthFormatter.string(from: date)
        
        return "\(localizedDay) \(dayNumber), \(localizedMonth)"
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
    
    /// Format date with custom pattern using current locale
    static func formatWithPattern(_ date: Date, pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }
}

// MARK: - Date Extension for convenience
extension Date {
    
    /// Returns localized short date string (e.g., "Mon 15 Jan")
    var localizedShortDateString: String {
        return LocalizedDateFormatter.formatShortDate(self)
    }
    
    /// Returns localized short date string with comma (e.g., "Mon 15, Jan")
    var localizedShortDateStringWithComma: String {
        return LocalizedDateFormatter.formatShortDateWithComma(self)
    }
}
