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
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    Text("\(travelDate), \(travelerInfo)")
                        .font(.system(size: 12))
                        .fontWeight(.light)
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Image("EditIcon")
                        .frame(width: 14, height: 14)
                    Text("Edit")
                        .font(.system(size: 12))
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
                        showSortSheet = true
                    }) {
                        HStack {
                            Image("SortIcon")
                            Text("Sort: \(filterViewModel.selectedSortOption.displayName)")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.gray)
                        .cornerRadius(20)
                    }
                    
                    // Filter Buttons with active state
                    FilterButton(
                        title: "Stops",
                        isSelected: filterViewModel.maxStops < 3,
                        action: {
                            // For now, just toggle max stops between 0 and 3
                            filterViewModel.maxStops = filterViewModel.maxStops == 3 ? 0 : 3
                            applyFilters()
                        }
                    )
                    
                    
                    FilterButton(
                        title: "Time",
                        isSelected: filterViewModel.departureTimeRange != 0...1440 || filterViewModel.returnTimeRange != 0...1440,
                        action: {
                            showTimesSheet = true
                        }
                    )
                    
                    FilterButton(
                        title: "Airlines",
                        isSelected: !filterViewModel.selectedAirlines.isEmpty,
                        action: {
                            showAirlinesSheet = true
                        }
                    )
                    
                    FilterButton(
                        title: "Duration",
                        isSelected: filterViewModel.maxDuration < 1440,
                        action: {
                            showDurationSheet = true
                        }
                    )
                    
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
    }
    
    private func applyFilters() {
        let pollRequest = filterViewModel.buildPollRequest()
        onFiltersChanged(pollRequest)
        
        print("🔧 Filters applied:")
        print("   Sort: \(filterViewModel.selectedSortOption.displayName)")
        print("   Max Stops: \(filterViewModel.maxStops)")
        print("   Selected Airlines: \(filterViewModel.selectedAirlines.count)")
        print("   Duration Filter: \(filterViewModel.maxDuration < 1440 ? "Active" : "Inactive")")
    }
    
    // Method to update available airlines from poll response
    func updateAvailableAirlines(_ airlines: [Airline]) {
        filterViewModel.updateAvailableAirlines(airlines)
        print("✈️ Updated available airlines: \(airlines.count) airlines")
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
