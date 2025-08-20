
import SwiftUI

struct DateSelectionView: View {
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
    
    // Add this new initializer
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
    
    // ADD this original initializer for FlightView/RentalView compatibility
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
            
            // Weekday Headers
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
        .padding(.vertical,10)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .background(Color.white)
        .toolbar(.hidden, for: .tabBar) // Hide tab bar
    }
    
    private func formatDepartureDate() -> String {
        guard let firstDate = selectedDates.first else {
            return "select.date".localized
        }
        return dateFormatter.string(from: firstDate)
    }
    
    private func formatReturnDate() -> String {
        if selectedDates.count > 1, let secondDate = selectedDates.last {
            return dateFormatter.string(from: secondDate)
        }
        
        // Return different placeholder based on context
        if isFromHotel {
            return "add.check-out".localized
        } else {
            return "add.return".localized
        }
    }
}

struct DateCard: View {
    let title: String
    let dateText: String
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(CustomFont.font(.regular, weight: .medium))
                .foregroundColor(.gray)
            
            Text(dateText)
                .font(CustomFont.font(.medium, weight: .semibold))
                .foregroundColor(isSelected ? Color("Violet") : Color("Violet"))
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

#Preview {
    DateSelectionView(
        selectedDates: .constant([Date()]),
        isFromHotel: false
    ) { _ in }
}
