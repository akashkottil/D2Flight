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
    
    // Trip and result data
    let originCode: String
    let destinationCode: String
    let isRoundTrip: Bool
    let travelDate: String
    let travelerInfo: String
    
    // Callback for applying filters
    var onFiltersChanged: (PollRequest) -> Void
    
    init(
        originCode: String = "KCH",
        destinationCode: String = "LON",
        isRoundTrip: Bool = false,
        travelDate: String = "Wed 17 Oct",
        travelerInfo: String = "1 Traveler, 1 Economy",
        onFiltersChanged: @escaping (PollRequest) -> Void = { _ in }
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
    }
    
    // Method to update available airlines from poll response
    func updateAvailableAirlines(_ airlines: [Airline]) {
        filterViewModel.updateAvailableAirlines(airlines)
    }
}

// Updated FilterButton with action support
//struct FilterButton: View {
//    let title: String
//    var isSelected: Bool = false
//    var action: (() -> Void)? = nil
//
//    var body: some View {
//        Button(action: {
//            action?()
//        }) {
//            Text(title)
//                .font(.system(size: 12, weight: .semibold))
//                .padding(.vertical, 8)
//                .padding(.horizontal, 16)
//                .background(isSelected ? Color("Violet") : Color.gray.opacity(0.1))
//                .foregroundColor(isSelected ? .white : .gray)
//                .cornerRadius(20)
//        }
//    }
//}

#Preview {
    ResultHeader(
        originCode: "KCH",
        destinationCode: "LON",
        isRoundTrip: false,
        travelDate: "Wed 17 Oct",
        travelerInfo: "1 Traveler, 1 Economy"
    ) { _ in }
}
