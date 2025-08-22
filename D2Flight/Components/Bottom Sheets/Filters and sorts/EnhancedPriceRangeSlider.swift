

import SwiftUI

struct FixedPriceRangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let minPrice: Double
    let maxPrice: Double
    let onPriceChanged: (ClosedRange<Double>) -> Void
    
    @State private var isDragging = false
    @State private var dragStartValue: ClosedRange<Double>?
    
    var body: some View {
        VStack(spacing: 16) {
            // Price display header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Minimum Price")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("₹\(formatPrice(range.lowerBound))")
                        .font(.headline)
                        .foregroundColor(Color("Violet"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Maximum Price")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("₹\(formatPrice(range.upperBound))")
                        .font(.headline)
                        .foregroundColor(Color("Violet"))
                }
            }
            
            // Slider
            GeometryReader { geometry in
                let width = geometry.size.width
                let trackHeight: CGFloat = 6
                let thumbSize: CGFloat = 24
                
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: trackHeight)
                    
                    // Active track
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(Color("Violet"))
                        .frame(
                            width: CGFloat((range.upperBound - range.lowerBound) / (maxPrice - minPrice)) * width,
                            height: trackHeight
                        )
                        .offset(x: CGFloat((range.lowerBound - minPrice) / (maxPrice - minPrice)) * width)
                    
                    // Lower thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Circle()
                                .stroke(Color("Violet"), lineWidth: 3)
                        )
                        .shadow(
                            color: isDragging ? Color("Violet").opacity(0.4) : Color.black.opacity(0.1),
                            radius: isDragging ? 8 : 3
                        )
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .offset(x: CGFloat((range.lowerBound - minPrice) / (maxPrice - minPrice)) * width - thumbSize / 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if dragStartValue == nil {
                                        dragStartValue = range
                                        isDragging = true
                                    }
                                    
                                    let location = max(0, min(Double(value.location.x), width))
                                    let newValue = minPrice + (location / width) * (maxPrice - minPrice)
                                    let clampedValue = max(minPrice, min(range.upperBound - 100, newValue))
                                    
                                    range = clampedValue...range.upperBound
                                    
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    if let startValue = dragStartValue, startValue != range {
                                        onPriceChanged(range)
                                        print("🔧 Lower thumb completed: ₹\(Int(range.lowerBound))")
                                    }
                                    dragStartValue = nil
                                }
                        )
                    
                    // Upper thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Circle()
                                .stroke(Color("Violet"), lineWidth: 3)
                        )
                        .shadow(
                            color: isDragging ? Color("Violet").opacity(0.4) : Color.black.opacity(0.1),
                            radius: isDragging ? 8 : 3
                        )
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .offset(x: CGFloat((range.upperBound - minPrice) / (maxPrice - minPrice)) * width - thumbSize / 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if dragStartValue == nil {
                                        dragStartValue = range
                                        isDragging = true
                                    }
                                    
                                    let location = max(0, min(Double(value.location.x), width))
                                    let newValue = minPrice + (location / width) * (maxPrice - minPrice)
                                    let clampedValue = max(range.lowerBound + 100, min(maxPrice, newValue))
                                    
                                    range = range.lowerBound...clampedValue
                                    
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    if let startValue = dragStartValue, startValue != range {
                                        onPriceChanged(range)
                                        print("🔧 Upper thumb completed: ₹\(Int(range.upperBound))")
                                    }
                                    dragStartValue = nil
                                }
                        )
                }
            }
            .frame(height: 44)
            
            // Range indicator
            HStack {
                Text("₹\(formatPrice(minPrice))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("₹\(formatPrice(maxPrice))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDragging)
    }
    
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        
        return formatter.string(from: NSNumber(value: Int(price))) ?? "\(Int(price))"
    }
}
