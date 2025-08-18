//
//  TimesFilterSheet.swift
//  D2Flight
//
//  Created by Assistant on 31/05/25.
//

import SwiftUI

struct TimesFilterSheet: View {
    @Binding var isPresented: Bool
    @Binding var departureTimeRange: ClosedRange<Double>
    @Binding var returnTimeRange: ClosedRange<Double>
    let isRoundTrip: Bool
    let originCode: String
    let destinationCode: String
    var onApply: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("times".localized)
                    .font(CustomFont.font(.large, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(CustomFont.font(.large, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Departure Time Range
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(originCode) - \(destinationCode)")
                            .font(CustomFont.font(.medium, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Taking off from \(originCode)")
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.black)
                            
                            TimeRangeSlider(
                                range: $departureTimeRange,
                                minTime: 0,
                                maxTime: 1440
                            )
                        }
                    }
                    
                    // Return Time Range (only for round trip)
                    if isRoundTrip {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("\(destinationCode) - \(originCode)")
                                .font(CustomFont.font(.medium, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Taking off from \(destinationCode)")
                                    .font(CustomFont.font(.medium, weight: .semibold))
                                    .foregroundColor(.black)
                                
                                TimeRangeSlider(
                                    range: $returnTimeRange,
                                    minTime: 0,
                                    maxTime: 1440
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100)
            }
            
            Spacer()
            
            // Bottom Section with Clear and Apply Buttons
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    SecondaryButton(
                        title: "Clear",
                        font: CustomFont.font(.medium),
                        fontWeight: .semibold,
                        textColor: .gray,
                        width: nil,
                        height: 56,
                        cornerRadius: 16,
                        action: {
                            departureTimeRange = 0...1440
                            returnTimeRange = 0...1440
                        }
                    )
                    
                    PrimaryButton(
                        title: "Apply",
                        font: CustomFont.font(.medium),
                        fontWeight: .semibold,
                        textColor: .white,
                        width: nil,
                        height: 56,
                        cornerRadius: 16,
                        action: {
                            onApply()
                            isPresented = false
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white)
    }
}

struct TimeRangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let minTime: Double
    let maxTime: Double

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let trackHeight: CGFloat = 20
                let thumbSize: CGFloat = 16

                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: trackHeight)

                    // Active track
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(Color("Violet"))
                        .frame(
                            width: CGFloat((range.upperBound - range.lowerBound) / (maxTime - minTime)) * width,
                            height: trackHeight
                        )
                        .offset(x: CGFloat((range.lowerBound - minTime) / (maxTime - minTime)) * width)

                    // Lower thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Circle()
                                .stroke(Color("Violet"), lineWidth: 3)
                        )
                        .offset(x: CGFloat((range.lowerBound - minTime) / (maxTime - minTime)) * width - thumbSize / 50)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let location = max(0, min(Double(value.location.x), width))
                                    let newValue = minTime + (location / width) * (maxTime - minTime)
                                    let clampedValue = max(minTime, min(range.upperBound, newValue))
                                    range = clampedValue...range.upperBound
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
                        .offset(x: CGFloat((range.upperBound - minTime) / (maxTime - minTime)) * width - thumbSize)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let location = max(0, min(Double(value.location.x), width))
                                    let newValue = minTime + (location / width) * (maxTime - minTime)
                                    let clampedValue = max(range.lowerBound, min(maxTime, newValue))
                                    range = range.lowerBound...clampedValue
                                }
                        )
                }
            }
            .frame(height: 28)

            // Time labels
            HStack {
                Text(formatTime(range.lowerBound))
                    .font(CustomFont.font(.small))
                    .foregroundColor(.gray)

                Spacer()

                Text(formatTime(range.upperBound))
                    .font(CustomFont.font(.small))
                    .foregroundColor(.gray)
            }
        }
    }

    private func formatTime(_ minutes: Double) -> String {
        let totalMinutes = Int(minutes)
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }
}


#Preview {
    TimesFilterSheet(
        isPresented: .constant(true),
        departureTimeRange: .constant(480...1200), // 8:00 to 20:00
        returnTimeRange: .constant(480...1200),
        isRoundTrip: true,
        originCode: "CCJ",
        destinationCode: "CNN",
        onApply: {}
    )
}
