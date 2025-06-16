import SwiftUI

struct ResultHeader: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var filterViewModel = FilterViewModel()
    
    // Sheet presentation states
    @State private var showSortSheet = false
    @State private var showTimesSheet = false
    @State private var showClassesSheet = false
    @State private var showDurationSheet = false
    @State private var showAirlinesSheet = false
    @State private var showPriceSheet = false  // ✅ Added price sheet
    
    // Dynamic trip and result data - NO MORE DEFAULTS
    let originCode: String
    let destinationCode: String
    let isRoundTrip: Bool
    let travelDate: String
    let travelerInfo: String
    
    // Callback for applying filters
    var onFiltersChanged: (PollRequest) -> Void
    
    // Updated initializer without defaults - parameters are required
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
                    // Sort Button - ✅ Show active state when not "Best"
                    Button(action: {
                        showSortSheet = true
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
                    
                    // ✅ Stops Filter - Show active state
                    FilterButton(
                        title: "Stops",
                        isSelected: filterViewModel.maxStops < 3,
                        action: {
                            // Cycle through stop options: All stops (3) -> Non-stop (0) -> 1 stop (1) -> 2 stops (2) -> All stops (3)
                            switch filterViewModel.maxStops {
                            case 3: filterViewModel.maxStops = 0 // All -> Non-stop
                            case 0: filterViewModel.maxStops = 1 // Non-stop -> 1 stop
                            case 1: filterViewModel.maxStops = 2 // 1 stop -> 2 stops
                            case 2: filterViewModel.maxStops = 3 // 2 stops -> All
                            default: filterViewModel.maxStops = 3
                            }
                            applyFilters()
                        }
                    )
                    
                    // ✅ Time Filter - Show active state
                    FilterButton(
                        title: "Time",
                        isSelected: filterViewModel.departureTimeRange != 0...1440 ||
                                   (isRoundTrip && filterViewModel.returnTimeRange != 0...1440),
                        action: {
                            showTimesSheet = true
                        }
                    )
                    
                    // ✅ Airlines Filter - Show active state
                    FilterButton(
                        title: "Airlines",
                        isSelected: !filterViewModel.selectedAirlines.isEmpty,
                        action: {
                            showAirlinesSheet = true
                        }
                    )
                    
                    // ✅ Duration Filter - Show active state
                    FilterButton(
                        title: "Duration",
                        isSelected: filterViewModel.maxDuration < 1440,
                        action: {
                            showDurationSheet = true
                        }
                    )
                    
                    // ✅ Price Filter - Show active state
                    FilterButton(
                        title: "Price",
                        isSelected: filterViewModel.priceRange.lowerBound > 0 ||
                                   filterViewModel.priceRange.upperBound < 10000,
                        action: {
                            showPriceSheet = true
                        }
                    )
                    
                    // ✅ Classes Filter - Show active state
                    FilterButton(
                        title: "Classes",
                        isSelected: filterViewModel.selectedClass != .economy,
                        action: {
                            showClassesSheet = true
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
        // Bottom Sheets
        .sheet(isPresented: $showSortSheet) {
            SortSheet(
                isPresented: $showSortSheet,
                selectedSortOption: $filterViewModel.selectedSortOption,
                onApply: applyFilters
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showTimesSheet) {
            TimesFilterSheet(
                isPresented: $showTimesSheet,
                departureTimeRange: $filterViewModel.departureTimeRange,
                returnTimeRange: $filterViewModel.returnTimeRange,
                isRoundTrip: isRoundTrip,
                originCode: originCode,
                destinationCode: destinationCode,
                onApply: applyFilters
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showClassesSheet) {
            ClassesSheet(
                isPresented: $showClassesSheet,
                selectedClass: $filterViewModel.selectedClass,
                onApply: applyFilters
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showDurationSheet) {
            DurationFilterSheet(
                isPresented: $showDurationSheet,
                departureStopoverRange: $filterViewModel.departureStopoverRange,
                departureLegRange: $filterViewModel.departureLegRange,
                returnStopoverRange: $filterViewModel.returnStopoverRange,
                returnLegRange: $filterViewModel.returnLegRange,
                isRoundTrip: isRoundTrip,
                originCode: originCode,
                destinationCode: destinationCode,
                onApply: applyFilters
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showAirlinesSheet) {
            AirlinesFilterSheet(
                isPresented: $showAirlinesSheet,
                selectedAirlines: $filterViewModel.selectedAirlines,
                availableAirlines: filterViewModel.availableAirlines,
                onApply: applyFilters
            )
            .presentationDetents([.large])
        }
        // ✅ Added Price Filter Sheet
        .sheet(isPresented: $showPriceSheet) {
            PriceFilterSheet(
                isPresented: $showPriceSheet,
                priceRange: $filterViewModel.priceRange,
                minPrice: 0,
                maxPrice: 10000,
                averagePrice: 500, // You might want to calculate this from actual data
                onApply: applyFilters
            )
            .presentationDetents([.medium])
        }
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
    
    // ✅ Method to update available airlines from poll response
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
