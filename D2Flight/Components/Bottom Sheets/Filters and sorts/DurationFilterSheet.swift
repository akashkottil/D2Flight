//
//  DurationFilterSheet.swift
//  D2Flight
//
//  Created by Assistant on 31/05/25.
//

import SwiftUI

struct DurationFilterSheet: View {
    @Binding var isPresented: Bool
    @Binding var departureStopoverRange: ClosedRange<Double>
    @Binding var departureLegRange: ClosedRange<Double>
    @Binding var returnStopoverRange: ClosedRange<Double>
    @Binding var returnLegRange: ClosedRange<Double>
    let isRoundTrip: Bool
    let originCode: String
    let destinationCode: String
    var onApply: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Duration")
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
                    // Departure Duration Filters
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(originCode) - \(destinationCode)")
                            .font(CustomFont.font(.regular, weight: .semibold))
                            .foregroundColor(.gray)
                        
                        VStack(spacing: 20) {
                            // Stopover Duration
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Stopover")
                                    .font(CustomFont.font(.regular, weight: .medium))
                                    .foregroundColor(.black)
                                
                                DurationRangeSlider(
                                    range: $departureStopoverRange,
                                    minDuration: 0,
                                    maxDuration: 1440,
                                    isDuration: true
                                )
                            }
                            
                            // Flight Leg Duration
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Flight leg")
                                    .font(CustomFont.font(.regular, weight: .medium))
                                    .foregroundColor(.black)
                                
                                DurationRangeSlider(
                                    range: $departureLegRange,
                                    minDuration: 0,
                                    maxDuration: 1440,
                                    isDuration: true
                                )
                            }
                        }
                    }
                    
                    // Return Duration Filters (only for round trip)
                    if isRoundTrip {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("\(destinationCode) - \(originCode)")
                                .font(CustomFont.font(.regular, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            VStack(spacing: 20) {
                                // Stopover Duration
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Stopover")
                                        .font(CustomFont.font(.regular, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    DurationRangeSlider(
                                        range: $returnStopoverRange,
                                        minDuration: 0,
                                        maxDuration: 1440,
                                        isDuration: true
                                    )
                                }
                                
                                // Flight Leg Duration
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Flight leg")
                                        .font(CustomFont.font(.regular, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    DurationRangeSlider(
                                        range: $returnLegRange,
                                        minDuration: 0,
                                        maxDuration: 1440,
                                        isDuration: true
                                    )
                                }
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
                            departureStopoverRange = 0...1440
                            departureLegRange = 0...1440
                            returnStopoverRange = 0...1440
                            returnLegRange = 0...1440
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

struct DurationRangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let minDuration: Double
    let maxDuration: Double
    let isDuration: Bool

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

                    // Selected range (active track)
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(Color("Violet"))
                        .frame(
                            width: CGFloat((range.upperBound - range.lowerBound) / (maxDuration - minDuration)) * width,
                            height: trackHeight
                        )
                        .offset(x: CGFloat((range.lowerBound - minDuration) / (maxDuration - minDuration)) * width)

                    // Lower thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Circle()
                                .stroke(Color("Violet"), lineWidth: 3)
                        )
//                        .shadow(radius: 1)
                        .offset(x: CGFloat((range.lowerBound - minDuration) / (maxDuration - minDuration)) * width - thumbSize / 50)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let location = max(0, min(Double(value.location.x), width))
                                    let newValue = minDuration + (location / width) * (maxDuration - minDuration)
                                    let clampedValue = max(minDuration, min(range.upperBound, newValue))
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
                        .offset(x: CGFloat((range.upperBound - minDuration) / (maxDuration - minDuration)) * width - thumbSize )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let location = max(0, min(Double(value.location.x), width))
                                    let newValue = minDuration + (location / width) * (maxDuration - minDuration)
                                    let clampedValue = max(range.lowerBound, min(maxDuration, newValue))
                                    range = range.lowerBound...clampedValue
                                }
                        )
                }
            }
            .frame(height: 28)

            // Duration labels
            HStack {
                Text(isDuration ? formatDuration(range.lowerBound) : formatTime(range.lowerBound))
                    .font(CustomFont.font(.small))
                    .foregroundColor(.gray)
                Spacer()
                Text(isDuration ? formatDuration(range.upperBound) : formatTime(range.upperBound))
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

    private func formatDuration(_ minutes: Double) -> String {
        let totalMinutes = Int(minutes)
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        return "\(hours)h \(mins)m"
    }
}


#Preview {
    DurationFilterSheet(
        isPresented: .constant(true),
        departureStopoverRange: .constant(60...300),
        departureLegRange: .constant(120...480),
        returnStopoverRange: .constant(60...300),
        returnLegRange: .constant(120...480),
        isRoundTrip: true,
        originCode: "CCJ",
        destinationCode: "CNN",
        onApply: {}
    )
}
