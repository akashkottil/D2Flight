import SwiftUI

struct ResultHeader: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var filterViewModel = FilterViewModel()
    
    // Sheet presentation states - now using single sheet with filter type
    @State private var showUnifiedFilterSheet = false
    @State private var selectedFilterType: FilterType = .sort
    
    // Dynamic trip and result data
    let originCode: String
    let destinationCode: String
    let isRoundTrip: Bool
    let travelDate: String
    let travelerInfo: String
    
    // Callback for applying filters
    var onFiltersChanged: (PollRequest) -> Void
    
    init(
        originCode: String,
        destinationCode: String,
        isRoundTrip: Bool,
        travelDate: String,
        travelerInfo: String,
        onFiltersChanged: @escaping (PollRequest) -> Void
    ) {
        self.originCode = originCode
        self.destinationCode = destinationCode
        self.isRoundTrip = isRoundTrip
        self.travelDate = travelDate
        self.travelerInfo = travelerInfo
        self.onFiltersChanged = onFiltersChanged
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section with dynamic content
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
                VStack(alignment: .trailing) {
                    Image("EditIcon")
                        .frame(width: 14, height: 14)
                    Text("Edit")
                        .font(CustomFont.font(.small))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                }
            }
            .padding(.bottom, 16)
            
            // Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
                    
                    // Stops Filter
                    FilterButton(
                        title: "Stops",
                        isSelected: filterViewModel.maxStops < 3,
                        action: {
                            // Cycle through stop options
                            switch filterViewModel.maxStops {
                            case 3: filterViewModel.maxStops = 0
                            case 0: filterViewModel.maxStops = 1
                            case 1: filterViewModel.maxStops = 2
                            case 2: filterViewModel.maxStops = 3
                            default: filterViewModel.maxStops = 3
                            }
                            applyFilters()
                        }
                    )
                    
                    // Time Filter
                    FilterButton(
                        title: "Time",
                        isSelected: filterViewModel.departureTimeRange != 0...1440 ||
                                   (isRoundTrip && filterViewModel.returnTimeRange != 0...1440),
                        action: {
                            selectedFilterType = .times
                            showUnifiedFilterSheet = true
                        }
                    )
                    
                    // Airlines Filter
                    FilterButton(
                        title: "Airlines",
                        isSelected: !filterViewModel.selectedAirlines.isEmpty,
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
        .onAppear {
            filterViewModel.isRoundTrip = isRoundTrip
            print("🎛️ ResultHeader configured with:")
            print("   Route: \(originCode) to \(destinationCode)")
            print("   Trip Type: \(isRoundTrip ? "Round Trip" : "One Way")")
            print("   Date: \(travelDate)")
            print("   Travelers: \(travelerInfo)")
        }
        // Single Unified Sheet
        .sheet(isPresented: $showUnifiedFilterSheet) {
            UnifiedFilterSheet(
                isPresented: $showUnifiedFilterSheet,
                filterType: selectedFilterType,
                filterViewModel: filterViewModel,
                isRoundTrip: isRoundTrip,
                originCode: originCode,
                destinationCode: destinationCode,
                availableAirlines: filterViewModel.availableAirlines,
                minPrice: 0,
                maxPrice: 10000,
                averagePrice: 500,
                onApply: applyFilters
            )
            .presentationDetents(getPresentationDetents())
        }
    }
    
    // Helper to determine presentation detent - all sheets open to half screen
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
    func updateAvailableAirlines(_ airlines: [Airline]) {
        filterViewModel.updateAvailableAirlines(airlines)
        print("✈️ Updated available airlines in ResultHeader: \(airlines.count) airlines")
    }
}

// MARK: - Preview with Sample Data
#Preview {
    ResultHeader(
        originCode: "KCH",
        destinationCode: "LON",
        isRoundTrip: true,
        travelDate: "Wed 17 Oct - Mon 24 Oct",
        travelerInfo: "2 Travelers, Business"
    ) { _ in
        print("Filter applied")
    }
}
