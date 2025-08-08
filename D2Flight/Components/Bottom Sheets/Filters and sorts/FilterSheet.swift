import SwiftUI

// MARK: - Filter Type Enum
enum FilterType {
    case sort
    case times
    case airlines
    case duration
    case price
    case classes
}

// MARK: - Unified Filter Sheet
struct UnifiedFilterSheet: View {
    @Binding var isPresented: Bool
    let filterType: FilterType
    
    // Filter ViewModels and Bindings
    @ObservedObject var filterViewModel: FilterViewModel
    
    // Flight-specific properties
    let isRoundTrip: Bool
    let originCode: String
    let destinationCode: String
    let availableAirlines: [AirlineOption]
    let minPrice: Double
    let maxPrice: Double
    let averagePrice: Double
    
    var onApply: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(headerTitle)
                    .font(CustomFont.font(.large, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(CustomFont.font(.large, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.bottom, 20)
            
            // Content based on filter type
            ScrollView {
                contentView
                    .padding(.horizontal, 24)
                    .padding(.bottom, shouldShowBottomButtons ? 100 : 20)
            }
            
            Spacer()
            
            // Bottom Buttons (conditional)
            if shouldShowBottomButtons {
                bottomButtonsView
            } else {
                // Single Apply Button
                VStack {
                    PrimaryButton(
                        title: "Apply",
                        font: CustomFont.font(.large),
                        fontWeight: .semibold,
                        textColor: .white,
                        width: nil,
                        height: 56,
                        horizontalPadding: 24,
                        cornerRadius: 16,
                        action: {
                            onApply()
                            isPresented = false
                        }
                    )
                }
                .padding()
                .padding(.bottom, 24)
            }
        }
        .background(Color.white)
    }
    
    // MARK: - Header Title
    private var headerTitle: String {
        switch filterType {
        case .sort: return "Sort"
        case .times: return "Times"
        case .airlines: return "Airlines"
        case .duration: return "Duration"
        case .price: return "Price"
        case .classes: return "Classes"
        }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch filterType {
        case .sort:
            sortContent
        case .times:
            timesContent
        case .airlines:
            airlinesContent
        case .duration:
            durationContent
        case .price:
            priceContent
        case .classes:
            classesContent
        }
    }
    
    // MARK: - Sort Content
    private var sortContent: some View {
        VStack(spacing: 0) {
            ForEach(SortOption.allCases, id: \.self) { option in
                sortSelectionRow(
                    title: option.displayName,
                    option: option,
                    isSelected: filterViewModel.selectedSortOption == option
                )
            }
        }
    }
    
    private func sortSelectionRow(title: String, option: SortOption, isSelected: Bool) -> some View {
        Button(action: {
            filterViewModel.selectedSortOption = option
        }) {
            HStack {
                Text(title)
                    .font(CustomFont.font(.medium, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                ZStack {
                    if isSelected {
                        Circle()
                            .stroke(Color("Violet"), lineWidth: 6)
                            .frame(width: 20, height: 20)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Times Content
    private var timesContent: some View {
        VStack(spacing: 32) {
            // Departure Time Range
            VStack(alignment: .leading, spacing: 16) {
                Text("\(originCode) - \(destinationCode)")
                    .font(CustomFont.font(.medium, weight: .semibold))
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Taking off from \(originCode)")
                        .font(CustomFont.font(.medium, weight: .semibold))
                        .foregroundColor(.black)
                    
                    TimeRangeSlider(
                        range: $filterViewModel.departureTimeRange,
                        minTime: 0,
                        maxTime: 1440
                    )
                }
            }
            
            // Return Time Range (only for round trip)
            if isRoundTrip {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(destinationCode) - \(originCode)")
                        .font(CustomFont.font(.medium, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Taking off from \(destinationCode)")
                            .font(CustomFont.font(.medium, weight: .semibold))
                            .foregroundColor(.black)
                        
                        TimeRangeSlider(
                            range: $filterViewModel.returnTimeRange,
                            minTime: 0,
                            maxTime: 1440
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Airlines Content
    private var airlinesContent: some View {
          VStack(spacing: 0) {
              // Select All Option (always at top)
              airlineSelectionRow(
                  name: "Select All",
                  code: "ALL",
                  price: nil,
                  logo: "",
                  isSelected: filterViewModel.selectedAirlines.count == availableAirlines.count,
                  isSelectAll: true
              )
              
              // ✅ UPDATED: Use static sorting method (only sorts when sheet opens)
              ForEach(filterViewModel.cachedSortedAirlinesForSheet, id: \.code) { airline in
                  airlineSelectionRow(
                      name: airline.name,
                      code: airline.code,
                      price: airline.price,
                      logo: airline.logo,
                      isSelected: filterViewModel.selectedAirlines.contains(airline.code)
                  )
              }
          }
          .onAppear {
                  filterViewModel.cacheSortedAirlinesForSheet()
              }
      }
    
    private func getSortedAirlines() -> [AirlineOption] {
            return availableAirlines.sorted { airline1, airline2 in
                let isSelected1 = filterViewModel.selectedAirlines.contains(airline1.code)
                let isSelected2 = filterViewModel.selectedAirlines.contains(airline2.code)
                
                if isSelected1 && !isSelected2 {
                    return true // Selected airlines come first
                } else if !isSelected1 && isSelected2 {
                    return false // Non-selected airlines come after
                } else {
                    return airline1.name < airline2.name // Alphabetical within each group
                }
            }
        }
    
    private func airlineSelectionRow(
            name: String,
            code: String,
            price: Double?,
            logo: String,
            isSelected: Bool,
            isSelectAll: Bool = false
        ) -> some View {
            Button(action: {
                if isSelectAll {
                    if filterViewModel.selectedAirlines.count == availableAirlines.count {
                        // Deselect all
                        filterViewModel.selectedAirlines.removeAll()
                    } else {
                        // Select all
                        filterViewModel.selectedAirlines = Set(availableAirlines.map { $0.code })
                    }
                } else {
                    if filterViewModel.selectedAirlines.contains(code) {
                        filterViewModel.selectedAirlines.remove(code)
                    } else {
                        filterViewModel.selectedAirlines.insert(code)
                    }
                }
            }) {
                HStack(spacing: 16) {
                    // Checkbox
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color("Violet") : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isSelected ? Color("Violet") : Color.clear)
                            )
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(CustomFont.font(.small, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Airline Logo (only for individual airlines)
                    if !isSelectAll {
                        AsyncImage(url: URL(string: logo)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            // Fallback with airline initials
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.8))
                                .overlay(
                                    Text(String(name.prefix(2)))
                                        .font(CustomFont.font(.small, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                        .frame(width: 32, height: 32)
                        .cornerRadius(8)
                    }
                    
                    // Airline Name
                    Text(name)
                        .font(CustomFont.font(.medium, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // ✅ FIXED: Show real minimum price only if price > 0
                    if let price = price, price > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("₹\(Int(price))")
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.black)
                            Text("from")
                                .font(CustomFont.font(.tiny))
                                .foregroundColor(.gray)
                        }
                    } else if !isSelectAll {
                        // Show "Price varies" when no specific price is available
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Varies")
                                .font(CustomFont.font(.small, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .buttonStyle(PlainButtonStyle())
        }
    
    // MARK: - Duration Content
    private var durationContent: some View {
        VStack(spacing: 32) {
            // Departure Duration Filters
            VStack(alignment: .leading, spacing: 16) {
                Text("\(originCode) - \(destinationCode)")
                    .font(CustomFont.font(.regular, weight: .semibold))
                    .foregroundColor(.gray)
                
                VStack(spacing: 20) {
                    // Stopover Duration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Stopover")
                            .font(CustomFont.font(.regular, weight: .medium))
                            .foregroundColor(.black)
                        
                        DurationRangeSlider(
                            range: $filterViewModel.departureStopoverRange,
                            minDuration: 0,
                            maxDuration: 1440,
                            isDuration: true
                        )
                    }
                    
                    // Flight Leg Duration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Flight leg")
                            .font(CustomFont.font(.regular, weight: .medium))
                            .foregroundColor(.black)
                        
                        DurationRangeSlider(
                            range: $filterViewModel.departureLegRange,
                            minDuration: 0,
                            maxDuration: 1440,
                            isDuration: true
                        )
                    }
                }
            }
            
            // Return Duration Filters (only for round trip)
            if isRoundTrip {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(destinationCode) - \(originCode)")
                        .font(CustomFont.font(.regular, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 20) {
                        // Stopover Duration
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Stopover")
                                .font(CustomFont.font(.regular, weight: .medium))
                                .foregroundColor(.black)
                            
                            DurationRangeSlider(
                                range: $filterViewModel.returnStopoverRange,
                                minDuration: 0,
                                maxDuration: 1440,
                                isDuration: true
                            )
                        }
                        
                        // Flight Leg Duration
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Flight leg")
                                .font(CustomFont.font(.regular, weight: .medium))
                                .foregroundColor(.black)
                            
                            DurationRangeSlider(
                                range: $filterViewModel.returnLegRange,
                                minDuration: 0,
                                maxDuration: 1440,
                                isDuration: true
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Price Content
    private var priceContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Pricing Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Daily  + local taxes & fees")
                        .font(CustomFont.font(.regular, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.black)
                }
                
                Text("Average price is ₹\(Int(averagePrice))")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            // Price Slider
            PriceRangeSlider(
                range: $filterViewModel.priceRange,
                minPrice: minPrice,
                maxPrice: maxPrice
            )
        }
    }
    
    // MARK: - Classes Content
    private var classesContent: some View {
        VStack(spacing: 0) {
            ForEach(TravelClass.allCases, id: \.self) { travelClass in
                classSelectionRow(
                    title: travelClass.displayName,
                    travelClass: travelClass,
                    isSelected: filterViewModel.selectedClass == travelClass
                )
            }
        }
    }
    
    private func classSelectionRow(title: String, travelClass: TravelClass, isSelected: Bool) -> some View {
        Button(action: {
            filterViewModel.selectedClass = travelClass
        }) {
            HStack {
                Text(title)
                    .font(CustomFont.font(.medium, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                ZStack {
                    if isSelected {
                        Circle()
                            .stroke(Color("Violet"), lineWidth: 6)
                            .frame(width: 20, height: 20)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Bottom Buttons Helper
    private var shouldShowBottomButtons: Bool {
        switch filterType {
        case .times, .duration, .price:
            return true
        case .sort, .airlines, .classes:
            return false
        }
    }
    
    private var bottomButtonsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                SecondaryButton(
                    title: "Clear",
                    font: CustomFont.font(.medium),
                    fontWeight: .semibold,
                    textColor: .gray,
                    width: nil,
                    height: 56,
                    cornerRadius: 16,
                    action: {
                        clearFilters()
                    }
                )
                
                PrimaryButton(
                    title: "Apply",
                    font: CustomFont.font(.medium),
                    fontWeight: .semibold,
                    textColor: .white,
                    width: nil,
                    height: 56,
                    cornerRadius: 16,
                    action: {
                        onApply()
                        isPresented = false
                    }
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Clear Filters Helper
    private func clearFilters() {
        switch filterType {
        case .times:
            filterViewModel.departureTimeRange = 0...1440
            filterViewModel.returnTimeRange = 0...1440
        case .duration:
            filterViewModel.departureStopoverRange = 0...1440
            filterViewModel.departureLegRange = 0...1440
            filterViewModel.returnStopoverRange = 0...1440
            filterViewModel.returnLegRange = 0...1440
            // Reset max duration to API max value
            filterViewModel.maxDuration = 1440
        case .price:
            filterViewModel.priceRange = minPrice...maxPrice
        default:
            break
        }
    }
    
    struct DurationRangeSlider: View {
        @Binding var range: ClosedRange<Double>
        let minDuration: Double
        let maxDuration: Double
        let isDuration: Bool

        var body: some View {
            VStack(spacing: 12) {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let trackHeight: CGFloat = 20
                    let thumbSize: CGFloat = 16

                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: trackHeight)

                        // Selected range (active track)
                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .fill(Color("Violet"))
                            .frame(
                                width: CGFloat((range.upperBound - range.lowerBound) / (maxDuration - minDuration)) * width,
                                height: trackHeight
                            )
                            .offset(x: CGFloat((range.lowerBound - minDuration) / (maxDuration - minDuration)) * width)

                        // Lower thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: thumbSize, height: thumbSize)
                            .overlay(
                                Circle()
                                    .stroke(Color("Violet"), lineWidth: 3)
                            )
    //                        .shadow(radius: 1)
                            .offset(x: CGFloat((range.lowerBound - minDuration) / (maxDuration - minDuration)) * width - thumbSize / 50)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let location = max(0, min(Double(value.location.x), width))
                                        let newValue = minDuration + (location / width) * (maxDuration - minDuration)
                                        let clampedValue = max(minDuration, min(range.upperBound, newValue))
                                        range = clampedValue...range.upperBound
                                    }
                            )

                        // Upper thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: thumbSize, height: thumbSize)
                            .overlay(
                                Circle()
                                    .stroke(Color("Violet"), lineWidth: 3)
                            )
                            .offset(x: CGFloat((range.upperBound - minDuration) / (maxDuration - minDuration)) * width - thumbSize )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let location = max(0, min(Double(value.location.x), width))
                                        let newValue = minDuration + (location / width) * (maxDuration - minDuration)
                                        let clampedValue = max(range.lowerBound, min(maxDuration, newValue))
                                        range = range.lowerBound...clampedValue
                                    }
                            )
                    }
                }
                .frame(height: 28)

                // Duration labels
                HStack {
                    Text(isDuration ? formatDuration(range.lowerBound) : formatTime(range.lowerBound))
                        .font(CustomFont.font(.small))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(isDuration ? formatDuration(range.upperBound) : formatTime(range.upperBound))
                        .font(CustomFont.font(.small))
                        .foregroundColor(.gray)
                }
            }
        }

        private func formatTime(_ minutes: Double) -> String {
            let totalMinutes = Int(minutes)
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return String(format: "%02d:%02d", hours, mins)
        }

        private func formatDuration(_ minutes: Double) -> String {
            let totalMinutes = Int(minutes)
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return "\(hours)h \(mins)m"
        }
    }
    
    struct PriceRangeSlider: View {
        @Binding var range: ClosedRange<Double>
        let minPrice: Double
        let maxPrice: Double

        var body: some View {
            VStack(spacing: 12) {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let trackHeight: CGFloat = 20
                    let thumbSize: CGFloat = 16

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: trackHeight)

                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .fill(Color("Violet"))
                            .frame(
                                width: CGFloat((range.upperBound - range.lowerBound) / (maxPrice - minPrice)) * width,
                                height: trackHeight
                            )
                            .offset(x: CGFloat((range.lowerBound - minPrice) / (maxPrice - minPrice)) * width)

                        // Lower thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: thumbSize, height: thumbSize)
                            .overlay(Circle().stroke(Color("Violet"), lineWidth: 3))
                            .offset(x: CGFloat((range.lowerBound - minPrice) / (maxPrice - minPrice)) * width - thumbSize / 50)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let location = max(0, min(Double(value.location.x), width))
                                        let newValue = minPrice + (location / width) * (maxPrice - minPrice)
                                        let clampedValue = max(minPrice, min(range.upperBound, newValue))
                                        range = clampedValue...range.upperBound
                                    }
                            )

                        // Upper thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: thumbSize, height: thumbSize)
                            .overlay(Circle().stroke(Color("Violet"), lineWidth: 3))
                            .offset(x: CGFloat((range.upperBound - minPrice) / (maxPrice - minPrice)) * width - thumbSize)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let location = max(0, min(Double(value.location.x), width))
                                        let newValue = minPrice + (location / width) * (maxPrice - minPrice)
                                        let clampedValue = max(range.lowerBound, min(maxPrice, newValue))
                                        range = range.lowerBound...clampedValue
                                    }
                            )
                    }
                }
                .frame(height: 28)

                // Price labels
                HStack {
                    Text("$\(Int(range.lowerBound))")
                        .font(CustomFont.font(.small))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("$\(Int(range.upperBound))")
                        .font(CustomFont.font(.small))
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    UnifiedFilterSheet(
        isPresented: .constant(true),
        filterType: .airlines,
        filterViewModel: FilterViewModel(),
        isRoundTrip: true,
        originCode: "CCJ",
        destinationCode: "CNN",
        availableAirlines: [
            AirlineOption(code: "QR", name: "Qatar Airways", logo: "", price: 350),
            AirlineOption(code: "EK", name: "Emirates", logo: "", price: 350),
            AirlineOption(code: "UK", name: "Vistara", logo: "", price: 350)
        ],
        minPrice: 0,
        maxPrice: 1000,
        averagePrice: 250,
        onApply: {}
    )
}
