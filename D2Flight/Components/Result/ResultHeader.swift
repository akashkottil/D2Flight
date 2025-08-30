import SwiftUI

struct ResultHeader: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var filterViewModel: FilterViewModel
    
    // Sheet presentation states - now using single sheet with filter type
    @State var showUnifiedFilterSheet = false
    @State var selectedFilterType: FilterType = .sort
    
    // Dynamic trip and result data
    let originCode: String
    let destinationCode: String
    let isRoundTrip: Bool
    let travelDate: String
    let travelerInfo: String
    let searchParameters: SearchParameters
    
    // Callback for applying filters
    var onFiltersChanged: (PollRequest) -> Void
    
    // Callback for edit search completion
    var onEditSearchCompleted: (String, SearchParameters) -> Void
    
    // Callback for edit button tap
    var onEditButtonTapped: () -> Void
    
    // Callback for clear all filters
    var onClearAllFilters: () -> Void
    
    // ✅ FIXED: Store current API price data
    @State private var currentMinPrice: Double = 0
    @State private var currentMaxPrice: Double = 10000
    @State private var currentAveragePrice: Double = 500
    
    init(
        originCode: String,
        destinationCode: String,
        isRoundTrip: Bool,
        travelDate: String,
        travelerInfo: String,
        searchParameters: SearchParameters,
        filterViewModel: FilterViewModel,
        onFiltersChanged: @escaping (PollRequest) -> Void,
        onEditSearchCompleted: @escaping (String, SearchParameters) -> Void,
        onEditButtonTapped: @escaping () -> Void,
        onClearAllFilters: @escaping () -> Void = {}
    ) {
        self.originCode = originCode
        self.destinationCode = destinationCode
        self.isRoundTrip = isRoundTrip
        self.travelDate = travelDate
        self.travelerInfo = travelerInfo
        self.searchParameters = searchParameters
        self.filterViewModel = filterViewModel
        self.onFiltersChanged = onFiltersChanged
        self.onEditSearchCompleted = onEditSearchCompleted
        self.onEditButtonTapped = onEditButtonTapped
        self.onClearAllFilters = onClearAllFilters
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image("BlackArrow")
                        .padding(.trailing, 10)
                }
                
                VStack(alignment: .leading) {
                    Text("\(originCode) to \(destinationCode)")
                        .font(CustomFont.font(.regular))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    Text("\(travelDate), \(travelerInfo)")
                        .font(CustomFont.font(.small))
                        .fontWeight(.light)
                        .foregroundColor(.gray)
                }
                Spacer()

                Button(action: {
                    onEditButtonTapped()
                }) {
                    VStack(alignment: .trailing) {
                        Image("EditIcon")
                            .frame(width: 14, height: 14)
                        Text("edit".localized)
                            .font(CustomFont.font(.small))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.bottom, 16)
            .padding(.horizontal)
            
            // Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Clear All Filters Button (shows only when filters are active)
                    if hasActiveFilters() {
                        Button(action: {
                            clearAllFilters()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(CustomFont.font(.small))
                                Text("clear.all".localized)
                            }
                            .font(CustomFont.font(.small, weight: .semibold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(20)
                        }
                    }
                    
                    // Sort Button
                    FilterButton(
                        title: getSortFilterTitle(),
                        isSelected: filterViewModel.selectedSortOption != .best,
                        action: {
                            selectedFilterType = .sort
                            showUnifiedFilterSheet = true
                        }
                    )

                    // Stops Filter Button
                    FilterButton(
                        title: getLocalizedStopsFilterTitle(),
                        isSelected: filterViewModel.maxStops < 3,
                        action: {
                            selectedFilterType = .stops
                            showUnifiedFilterSheet = true
                        }
                    )

                    // Time Filter
                    FilterButton(
                        title: "times".localized,
                        isSelected: filterViewModel.departureTimeRange != 0...86400 ||
                                   filterViewModel.arrivalTimeRange != 0...86400 ||
                                   (isRoundTrip && filterViewModel.returnDepartureTimeRange != 0...86400) ||
                                   (isRoundTrip && filterViewModel.returnArrivalTimeRange != 0...86400),
                        action: {
                            selectedFilterType = .times
                            showUnifiedFilterSheet = true
                        }
                    )

                    // Airlines Filter
                    FilterButton(
                        title: filterViewModel.getLocalizedAirlineFilterDisplayText(),
                        isSelected: filterViewModel.selectedAirlinesCount > 0,
                        action: {
                            selectedFilterType = .airlines
                            showUnifiedFilterSheet = true
                        }
                    )

                    // Price Filter
                    FilterButton(
                        title: filterViewModel.getLocalizedPriceFilterDisplayText(),
                        isSelected: filterViewModel.isPriceFilterActive(),
                        action: {
                            selectedFilterType = .price
                            showUnifiedFilterSheet = true
                        }
                    )

                    // Classes Filter
                    FilterButton(
                        title: "classes".localized,
                        isSelected: filterViewModel.selectedClass != .economy,
                        action: {
                            selectedFilterType = .classes
                            showUnifiedFilterSheet = true
                        }
                    )
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical)
        .onAppear {
            filterViewModel.isRoundTrip = isRoundTrip
            print("🎛️ ResultHeader configured with:")
            print("   Route: \(originCode) to \(destinationCode)")
            print("   Trip Type: \(isRoundTrip ? "Round Trip" : "One Way")")
            print("   Date: \(travelDate)")
            print("   Travelers: \(travelerInfo)")
        }
        
        // Single Unified Filter Sheet
        .sheet(isPresented: $showUnifiedFilterSheet) {
            UnifiedFilterSheet(
                isPresented: $showUnifiedFilterSheet,
                filterType: selectedFilterType,
                filterViewModel: filterViewModel,
                isRoundTrip: isRoundTrip,
                originCode: originCode,
                destinationCode: destinationCode,
                availableAirlines: filterViewModel.availableAirlines,
                // ✅ CRITICAL: Use API price data if available, fallback to provided values
                minPrice: filterViewModel.hasAPIDataLoaded ? filterViewModel.apiMinPrice : currentMinPrice,
                maxPrice: filterViewModel.hasAPIDataLoaded ? filterViewModel.apiMaxPrice : currentMaxPrice,
                averagePrice: filterViewModel.hasAPIDataLoaded ?
                    (filterViewModel.apiMinPrice + filterViewModel.apiMaxPrice) / 2 : currentAveragePrice,
                onApply: applyFilters
            )
            .presentationDetents(getPresentationDetents())
        }

    }
    
    func updateAvailableAirlines(_ pollResponse: PollResponse) {
        print("🔧 ResultHeader: Updating airlines and price data from poll response")
        
        // Update airlines in FilterViewModel
        filterViewModel.updateAvailableAirlines(from: pollResponse)
        
        // ✅ CRITICAL: Update price data in FilterViewModel with API values
        filterViewModel.updatePriceRangeFromAPI(
            minPrice: pollResponse.min_price,
            maxPrice: pollResponse.max_price
        )
        
        print("✅ ResultHeader: Updated both airlines and price data:")
        print("   Airlines: \(filterViewModel.availableAirlines.count)")
        print("   API Price Range: ₹\(pollResponse.min_price) - ₹\(pollResponse.max_price)")
        print("   FilterViewModel hasAPIDataLoaded: \(filterViewModel.hasAPIDataLoaded)")
        print("   Current price range: ₹\(filterViewModel.priceRange.lowerBound) - ₹\(filterViewModel.priceRange.upperBound)")
    }
    
    private func getStopsFilterTitle() -> String {
        switch filterViewModel.maxStops {
        case 0:
            return "Direct"
        case 1:
            return "1 Stop"
        case 2:
            return "2 Stops"
        default:
            return "Stops"
        }
    }
    
    private func hasActiveFilters() -> Bool {
        return filterViewModel.selectedSortOption != .best ||
               filterViewModel.maxStops < 3 ||
               filterViewModel.departureTimeRange != 0...86400 ||
               filterViewModel.arrivalTimeRange != 0...86400 ||
               (isRoundTrip && filterViewModel.returnDepartureTimeRange != 0...86400) ||
               (isRoundTrip && filterViewModel.returnArrivalTimeRange != 0...86400) ||
               filterViewModel.maxDuration < 1440 ||
               !filterViewModel.selectedAirlines.isEmpty ||
               filterViewModel.selectedClass != .economy ||
               filterViewModel.isPriceFilterActive() // ✅ Include price filter
    }
    
     func clearAllFilters() {
        print("\n🗑️ ===== CLEAR ALL FILTERS =====")
        print("🔄 Clearing all filters and resetting to default state...")
        
        // Clear all filter values to proper defaults
        filterViewModel.selectedSortOption = .best
        filterViewModel.maxStops = 3
        filterViewModel.departureTimeRange = 0...86400
        filterViewModel.arrivalTimeRange = 0...86400
        filterViewModel.returnDepartureTimeRange = 0...86400
        filterViewModel.returnArrivalTimeRange = 0...86400
        filterViewModel.maxDuration = 1440
        filterViewModel.selectedAirlines.removeAll()
        filterViewModel.excludedAirlines.removeAll()
        filterViewModel.selectedClass = .economy
        
        // ✅ CRITICAL: Reset price filter to API values (not hardcoded values)
        filterViewModel.resetPriceFilter()
        
        print("✅ All filters cleared to default values")
        print("🗑️ ===== END CLEAR ALL FILTERS =====\n")
        
        // Apply empty filters
        let emptyRequest = PollRequest()
        onClearAllFilters()
        onFiltersChanged(emptyRequest)
    }
    
    private func getPresentationDetents() -> Set<PresentationDetent> {
        return [.medium]
    }
    
    private func applyFilters() {
        if selectedFilterType == .airlines || !filterViewModel.selectedAirlines.isEmpty {
                filterViewModel.applyAirlineFiltersAndUpdateOrdering()
                print("✅ Applied airline filter ordering updates")
            }
        
        let pollRequest = filterViewModel.buildPollRequest()
        onFiltersChanged(pollRequest)
        
        print("🔧 Filters applied:")
        print("   Sort: \(filterViewModel.selectedSortOption.displayName)")
        print("   Max Stops: \(filterViewModel.maxStops)")
        print("   Selected Airlines: \(filterViewModel.selectedAirlines.count)")
        print("   Duration Filter: \(filterViewModel.maxDuration < 1440 ? "Active" : "Inactive")")
        print("   Time Filter: \(filterViewModel.departureTimeRange != 0...86400 ? "Active" : "Inactive")")
        print("   Price Filter: \(filterViewModel.isPriceFilterActive() ? "Active" : "Inactive")")
        if filterViewModel.isPriceFilterActive() {
            print("   Price Range: ₹\(filterViewModel.priceRange.lowerBound) - ₹\(filterViewModel.priceRange.upperBound)")
        }
        print("   Has Any Filters: \(pollRequest.hasFilters())")
    }
    
    private func getLocalizedStopsFilterTitle() -> String {
        switch filterViewModel.maxStops {
        case 0:
            return "direct".localized
        case 1:
            return "1.stop".localized
        case 2:
            return "count.stops".localized.replacingOccurrences(of: "{count}", with: "2")
        default:
            return "stops".localized
        }
    }
    
    private func getSortFilterTitle() -> String {
        return "sort".localized + ": \(filterViewModel.selectedSortOption.localizedDisplayName)"
    }
    
}
