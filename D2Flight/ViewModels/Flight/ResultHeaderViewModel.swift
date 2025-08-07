import SwiftUI

// MARK: - ResultHeader ViewModel
class ResultHeaderViewModel: ObservableObject {
    @Published var filterViewModel = FilterViewModel()
    @Published var pollResponseData: PollResponse? = nil
    
    // Sheet presentation states
    @Published var showUnifiedFilterSheet = false
    @Published var selectedFilterType: FilterType = .sort
    
    func updatePollData(_ pollResponse: PollResponse) {
        self.pollResponseData = pollResponse
        
        // ✅ Create airline options with real data including minimum prices
        let airlineOptions = createAirlineOptionsFromPollData(pollResponse)
        filterViewModel.availableAirlines = airlineOptions
        
        // ✅ CRITICAL FIX: Update price range and store original API values
        let minPrice = pollResponse.min_price
        let maxPrice = pollResponse.max_price
        
        // Update the FilterViewModel with API price range
        filterViewModel.updatePriceRangeFromAPI(minPrice: minPrice, maxPrice: maxPrice)
        
        print("✅ Updated ResultHeader with API data:")
        print("   Airlines: \(pollResponse.airlines.count)")
        print("   Airline Options with Prices: \(airlineOptions.count)")
        for option in airlineOptions {
            print("     \(option.name) (\(option.code)): ₹\(option.price)")
        }
        print("   API Price Range: ₹\(minPrice) - ₹\(maxPrice)")
        print("   Current Filter Price Range: ₹\(filterViewModel.priceRange.lowerBound) - ₹\(filterViewModel.priceRange.upperBound)")
        print("   Duration Range: \(pollResponse.min_duration) - \(pollResponse.max_duration) minutes")
    }
    
    // ✅ NEW: Create airline options with real minimum prices from flight results
    private func createAirlineOptionsFromPollData(_ pollResponse: PollResponse) -> [AirlineOption] {
            var airlineOptions: [AirlineOption] = []
            
            // Create a dictionary to track minimum price for each airline
            var airlineMinPrices: [String: Double] = [:]
            
            // ✅ CRITICAL FIX: Only calculate prices if there are actual flight results
            if !pollResponse.results.isEmpty {
                // Go through all flight results to find minimum price for each airline
                for flightResult in pollResponse.results {
                    for leg in flightResult.legs {
                        for segment in leg.segments {
                            let airlineCode = segment.airlineIata
                            let flightMinPrice = flightResult.min_price
                            
                            // Update minimum price for this airline
                            if let existingPrice = airlineMinPrices[airlineCode] {
                                airlineMinPrices[airlineCode] = min(existingPrice, flightMinPrice)
                            } else {
                                airlineMinPrices[airlineCode] = flightMinPrice
                            }
                        }
                    }
                }
            }
            
            // Create AirlineOption objects with real data
            for airline in pollResponse.airlines {
                // ✅ FIXED: Use actual minimum price if available, otherwise use a reasonable default
                let minPrice = airlineMinPrices[airline.airlineIata] ?? 0
                
                let airlineOption = AirlineOption(
                    code: airline.airlineIata,
                    name: airline.airlineName,
                    logo: airline.airlineLogo,
                    price: minPrice
                )
                
                airlineOptions.append(airlineOption)
            }
            
            // Sort by price (cheapest first) but only if we have real prices
            if !airlineMinPrices.isEmpty {
                return airlineOptions.sorted { $0.price < $1.price }
            } else {
                // If no flight results, sort alphabetically by name
                return airlineOptions.sorted { $0.name < $1.name }
            }
        }
    
    func calculateAveragePrice() -> Double {
        guard let pollData = pollResponseData else { return 500 }
        return (pollData.min_price + pollData.max_price) / 2
    }
    
    func applyFilters(onFiltersChanged: @escaping (PollRequest) -> Void) {
        let pollRequest = filterViewModel.buildPollRequest()
        onFiltersChanged(pollRequest)
        
        print("🔧 Filters applied:")
        print("   Sort: \(filterViewModel.selectedSortOption.displayName)")
        print("   Max Stops: \(filterViewModel.maxStops)")
        print("   Selected Airlines: \(filterViewModel.selectedAirlines.count)")
        print("   Has Any Filters: \(pollRequest.hasFilters())")
    }
}

// MARK: - Updated ResultHeader View
struct ResultHeaderView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var headerViewModel: ResultHeaderViewModel
    
    let originCode: String
    let destinationCode: String
    let isRoundTrip: Bool
    let travelDate: String
    let travelerInfo: String
    let onFiltersChanged: (PollRequest) -> Void
    
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
                        headerViewModel.selectedFilterType = .sort
                        headerViewModel.showUnifiedFilterSheet = true
                    }) {
                        HStack {
                            Image("SortIcon")
                            Text("Sort: \(headerViewModel.filterViewModel.selectedSortOption.displayName)")
                        }
                        .font(CustomFont.font(.small, weight: .semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(headerViewModel.filterViewModel.selectedSortOption != .best ? Color("Violet") : Color.gray.opacity(0.1))
                        .foregroundColor(headerViewModel.filterViewModel.selectedSortOption != .best ? .white : .gray)
                        .cornerRadius(20)
                    }
                    
                    // Other filter buttons...
                    FilterButton(
                        title: "Stops",
                        isSelected: headerViewModel.filterViewModel.maxStops < 3,
                        action: {
                            switch headerViewModel.filterViewModel.maxStops {
                            case 3: headerViewModel.filterViewModel.maxStops = 0
                            case 0: headerViewModel.filterViewModel.maxStops = 1
                            case 1: headerViewModel.filterViewModel.maxStops = 2
                            case 2: headerViewModel.filterViewModel.maxStops = 3
                            default: headerViewModel.filterViewModel.maxStops = 3
                            }
                            headerViewModel.applyFilters(onFiltersChanged: onFiltersChanged)
                        }
                    )
                    
                    FilterButton(
                        title: "Time",
                        isSelected: headerViewModel.filterViewModel.departureTimeRange != 0...1440 ||
                                   (isRoundTrip && headerViewModel.filterViewModel.returnTimeRange != 0...1440),
                        action: {
                            headerViewModel.selectedFilterType = .times
                            headerViewModel.showUnifiedFilterSheet = true
                        }
                    )
                    
                    FilterButton(
                        title: "Airlines",
                        isSelected: !headerViewModel.filterViewModel.selectedAirlines.isEmpty,
                        action: {
                            headerViewModel.selectedFilterType = .airlines
                            headerViewModel.showUnifiedFilterSheet = true
                        }
                    )
                    
                    FilterButton(
                        title: "Duration",
                        isSelected: headerViewModel.filterViewModel.maxDuration < 1440,
                        action: {
                            headerViewModel.selectedFilterType = .duration
                            headerViewModel.showUnifiedFilterSheet = true
                        }
                    )
                    
                    FilterButton(
                        title: "Price",
                        isSelected: headerViewModel.filterViewModel.priceRange.lowerBound > (headerViewModel.pollResponseData?.min_price ?? 0) ||
                                   headerViewModel.filterViewModel.priceRange.upperBound < (headerViewModel.pollResponseData?.max_price ?? 10000),
                        action: {
                            headerViewModel.selectedFilterType = .price
                            headerViewModel.showUnifiedFilterSheet = true
                        }
                    )
                    
                    FilterButton(
                        title: "Classes",
                        isSelected: headerViewModel.filterViewModel.selectedClass != .economy,
                        action: {
                            headerViewModel.selectedFilterType = .classes
                            headerViewModel.showUnifiedFilterSheet = true
                        }
                    )
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            headerViewModel.filterViewModel.isRoundTrip = isRoundTrip
        }
        .sheet(isPresented: $headerViewModel.showUnifiedFilterSheet) {
            UnifiedFilterSheet(
                isPresented: $headerViewModel.showUnifiedFilterSheet,
                filterType: headerViewModel.selectedFilterType,
                filterViewModel: headerViewModel.filterViewModel,
                isRoundTrip: isRoundTrip,
                originCode: originCode,
                destinationCode: destinationCode,
                availableAirlines: headerViewModel.filterViewModel.availableAirlines,
                minPrice: headerViewModel.pollResponseData?.min_price ?? 0,
                maxPrice: headerViewModel.pollResponseData?.max_price ?? 10000,
                averagePrice: headerViewModel.calculateAveragePrice(),
                onApply: {
                    headerViewModel.applyFilters(onFiltersChanged: onFiltersChanged)
                }
            )
            .presentationDetents([.medium])
        }
    }
}
