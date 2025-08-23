////
////  StopsFilterSheet.swift
////  D2Flight
////
////  Created by Akash Kottil on 21/08/25.
////
//
//
//import SwiftUI
//
//// MARK: - Stops Filter Sheet
//struct StopsFilterSheet: View {
//    @Binding var isPresented: Bool
//    @ObservedObject var filterViewModel: FilterViewModel
//    let onApply: () -> Void
//    
//    // Local state for stops selection
//    @State private var selectedStopsOption: StopsOption = .any
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // MARK: - Sheet Header
//            VStack(spacing: 16) {
//                // Handle bar
//                RoundedRectangle(cornerRadius: 2)
//                    .fill(Color.gray.opacity(0.3))
//                    .frame(width: 40, height: 4)
//                    .padding(.top, 8)
//                
//                // Title and Close
//                HStack {
//                    Text("Stops")
//                        .font(.system(size: 20, weight: .semibold))
//                        .foregroundColor(.black)
//                    
//                    Spacer()
//                    
//                    Button(action: {
//                        isPresented = false
//                    }) {
//                        Image(systemName: "xmark")
//                            .font(.system(size: 16, weight: .medium))
//                            .foregroundColor(.gray)
//                            .frame(width: 30, height: 30)
//                            .background(Color.gray.opacity(0.1))
//                            .clipShape(Circle())
//                    }
//                }
//                .padding(.horizontal, 20)
//            }
//            .padding(.bottom, 20)
//            
//            // MARK: - Stops Options
//            VStack(spacing: 0) {
//                ForEach(StopsOption.allCases, id: \.self) { option in
//                    StopsOptionRow(
//                        option: option,
//                        isSelected: selectedStopsOption == option,
//                        onTap: {
//                            selectedStopsOption = option
//                            print("🛑 Selected stops option: \(option.title) (max: \(option.maxStops?.description ?? "unlimited"))")
//                        }
//                    )
//                    
//                    // Add divider except for last item
//                    if option != StopsOption.allCases.last {
//                        Divider()
//                            .padding(.leading, 20)
//                    }
//                }
//            }
//            .background(Color.white)
//            .cornerRadius(12)
//            .padding(.horizontal, 20)
//            
//            Spacer()
//            
//            // MARK: - Bottom Buttons
//            VStack(spacing: 12) {
//                // Apply Button
//                Button(action: {
//                    applyStopsFilter()
//                }) {
//                    Text("Apply Filter")
//                        .font(.system(size: 16, weight: .semibold))
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .frame(height: 50)
//                        .background(Color("Violet"))
//                        .cornerRadius(12)
//                }
//                
//                // Clear Filter Button
//                Button(action: {
//                    clearStopsFilter()
//                }) {
//                    Text("Clear Filter")
//                        .font(.system(size: 16, weight: .medium))
//                        .foregroundColor(Color("Violet"))
//                        .frame(maxWidth: .infinity)
//                        .frame(height: 50)
//                        .background(Color("Violet").opacity(0.1))
//                        .cornerRadius(12)
//                }
//            }
//            .padding(.horizontal, 20)
//            .padding(.bottom, 20)
//        }
//        .background(Color.gray.opacity(0.05))
//        .onAppear {
//            // Set initial selection based on current filter state
//            selectedStopsOption = StopsOption.fromMaxStops(filterViewModel.maxStops)
//            print("🛑 Stops sheet opened with current selection: \(selectedStopsOption.title)")
//        }
//    }
//    
//    // MARK: - Apply Stops Filter
//    private func applyStopsFilter() {
//        print("\n🛑 ===== APPLYING STOPS FILTER =====")
//        print("🖱️ Apply button pressed")
//        print("   Selected option: \(selectedStopsOption.title)")
//        print("   Max stops value: \(selectedStopsOption.maxStops?.description ?? "unlimited")")
//        
//        // Update FilterViewModel
//        if let maxStops = selectedStopsOption.maxStops {
//            filterViewModel.maxStops = maxStops
//            print("   Updated FilterViewModel.maxStops to: \(maxStops)")
//        } else {
//            filterViewModel.maxStops = 3 // Any stops
//            print("   Updated FilterViewModel.maxStops to: 3 (any stops)")
//        }
//        
//        print("🛑 ===== END APPLYING STOPS FILTER =====\n")
//        
//        // Close sheet and apply filter
//        isPresented = false
//        onApply()
//    }
//    
//    // MARK: - Clear Stops Filter
//    private func clearStopsFilter() {
//        print("\n🛑 ===== CLEARING STOPS FILTER =====")
//        print("🗑️ Clear filter button pressed")
//        print("   Previous max stops: \(filterViewModel.maxStops)")
//        
//        // Reset to "Any" (default)
//        selectedStopsOption = .any
//        filterViewModel.maxStops = 3
//        
//        print("   Reset max stops to: 3 (any stops)")
//        print("   Reset selection to: Any")
//        print("🛑 ===== END CLEARING STOPS FILTER =====\n")
//        
//        // Close sheet and apply filter (this will send empty filter)
//        isPresented = false
//        onApply()
//    }
//}
//
//// MARK: - Stops Option Row
//struct StopsOptionRow: View {
//    let option: StopsOption
//    let isSelected: Bool
//    let onTap: () -> Void
//    
//    var body: some View {
//        Button(action: onTap) {
//            HStack(spacing: 16) {
//                // Icon
//                ZStack {
//                    Circle()
//                        .fill(option.iconBackgroundColor)
//                        .frame(width: 40, height: 40)
//                    
//                    Image(systemName: option.iconName)
//                        .font(.system(size: 18, weight: .medium))
//                        .foregroundColor(option.iconColor)
//                }
//                
//                // Text Content
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(option.title)
//                        .font(.system(size: 16, weight: .medium))
//                        .foregroundColor(.black)
//                    
//                    Text(option.subtitle)
//                        .font(.system(size: 14))
//                        .foregroundColor(.gray)
//                }
//                
//                Spacer()
//                
//                // Selection Indicator
//                ZStack {
//                    Circle()
//                        .stroke(isSelected ? Color("Violet") : Color.gray.opacity(0.3), lineWidth: 2)
//                        .frame(width: 24, height: 24)
//                    
//                    if isSelected {
//                        Circle()
//                            .fill(Color("Violet"))
//                            .frame(width: 12, height: 12)
//                    }
//                }
//            }
//            .padding(.horizontal, 20)
//            .padding(.vertical, 16)
//            .background(Color.white)
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}
//
//// MARK: - Stops Option Model
//enum StopsOption: CaseIterable {
//    case any
//    case direct
//    case oneStop
//    case twoStops
//    
//    var title: String {
//        switch self {
//        case .any: return "Any"
//        case .direct: return "Direct"
//        case .oneStop: return "1 Stop"
//        case .twoStops: return "2 Stops"
//        }
//    }
//    
//    var subtitle: String {
//        switch self {
//        case .any: return "Show all flights"
//        case .direct: return "Non-stop flights only"
//        case .oneStop: return "Up to 1 stopover"
//        case .twoStops: return "Up to 2 stopovers"
//        }
//    }
//    
//    var iconName: String {
//        switch self {
//        case .any: return "airplane"
//        case .direct: return "arrow.right"
//        case .oneStop: return "arrow.turn.up.right"
//        case .twoStops: return "arrow.triangle.turn.up.right.diamond"
//        }
//    }
//    
//    var iconColor: Color {
//        switch self {
//        case .any: return .blue
//        case .direct: return .green
//        case .oneStop: return .orange
//        case .twoStops: return .red
//        }
//    }
//    
//    var iconBackgroundColor: Color {
//        return iconColor.opacity(0.1)
//    }
//    
//    var maxStops: Int? {
//        switch self {
//        case .any: return nil // Will be converted to 3 in the filter
//        case .direct: return 0
//        case .oneStop: return 1
//        case .twoStops: return 2
//        }
//    }
//    
//    // Helper to convert from maxStops value back to option
//    static func fromMaxStops(_ maxStops: Int) -> StopsOption {
//        switch maxStops {
//        case 0: return .direct
//        case 1: return .oneStop
//        case 2: return .twoStops
//        default: return .any
//        }
//    }
//}
//
//// MARK: - Preview
//#Preview {
//    @State var isPresented = true
//    @StateObject var filterViewModel = FilterViewModel()
//    
//    return StopsFilterSheet(
//        isPresented: $isPresented,
//        filterViewModel: filterViewModel,
//        onApply: {
//            print("Apply tapped")
//        }
//    )
//}
