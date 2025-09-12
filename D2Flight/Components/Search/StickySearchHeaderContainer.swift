//
//  StickySearchHeaderContainer.swift
//  D2Flight
//
//  Created by Akash Kottil on 12/09/25.
//


import SwiftUI

struct StickySearchHeaderContainer: View {
    // from demo
    let progress: CGFloat            // 0 → expanded, 1 → collapsed
    let expandedHeight: CGFloat
    let collapsedHeight: CGFloat
    let namespace: Namespace.ID

    // threshold to flip states
    private let threshold: CGFloat = 0.6

    @State private var isCollapsed: Bool = false

    // all bindings you already use in SearchCard
    @Binding var isOneWay: Bool
    @Binding var originLocation: String
    @Binding var destinationLocation: String
    @Binding var originIATACode: String
    @Binding var destinationIATACode: String
    @Binding var selectedDates: [Date]
    @Binding var travelersCount: String
    @Binding var showPassengerSheet: Bool
    @Binding var adults: Int
    @Binding var children: Int
    @Binding var infants: Int
    @Binding var selectedClass: TravelClass
    @Binding var navigateToLocationSelection: Bool
    @Binding var navigateToDateSelection: Bool

    let onSearchFlights: () -> Void

    var body: some View {
        let headerHeight = lerp(expandedHeight, collapsedHeight, progress)

        ZStack {
            // subtle stickiness
//            VisualEffectBlur().opacity(progress)

            // we can also lerp any shared metrics if needed (e.g., internal paddings)
            Group {
                if isCollapsed {
                    // COLLAPSED — your summary bar
                    CollapsedSearch(
                        originCode: originIATACode.isEmpty ? "NYC" : originIATACode,
                        destinationCode: destinationIATACode.isEmpty ? "LHR" : destinationIATACode,
                        travelDate: formatTravelDate(),
                        travelerInfo: travelersCount,
                        animationNamespace: namespace,
                        onEdit: { withAnimation(.spring(response: 0.35, dampingFraction: 1.85)) { isCollapsed = false } },
                        onSearch: onSearchFlights
                    )
                } else {
                    // EXPANDED — your full card
                    SearchCard(
                        isOneWay: $isOneWay,
                        originLocation: $originLocation,
                        destinationLocation: $destinationLocation,
                        originIATACode: $originIATACode,
                        destinationIATACode: $destinationIATACode,
                        selectedDates: $selectedDates,
                        travelersCount: $travelersCount,
                        showPassengerSheet: $showPassengerSheet,
                        adults: $adults,
                        children: $children,
                        infants: $infants,
                        selectedClass: $selectedClass,
                        navigateToLocationSelection: $navigateToLocationSelection,
                        navigateToDateSelection: $navigateToDateSelection,
                        buttonAnimationNamespace: namespace,   // IMPORTANT: same namespace
                        onSearchFlights: onSearchFlights
                    )
                }
            }
//            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
//        .frame(height: headerHeight, alignment: .bottom)
        .onChange(of: progress) { p in
            withAnimation(.spring(response: 0.35, dampingFraction: 1.85)) {
                isCollapsed = p > threshold
            }
        }
        .animation(.easeOut(duration: 0.15), value: progress)
    }

    // SAME formatter logic you already had in ExpandableSearchContainer
    private func formatTravelDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"

        guard let firstDate = selectedDates.first else {
            return formatter.string(from: Date())
        }
        if !isOneWay && selectedDates.count > 1 {
            return "\(formatter.string(from: firstDate)) - \(formatter.string(from: selectedDates[1]))"
        } else {
            return formatter.string(from: firstDate)
        }
    }
}
