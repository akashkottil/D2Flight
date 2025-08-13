import SwiftUI

struct ResultHeader: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var filterViewModel = FilterViewModel()
    
    // Sheet presentation states - now using single sheet with filter type
    @State private var showUnifiedFilterSheet = false
    @State private var selectedFilterType: FilterType = .sort
    
    // NEW: Edit search sheet state
    @State private var showEditSearchSheet = false
    
    // Dynamic trip and result data
    let originCode: String
    let destinationCode: String
    let isRoundTrip: Bool
    let travelDate: String
    let travelerInfo: String
    
    // NEW: Search parameters for editing
    @State private var editableIsOneWay: Bool
    @State private var editableOriginLocation: String
    @State private var editableDestinationLocation: String
    @State private var editableOriginIATACode: String
    @State private var editableDestinationIATACode: String
    @State private var editableSelectedDates: [Date]
    @State private var editableTravelersCount: String
    @State private var editableAdults: Int
    @State private var editableChildren: Int
    @State private var editableInfants: Int
    @State private var editableSelectedClass: TravelClass
    
    // Callback for applying filters
    var onFiltersChanged: (PollRequest) -> Void
    
    // NEW: Callback for search parameters update
    var onSearchUpdated: ((SearchParameters) -> Void)?
    
    init(
        originCode: String,
        destinationCode: String,
        isRoundTrip: Bool,
        travelDate: String,
        travelerInfo: String,
        onFiltersChanged: @escaping (PollRequest) -> Void,
        onSearchUpdated: ((SearchParameters) -> Void)? = nil,
        // NEW: Initial search parameters for editing
        initialSearchParams: SearchParameters? = nil
    ) {
        self.originCode = originCode
        self.destinationCode = destinationCode
        self.isRoundTrip = isRoundTrip
        self.travelDate = travelDate
        self.travelerInfo = travelerInfo
        self.onFiltersChanged = onFiltersChanged
        self.onSearchUpdated = onSearchUpdated
        
        // Initialize editable states with current or provided parameters
        if let params = initialSearchParams {
            self._editableIsOneWay = State(initialValue: !params.isRoundTrip)
            self._editableOriginLocation = State(initialValue: params.originName)
            self._editableDestinationLocation = State(initialValue: params.destinationName)
            self._editableOriginIATACode = State(initialValue: params.originCode)
            self._editableDestinationIATACode = State(initialValue: params.destinationCode)
            self._editableSelectedDates = State(initialValue: [params.departureDate] + (params.returnDate != nil ? [params.returnDate!] : []))
            self._editableTravelersCount = State(initialValue: params.formattedTravelerInfo)
            self._editableAdults = State(initialValue: params.adults)
            self._editableChildren = State(initialValue: params.children)
            self._editableInfants = State(initialValue: params.infants)
            self._editableSelectedClass = State(initialValue: params.selectedClass)
        } else {
            // Fallback to defaults
            self._editableIsOneWay = State(initialValue: !isRoundTrip)
            self._editableOriginLocation = State(initialValue: "")
            self._editableDestinationLocation = State(initialValue: "")
            self._editableOriginIATACode = State(initialValue: originCode)
            self._editableDestinationIATACode = State(initialValue: destinationCode)
            self._editableSelectedDates = State(initialValue: [Date()])
            self._editableTravelersCount = State(initialValue: travelerInfo)
            self._editableAdults = State(initialValue: 2)
            self._editableChildren = State(initialValue: 0)
            self._editableInfants = State(initialValue: 0)
            self._editableSelectedClass = State(initialValue: .economy)
        }
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
                
                // NEW: Edit button that opens the edit search sheet
                Button(action: {
                    showEditSearchSheet = true
                }) {
                    VStack(alignment: .trailing) {
                        Image("EditIcon")
                            .frame(width: 14, height: 14)
                        Text("Edit")
                            .font(CustomFont.font(.small))
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(.bottom, 16)
            
            // Filter Buttons (existing code remains the same)
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
        // Single Unified Sheet for filters
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
        // NEW: Top-to-bottom edit search sheet
        .topToBottomSheet(isPresented: $showEditSearchSheet) {
            EditSearchSheet(
                isPresented: $showEditSearchSheet,
                isOneWay: $editableIsOneWay,
                originLocation: $editableOriginLocation,
                destinationLocation: $editableDestinationLocation,
                originIATACode: $editableOriginIATACode,
                destinationIATACode: $editableDestinationIATACode,
                selectedDates: $editableSelectedDates,
                travelersCount: $editableTravelersCount,
                adults: $editableAdults,
                children: $editableChildren,
                infants: $editableInfants,
                selectedClass: $editableSelectedClass,
                onSearchUpdated: {
                    handleSearchUpdate()
                }
            )
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
    
    // NEW: Handle search parameter updates
    private func handleSearchUpdate() {
        // Create new search parameters from editable states
        let updatedSearchParams = SearchParameters(
            originCode: editableOriginIATACode,
            destinationCode: editableDestinationIATACode,
            originName: editableOriginLocation,
            destinationName: editableDestinationLocation,
            isRoundTrip: !editableIsOneWay,
            departureDate: editableSelectedDates.first ?? Date(),
            returnDate: editableSelectedDates.count > 1 ? editableSelectedDates[1] : nil,
            adults: editableAdults,
            children: editableChildren,
            infants: editableInfants,
            selectedClass: editableSelectedClass
        )
        
        print("🔄 Search parameters updated:")
        print("   Origin: \(editableOriginLocation) (\(editableOriginIATACode))")
        print("   Destination: \(editableDestinationLocation) (\(editableDestinationIATACode))")
        print("   Trip Type: \(editableIsOneWay ? "One Way" : "Round Trip")")
        print("   Travelers: \(editableAdults) adults, \(editableChildren) children, \(editableInfants) infants")
        print("   Class: \(editableSelectedClass.rawValue)")
        
        // Call the update callback
        onSearchUpdated?(updatedSearchParams)
    }
    
    // Method to update available airlines from poll response
    func updateAvailableAirlines(_ airlines: [Airline]) {
        filterViewModel.updateAvailableAirlines(airlines)
        print("✈️ Updated available airlines in ResultHeader: \(airlines.count) airlines")
    }
    
    // NEW: Method to update editable search parameters when needed
    func updateEditableSearchParameters(_ searchParams: SearchParameters) {
        editableIsOneWay = !searchParams.isRoundTrip
        editableOriginLocation = searchParams.originName
        editableDestinationLocation = searchParams.destinationName
        editableOriginIATACode = searchParams.originCode
        editableDestinationIATACode = searchParams.destinationCode
        editableSelectedDates = [searchParams.departureDate] + (searchParams.returnDate != nil ? [searchParams.returnDate!] : [])
        editableTravelersCount = searchParams.formattedTravelerInfo
        editableAdults = searchParams.adults
        editableChildren = searchParams.children
        editableInfants = searchParams.infants
        editableSelectedClass = searchParams.selectedClass
        
        print("✅ Updated editable search parameters in ResultHeader")
    }
}

// MARK: - Preview with Sample Data
#Preview {
    let sampleSearchParams = SearchParameters(
        originCode: "KCH",
        destinationCode: "LON",
        originName: "Kochi",
        destinationName: "London",
        isRoundTrip: true,
        departureDate: Date(),
        returnDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
        adults: 2,
        children: 0,
        infants: 0,
        selectedClass: .business
    )
    
    ResultHeader(
        originCode: "KCH",
        destinationCode: "LON",
        isRoundTrip: true,
        travelDate: "Wed 17 Oct - Mon 24 Oct",
        travelerInfo: "2 Travelers, Business",
        onFiltersChanged: { _ in
            print("Filter applied")
        },
        onSearchUpdated: { updatedParams in
            print("Search updated: \(updatedParams.originName) → \(updatedParams.destinationName)")
        },
        initialSearchParams: sampleSearchParams
    )
}
