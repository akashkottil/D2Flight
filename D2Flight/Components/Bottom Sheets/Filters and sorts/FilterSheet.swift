import SwiftUI

// MARK: - Updated Filter Type Enum
enum FilterType {
    case sort
    case times
    case airlines
    case duration
    case price
    case classes
    case stops // ✅ NEW: Added stops filter type
}

// MARK: - Stops Option Model (Updated)
enum StopsOption: CaseIterable {
    case any
    case direct
    case oneStop
    case twoStops
    
    var title: String {
        switch self {
        case .any: return "any".localized
        case .direct: return "direct".localized
        case .oneStop: return "1.stop".localized
        case .twoStops: return "2.stops".localized
        }
    }
    
    var subtitle: String {
        switch self {
        case .any: return "show.all.flights".localized
        case .direct: return "non.stop.flights.only".localized
        case .oneStop: return "exactly.1.stopover".localized  // Changed subtitle
        case .twoStops: return "exactly.2.stopovers".localized // Changed subtitle
        }
    }
    
    var exactStops: Int? {
        switch self {
        case .any: return nil
        case .direct: return 0
        case .oneStop: return 1
        case .twoStops: return 2
        }
    }
    
    var maxStops: Int? {
        switch self {
        case .any: return nil // Will be converted to 3 in the filter
        case .direct: return 0
        case .oneStop: return 1
        case .twoStops: return 2
        }
    }
    
    // Helper to convert from exactStops value back to option
    static func fromExactStops(_ stops: Int) -> StopsOption {
        switch stops {
        case 0: return .direct
        case 1: return .oneStop
        case 2: return .twoStops
        default: return .any
        }
    }
    
    // Keep the existing helper for backward compatibility
    static func fromMaxStops(_ maxStops: Int) -> StopsOption {
        switch maxStops {
        case 0: return .direct
        case 1: return .oneStop
        case 2: return .twoStops
        default: return .any
        }
    }
}

// MARK: - Updated Unified Filter Sheet
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
                        title: "apply".localized,
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
        case .sort: return "sort".localized
        case .times: return "times".localized
        case .airlines: return "airlines".localized
        case .duration: return "duration".localized
        case .price: return "price".localized
        case .classes: return "classes".localized
        case .stops: return "stops".localized // ✅ NEW
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
        case .stops: // ✅ NEW
            stopsContent
        }
    }
    
    // ✅ NEW: Stops Content (Similar to Sort Content)
    private var stopsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
                ForEach(StopsOption.allCases, id: \.self) { option in
                    stopsSelectionRow(
                        title: option.title,
                        subtitle: option.subtitle,
                        option: option,
                        isSelected: getCurrentStopsSelection() == option
                    )
                }
            }.onAppear {
            // ✅ ADD: Sync current stops selection on appear
            print("🛑 Stops filter opened - syncing current state")
            print("   Current maxStops: \(filterViewModel.maxStops)")
            print("   Current exactStops: \(filterViewModel.exactStops?.description ?? "nil")")
            print("   Current isExactStopsFilter: \(filterViewModel.isExactStopsFilter)")
        }
    }
    

    // Add this helper function to determine current selection
    private func getCurrentStopsSelection() -> StopsOption {
        // Use exactStops if available, otherwise fallback to maxStops
        if filterViewModel.isExactStopsFilter, let exactStops = filterViewModel.exactStops {
            return StopsOption.fromExactStops(exactStops)
        } else {
            return StopsOption.fromMaxStops(filterViewModel.maxStops)
        }
    }
    
    private func clearStopsFilter() {
        print("\n🛑 ===== CLEARING STOPS FILTER =====")
        print("🗑️ Individual stops clear button pressed")
        
        // Reset all stops-related properties
        filterViewModel.maxStops = 3
        filterViewModel.exactStops = nil
        filterViewModel.isExactStopsFilter = false
        
        print("   Reset maxStops to: 3 (any stops)")
        print("   Reset exactStops to: nil")
        print("   Reset isExactStopsFilter to: false")
        print("🛑 ===== END CLEARING STOPS FILTER =====\n")
    }
    
    private func getLocalizedStopText(_ stopCount: Int) -> String {
        switch stopCount {
        case 0:
            return "non.stop".localized
        case 1:
            return "1.stop".localized
        case 2:
            return "count.stops".localized.replacingOccurrences(of: "{count}", with: "2")
        default:
            return "any".localized
        }
    }
    
    // ✅ UPDATED: Single timesContent with departure AND arrival time filters
    private var timesContent: some View {
        VStack(spacing: 32) {
            // ✅ UPDATED: Outbound leg with departure AND arrival time filters
            VStack(alignment: .leading, spacing: 16) {
                Text("\(originCode) - \(destinationCode)")
                    .font(CustomFont.font(.medium, weight: .semibold))
                    .foregroundColor(.gray)
                
                VStack(spacing: 20) {
                    // Departure Time Filter
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "airplane.departure")
                                .font(CustomFont.font(.small))
                                .foregroundColor(Color("Violet"))
                            Text("departure.time.from".localized.replacingOccurrences(of: "{origin}", with: originCode))
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        TimeRangeSlider(
                            range: $filterViewModel.departureTimeRange,
                            minTime: 0,
                            maxTime: 86400 // ✅ UPDATED: seconds
                        )
                    }
                    
                    // ✅ NEW: Arrival Time Filter
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "airplane.arrival")
                                .font(CustomFont.font(.small))
                                .foregroundColor(Color("Violet"))
                            Text("arrival.time.at".localized.replacingOccurrences(of: "{destination}", with: destinationCode))
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        TimeRangeSlider(
                            range: $filterViewModel.arrivalTimeRange,
                            minTime: 0,
                            maxTime: 86400 // ✅ UPDATED: seconds
                        )
                    }
                }
            }
            
            // ✅ UPDATED: Return leg with departure AND arrival time filters (only for round trip)
            if isRoundTrip {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(destinationCode) - \(originCode)")
                        .font(CustomFont.font(.medium, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 20) {
                        // Return Departure Time Filter
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "airplane.departure")
                                    .font(CustomFont.font(.small))
                                    .foregroundColor(Color("Violet"))
                                Text("departure.time.from".localized.replacingOccurrences(of: "{origin}", with: destinationCode))
                                    .font(CustomFont.font(.medium, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            
                            TimeRangeSlider(
                                range: $filterViewModel.returnDepartureTimeRange,
                                minTime: 0,
                                maxTime: 86400 // ✅ UPDATED: seconds
                            )
                        }
                        
                        // ✅ NEW: Return Arrival Time Filter
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "airplane.arrival")
                                    .font(CustomFont.font(.small))
                                    .foregroundColor(Color("Violet"))
                                Text("arrival.time.at".localized.replacingOccurrences(of: "{destination}", with: originCode))
                                    .font(CustomFont.font(.medium, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            
                            TimeRangeSlider(
                                range: $filterViewModel.returnArrivalTimeRange,
                                minTime: 0,
                                maxTime: 86400 // ✅ UPDATED: seconds
                            )
                        }
                    }
                }
            }
        }
    }
    
    // ✅ NEW: Stops Selection Row (Similar to Sort Selection Row)
    private func stopsSelectionRow(title: String, subtitle: String, option: StopsOption, isSelected: Bool) -> some View {
        Button(action: {
                // ✅ FIXED: Use exact stops filtering logic
                switch option {
                case .any:
                    filterViewModel.exactStops = nil
                    filterViewModel.isExactStopsFilter = false
                    filterViewModel.maxStops = 3 // Keep for backward compatibility
                case .direct:
                    filterViewModel.exactStops = 0
                    filterViewModel.isExactStopsFilter = true
                    filterViewModel.maxStops = 0
                case .oneStop:
                    filterViewModel.exactStops = 1
                    filterViewModel.isExactStopsFilter = true
                    filterViewModel.maxStops = 1
                case .twoStops:
                    filterViewModel.exactStops = 2
                    filterViewModel.isExactStopsFilter = true
                    filterViewModel.maxStops = 2
                }
                
                print("🛑 Stops filter selected: \(title)")
                print("   Exact stops value: \(filterViewModel.exactStops?.description ?? "nil")")
                print("   Is exact filter: \(filterViewModel.isExactStopsFilter)")
                print("   Max stops (fallback): \(filterViewModel.maxStops)")
            }) {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(CustomFont.font(.medium, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text(subtitle)
                            .font(CustomFont.font(.small))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Radio button indicator (same as sort and classes)
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
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Sort Content
    private var sortContent: some View {
        VStack(spacing: 0) {
            ForEach(SortOption.allCases, id: \.self) { option in
                sortSelectionRow(
                    title: option.localizedDisplayName,
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
                Text(option.localizedDisplayName)
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
    
    // MARK: - Airlines Content
    private var airlinesContent: some View {
        VStack(spacing: 0) {
            if filterViewModel.availableAirlines.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "airplane")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("no.airlines.available".localized)
                        .font(CustomFont.font(.medium))
                        .foregroundColor(.gray)
                    
                    Text("airlines.will.appear.here".localized)
                        .font(CustomFont.font(.small))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 40)
            } else {
                // Select All Option (always at top)
                airlineSelectionRow(
                    name: "select.all".localized,
                    code: "ALL",
                    price: nil,
                    logo: "",
                    isSelected: filterViewModel.areAllAirlinesSelected,
                    isSelectAll: true
                )
                
                // ✅ UPDATED: Use the improved ordering method
                ForEach(filterViewModel.getAirlinesForSheetDisplay(), id: \.code) { airline in
                    airlineSelectionRow(
                        name: airline.name,
                        code: airline.code,
                        price: airline.price,
                        logo: airline.logo,
                        isSelected: filterViewModel.isAirlineSelected(airline.code)
                    )
                }
            }
        }
        .onAppear {
            // ✅ UPDATED: Don't automatically reorder on appear
            // Just use the existing cached ordering from last Apply
            print("✈️ Airlines filter sheet opened")
            print("   Using ordering from last Apply button click")
            filterViewModel.debugPrintAirlineState()
        }
    }

    // MARK: - Updated Airline Selection Row (Remove auto-reordering)
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
                filterViewModel.toggleSelectAllAirlinesFilter()
            } else {
                filterViewModel.toggleAirlineFilter(code)
            }
            
            // ✅ REMOVED: Don't reorder immediately on selection
            // The ordering will only update when Apply is clicked
            
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
                
                // Price
                if let price = price, price > 0, !isSelectAll {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("₹\(Int(price))")
                            .font(CustomFont.font(.medium, weight: .semibold))
                            .foregroundColor(.black)
                        Text("from".localized)
                            .font(CustomFont.font(.tiny))
                            .foregroundColor(.gray)
                    }
                } else if !isSelectAll && (price == nil || price == 0) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("varies".localized)
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
                        Text("stopover.3".localized)
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
                        Text("flight.leg.3".localized)
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
                            Text("stopover.4".localized)
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
                            Text("flight.leg.4".localized)
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
            
            // Pricing Info Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("daily.local.taxes.fees".localized)
                        .font(CustomFont.font(.regular, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                   
                }
                
                if filterViewModel.hasAPIDataLoaded {
                    Text("price.range.info".localized
                        .replacingOccurrences(of: "{minPrice}", with: "₹\(Int(filterViewModel.apiMinPrice))")
                        .replacingOccurrences(of: "{maxPrice}", with: "₹\(Int(filterViewModel.apiMaxPrice))"))
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                } else {
                    Text("average.price.info".localized.replacingOccurrences(of: "{avgPrice}", with: "₹\(Int(averagePrice))"))
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            // ✅ FIXED: Price Slider with proper API range
            PriceRangeSlider(
                range: $filterViewModel.priceRange,
                minPrice: filterViewModel.hasAPIDataLoaded ? filterViewModel.apiMinPrice : minPrice,
                maxPrice: filterViewModel.hasAPIDataLoaded ? filterViewModel.apiMaxPrice : maxPrice
            ) { newRange in
                print("💰 User changed price range in FilterSheet:")
                print("   From: ₹\(filterViewModel.priceRange.lowerBound) - ₹\(filterViewModel.priceRange.upperBound)")
                print("   To: ₹\(newRange.lowerBound) - ₹\(newRange.upperBound)")
                filterViewModel.updatePriceRange(newRange: newRange)
            }
        }
        .onAppear {
            print("🎛️ Price filter sheet opened:")
            if filterViewModel.hasAPIDataLoaded {
                print("   API minPrice: ₹\(filterViewModel.apiMinPrice)")
                print("   API maxPrice: ₹\(filterViewModel.apiMaxPrice)")
                print("   Current filterViewModel.priceRange: ₹\(filterViewModel.priceRange.lowerBound) - ₹\(filterViewModel.priceRange.upperBound)")
                print("   User has modified: \(filterViewModel.userHasModifiedPrice)")
                print("   Filter is active: \(filterViewModel.isPriceFilterActive())")
            } else {
                print("   ⚠️ No API data loaded - using fallback prices")
            }
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
        case .sort, .airlines, .classes, .stops: // ✅ Stops uses single apply button
            return false
        }
    }
    
    private var bottomButtonsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                SecondaryButton(
                    title: "clear".localized,
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
                    title: "apply".localized,
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
    
    private func clearFilters() {
        switch filterType {
        case .stops:                    // ✅ ADD: Stops clear case
            clearStopsFilter()
        case .times:
            filterViewModel.departureTimeRange = 0...86400
            filterViewModel.arrivalTimeRange = 0...86400
            filterViewModel.returnDepartureTimeRange = 0...86400
            filterViewModel.returnArrivalTimeRange = 0...86400
        case .duration:
            filterViewModel.maxDuration = 1440
        case .price:
            filterViewModel.resetPriceFilter()
        default:
            break
        }
    }
    
    // MARK: - TimeRangeSlider Component
    struct TimeRangeSlider: View {
        @Binding var range: ClosedRange<Double>
        let minTime: Double
        let maxTime: Double

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

                        // Active track
                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .fill(Color("Violet"))
                            .frame(
                                width: CGFloat((range.upperBound - range.lowerBound) / (maxTime - minTime)) * width,
                                height: trackHeight
                            )
                            .offset(x: CGFloat((range.lowerBound - minTime) / (maxTime - minTime)) * width)

                        // Lower thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: thumbSize, height: thumbSize)
                            .overlay(
                                Circle()
                                    .stroke(Color("Violet"), lineWidth: 3)
                            )
                            .offset(x: CGFloat((range.lowerBound - minTime) / (maxTime - minTime)) * width - thumbSize / 50)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let location = max(0, min(Double(value.location.x), width))
                                        let newValue = minTime + (location / width) * (maxTime - minTime)
                                        let clampedValue = max(minTime, min(range.upperBound, newValue))
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
                            .offset(x: CGFloat((range.upperBound - minTime) / (maxTime - minTime)) * width - thumbSize)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let location = max(0, min(Double(value.location.x), width))
                                        let newValue = minTime + (location / width) * (maxTime - minTime)
                                        let clampedValue = max(range.lowerBound, min(maxTime, newValue))
                                        range = range.lowerBound...clampedValue
                                    }
                            )
                    }
                }
                .frame(height: 28)

                // Time labels
                HStack {
                    Text(formatTime(range.lowerBound))
                        .font(CustomFont.font(.small))
                        .foregroundColor(.gray)

                    Spacer()

                    Text(formatTime(range.upperBound))
                        .font(CustomFont.font(.small))
                        .foregroundColor(.gray)
                }
            }
        }

        private func formatTime(_ minutes: Double) -> String {
            // ✅ UPDATED: Convert seconds to hours and minutes for display
            let totalSeconds = Int(minutes)
            let hours = totalSeconds / 3600
            let mins = (totalSeconds % 3600) / 60
            return String(format: "%02d:%02d", hours, mins)
        }
    }
    
    // MARK: - DurationRangeSlider Component
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
    
    // MARK: - PriceRangeSlider Component
    struct PriceRangeSlider: View {
        @Binding var range: ClosedRange<Double>
        let minPrice: Double
        let maxPrice: Double
        let onPriceChanged: ((ClosedRange<Double>) -> Void)?
        
        init(
            range: Binding<ClosedRange<Double>>,
            minPrice: Double,
            maxPrice: Double,
            onPriceChanged: ((ClosedRange<Double>) -> Void)? = nil
        ) {
            self._range = range
            self.minPrice = minPrice
            self.maxPrice = maxPrice
            self.onPriceChanged = onPriceChanged
        }

        var body: some View {
            VStack(spacing: 12) {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let trackHeight: CGFloat = 20
                    let thumbSize: CGFloat = 16

                    ZStack(alignment: .leading) {
                        // Background track - EXACTLY like DurationRangeSlider
                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: trackHeight)

                        // Selected range (active track) - EXACTLY like DurationRangeSlider
                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .fill(Color("Violet"))
                            .frame(
                                width: CGFloat((range.upperBound - range.lowerBound) / (maxPrice - minPrice)) * width,
                                height: trackHeight
                            )
                            .offset(x: CGFloat((range.lowerBound - minPrice) / (maxPrice - minPrice)) * width)

                        // Lower thumb - EXACTLY like DurationRangeSlider
                        Circle()
                            .fill(Color.white)
                            .frame(width: thumbSize, height: thumbSize)
                            .overlay(
                                Circle()
                                    .stroke(Color("Violet"), lineWidth: 3)
                            )
                            .offset(x: CGFloat((range.lowerBound - minPrice) / (maxPrice - minPrice)) * width - thumbSize / 50)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let location = max(0, min(Double(value.location.x), width))
                                        let newValue = minPrice + (location / width) * (maxPrice - minPrice)
                                        let clampedValue = max(minPrice, min(range.upperBound, newValue))
                                        range = clampedValue...range.upperBound
                                    }
                                    .onEnded { _ in
                                        onPriceChanged?(range)
                                    }
                            )

                        // Upper thumb - EXACTLY like DurationRangeSlider
                        Circle()
                            .fill(Color.white)
                            .frame(width: thumbSize, height: thumbSize)
                            .overlay(
                                Circle()
                                    .stroke(Color("Violet"), lineWidth: 3)
                            )
                            .offset(x: CGFloat((range.upperBound - minPrice) / (maxPrice - minPrice)) * width - thumbSize )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let location = max(0, min(Double(value.location.x), width))
                                        let newValue = minPrice + (location / width) * (maxPrice - minPrice)
                                        let clampedValue = max(range.lowerBound, min(maxPrice, newValue))
                                        range = range.lowerBound...clampedValue
                                    }
                                    .onEnded { _ in
                                        onPriceChanged?(range)
                                    }
                            )
                    }
                }
                .frame(height: 28)

                // Price labels - Same format as DurationRangeSlider
                HStack {
                    Text("₹\(formatPrice(range.lowerBound))")
                        .font(CustomFont.font(.small))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("₹\(formatPrice(range.upperBound))")
                        .font(CustomFont.font(.small))
                        .foregroundColor(.gray)
                }
            }
        }

        // Format price like duration formatting
        private func formatPrice(_ price: Double) -> String {
            return "\(Int(price))"
        }
    }

}

// MARK: - Preview
#Preview {
    UnifiedFilterSheet(
        isPresented: .constant(true),
        filterType: .times, // ✅ Testing times filter
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
