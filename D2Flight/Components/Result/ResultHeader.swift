import SwiftUI

struct ResultHeader: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var filterViewModel: FilterViewModel
    
    // Sheet presentation states - now using single sheet with filter type
    @State private var showUnifiedFilterSheet = false
    @State private var selectedFilterType: FilterType = .sort
    
    // Dynamic trip and result data
    let originCode: String
    let destinationCode: String
    let isRoundTrip: Bool
    let travelDate: String
    let travelerInfo: String
    let searchParameters: SearchParameters
    
    // Callback for applying filters
    var onFiltersChanged: (PollRequest) -> Void
    
    // ✅ NEW: Callback for edit search completion
    var onEditSearchCompleted: (String, SearchParameters) -> Void
    
    // ✅ NEW: Callback for edit button tap
    var onEditButtonTapped: () -> Void
    
    // ✅ NEW: Callback for clear all filters
    var onClearAllFilters: () -> Void
    
    // ✅ UPDATED: Initialize with clear filters callback
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
        onClearAllFilters: @escaping () -> Void = {} // ✅ NEW: Default empty closure
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
                    dismiss() // Navigate back to previous screen
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

                // ✅ UPDATED: Edit button now triggers callback instead of top sheet
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
            
            // Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // ✅ NEW: Clear All Filters Button (shows only when filters are active)
                    if hasActiveFilters() {
                        Button(action: {
                            clearAllFilters()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(CustomFont.font(.small))
                                Text("Clear All")
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
                    Button(action: {
                        selectedFilterType = .sort
                        showUnifiedFilterSheet = true
                    }) {
                        HStack {
                            Image("SortIcon")
                            Text("Sort: \(filterViewModel.selectedSortOption.displayName)")
                        }
                        .font(CustomFont.font(.small, weight: .semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(filterViewModel.selectedSortOption != .best ? Color("Violet") : Color.gray.opacity(0.1))
                        .foregroundColor(filterViewModel.selectedSortOption != .best ? .white : .gray)
                        .cornerRadius(20)
                    }
                    
                    // ✅ NEW: Stops Filter Button
                    FilterButton(
                        title: getStopsFilterTitle(),
                        isSelected: filterViewModel.maxStops < 3,
                        action: {
                            selectedFilterType = .stops
                            showUnifiedFilterSheet = true
                        }
                    )
                    
                    // Time Filter
                    FilterButton(
                        title: "Time",
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
                        title: filterViewModel.getAirlineFilterDisplayText(),
                        isSelected: filterViewModel.selectedAirlinesCount > 0,
                        action: {
                            selectedFilterType = .airlines
                            showUnifiedFilterSheet = true
                        }
                    )
                    
                    // Duration Filter
                    FilterButton(
                        title: "Duration",
                        isSelected: filterViewModel.maxDuration < 1440,
                        action: {
                            selectedFilterType = .duration
                            showUnifiedFilterSheet = true
                        }
                    )
                    
                    // Price Filter
                    FilterButton(
                        title: "Price",
                        isSelected: filterViewModel.priceRange.lowerBound > 0 ||
                                   filterViewModel.priceRange.upperBound < 10000,
                        action: {
                            selectedFilterType = .price
                            showUnifiedFilterSheet = true
                        }
                    )
                    
                    // Classes Filter
                    FilterButton(
                        title: "Classes",
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
        .padding()
        .onAppear {
            filterViewModel.isRoundTrip = isRoundTrip
            print("🎛️ ResultHeader configured with:")
            print("   Route: \(originCode) to \(destinationCode)")
            print("   Trip Type: \(isRoundTrip ? "Round Trip" : "One Way")")
            print("   Date: \(travelDate)")
            print("   Travelers: \(travelerInfo)")
        }
        
        // Single Unified Filter Sheet (updated with stops)
        .sheet(isPresented: $showUnifiedFilterSheet) {
            UnifiedFilterSheet(
                isPresented: $showUnifiedFilterSheet,
                filterType: selectedFilterType,
                filterViewModel: filterViewModel,
                isRoundTrip: isRoundTrip,
                originCode: originCode,
                destinationCode: destinationCode,
                availableAirlines: filterViewModel.availableAirlines, // ✅ Pass actual airlines
                minPrice: 0,
                maxPrice: 10000,
                averagePrice: 500,
                onApply: applyFilters
            )
            .presentationDetents(getPresentationDetents())
        }
    }
    
    // ✅ NEW: Get dynamic stops filter title
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
    
    // ✅ NEW: Check if any filters are active
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
               filterViewModel.priceRange.lowerBound > 0 ||
               filterViewModel.priceRange.upperBound < 10000
    }
    
    // ✅ NEW: Clear all filters functionality
    private func clearAllFilters() {
        print("\n🗑️ ===== CLEAR ALL FILTERS =====")
        print("🔄 Clearing all filters and resetting to default state...")
        
        // Clear all filter values to proper defaults
        filterViewModel.selectedSortOption = .best
        filterViewModel.maxStops = 3 // Reset to "Any"
        filterViewModel.departureTimeRange = 0...86400 // ✅ FIXED: Use seconds
        filterViewModel.arrivalTimeRange = 0...86400 // ✅ FIXED: Use seconds
        filterViewModel.returnDepartureTimeRange = 0...86400 // ✅ FIXED: Use seconds
        filterViewModel.returnArrivalTimeRange = 0...86400 // ✅ FIXED: Use seconds
        filterViewModel.maxDuration = 1440
        filterViewModel.selectedAirlines.removeAll()
        filterViewModel.excludedAirlines.removeAll()
        filterViewModel.selectedClass = .economy
        filterViewModel.priceRange = 0...10000
        
        print("✅ All filters cleared to default values")
        print("🗑️ ===== END CLEAR ALL FILTERS =====\n")
        
        // Apply empty filters (this will fetch all results without filters)
        let emptyRequest = PollRequest() // Empty request = no filters
        onClearAllFilters() // Notify parent to handle clear
        onFiltersChanged(emptyRequest)
    }
    
    // Helper to determine presentation detent
    private func getPresentationDetents() -> Set<PresentationDetent> {
        return [.medium]
    }
    
    private func applyFilters() {
        let pollRequest = filterViewModel.buildPollRequest()
        onFiltersChanged(pollRequest)
        
        print("🔧 Filters applied:")
        print("   Sort: \(filterViewModel.selectedSortOption.displayName)")
        print("   Max Stops: \(filterViewModel.maxStops)")
        print("   Selected Airlines: \(filterViewModel.selectedAirlines.count)")
        print("   Duration Filter: \(filterViewModel.maxDuration < 1440 ? "Active" : "Inactive")")
        print("   Time Filter: \(filterViewModel.departureTimeRange != 0...1440 ? "Active" : "Inactive")")
        print("   Price Filter: \(filterViewModel.priceRange != 0...10000 ? "Active" : "Inactive")")
        print("   Has Any Filters: \(pollRequest.hasFilters())")
    }
    
    // Method to update available airlines from poll response
    func updateAvailableAirlines(_ pollResponse: PollResponse) {
        print("🔧 ResultHeader: Updating airlines from poll response")
        filterViewModel.updateAvailableAirlines(from: pollResponse)
        print("✅ ResultHeader: Airlines updated - \(filterViewModel.availableAirlines.count) available")
    }
}

