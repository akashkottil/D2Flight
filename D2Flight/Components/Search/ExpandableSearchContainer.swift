import SwiftUI

struct ExpandableSearchContainer: View {
    @Namespace private var animationNamespace
    
    // State management
    @State private var isExpanded = true
    @State private var dragOffset: CGFloat = 0
    @State private var buttonOffset: CGFloat = 0
    
    // Binding properties for search functionality
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
    
    // Action closures
    let onSearchFlights: () -> Void
    
    // Animation constants
    private let expandedHeight: CGFloat = 400
    private let collapsedHeight: CGFloat = 80
    private let dragThreshold: CGFloat = 50
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Expanded SearchCard
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
                    buttonAnimationNamespace: animationNamespace,
                    onSearchFlights: onSearchFlights
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .move(edge: .bottom))
                ))
            } else {
                // Collapsed SearchCard
                CollapsedSearch(
                    originCode: originIATACode.isEmpty ? "NYC" : originIATACode,
                    destinationCode: destinationIATACode.isEmpty ? "LHR" : destinationIATACode,
                    travelDate: formatTravelDate(),
                    travelerInfo: travelersCount,
                    animationNamespace: animationNamespace,
                    onEdit: {
                        expandSearchCard()
                    },
                    onSearch: onSearchFlights
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .offset(y: dragOffset + buttonOffset)
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    handleDragChanged(value)
                }
                .onEnded { value in
                    handleDragEnded(value)
                }
        )
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isExpanded)
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: dragOffset)
        .animation(.spring(response: 0.4, dampingFraction: 0.9), value: buttonOffset)
    }
    
    // MARK: - Drag Gesture Handlers
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        let translation = value.translation.height
        
        if isExpanded {
            // When expanded, only allow upward drag (collapse)
            if translation < 0 {
                dragOffset = translation
                buttonOffset = translation * 0.3 // Button moves slower than card
            }
        } else {
            // When collapsed, only allow downward drag (expand)
            if translation > 0 {
                dragOffset = translation
                buttonOffset = translation * 0.3
            }
        }
    }
    
    private func handleDragEnded(_ value: DragGesture.Value) {
        let translation = value.translation.height
        let velocity = value.velocity.height
        
        // Determine if should change state based on drag distance and velocity
        let shouldToggle = abs(translation) > dragThreshold || abs(velocity) > 500
        
        if shouldToggle {
            if isExpanded && translation < 0 {
                // Collapse the card
                collapseSearchCard()
            } else if !isExpanded && translation > 0 {
                // Expand the card
                expandSearchCard()
            } else {
                // Reset to current state
                resetDragOffset()
            }
        } else {
            // Reset to current state if drag wasn't sufficient
            resetDragOffset()
        }
    }
    
    private func expandSearchCard() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = true
            resetDragOffset()
        }
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func collapseSearchCard() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = false
            resetDragOffset()
        }
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func resetDragOffset() {
        dragOffset = 0
        buttonOffset = 0
    }
    
    // MARK: - Helper Methods
    
    private func formatTravelDate() -> String {
        guard let firstDate = selectedDates.first else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM"
            return formatter.string(from: Date())
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        
        if !isOneWay && selectedDates.count > 1 {
            let returnDateString = formatter.string(from: selectedDates[1])
            return "\(formatter.string(from: firstDate)) - \(returnDateString)"
        } else {
            return formatter.string(from: firstDate)
        }
    }
    
    // MARK: - Public Methods for External Control
    
    func forceExpand() {
        expandSearchCard()
    }
    
    func forceCollapse() {
        collapseSearchCard()
    }
    
    var currentState: Bool {
        return isExpanded
    }
}
