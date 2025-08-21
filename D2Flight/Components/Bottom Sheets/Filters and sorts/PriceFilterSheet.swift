////
////  PriceFilterSheet.swift
////  D2Flight
////
////  Created by Assistant on 31/05/25.
////
//
//import SwiftUI
//
//struct PriceFilterSheet: View {
//    @Binding var isPresented: Bool
//    @Binding var priceRange: ClosedRange<Double>
//    let minPrice: Double
//    let maxPrice: Double
//    let averagePrice: Double
//    var onApply: () -> Void
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // Header
//            HStack {
//                Text("price".localized)
//                    .font(CustomFont.font(.large, weight: .bold))
//                    .foregroundColor(.black)
//                Spacer()
//                Button(action: {
//                    isPresented = false
//                }) {
//                    Image(systemName: "xmark")
//                        .font(CustomFont.font(.large, weight: .medium))
//                        .foregroundColor(.black)
//                }
//            }
//            .padding(.horizontal, 24)
//            .padding(.top, 24)
//            .padding(.bottom, 16)
//            
//            Divider()
//                .padding(.bottom, 20)
//            
//            ScrollView {
//                VStack(alignment: .leading, spacing: 24) {
//                    // Pricing Info
//                    VStack(alignment: .leading, spacing: 4) {
//                        HStack {
//                            Text("daily.local.taxes.fees.2".localized)
//                                .font(CustomFont.font(.regular, weight: .semibold))
//                                .foregroundColor(.black)
//                            Spacer()
//                            Image(systemName: "chevron.down")
//                                .foregroundColor(.black)
//                        }
//                        
//                        Text("Average price is $\(Int(averagePrice))")
//                            .font(.system(size: 13))
//                            .foregroundColor(.gray)
//                    }
//                    
//                    // Price Slider
//                    PriceRangeSlider(
//                        range: $priceRange,
//                        minPrice: minPrice,
//                        maxPrice: maxPrice
//                    )
//                }
//                .padding(.horizontal, 24)
//                .padding(.bottom, 100)
//            }
//            
//            Spacer()
//            
//            // Bottom Buttons
//            VStack(spacing: 16) {
//                HStack(spacing: 12) {
//                    SecondaryButton(
//                        title: "Clear",
//                        font: CustomFont.font(.medium),
//                        fontWeight: .semibold,
//                        textColor: .gray,
//                        width: nil,
//                        height: 56,
//                        cornerRadius: 16,
//                        action: {
//                            priceRange = minPrice...maxPrice
//                        }
//                    )
//                    
//                    PrimaryButton(
//                        title: "Apply",
//                        font: CustomFont.font(.medium),
//                        fontWeight: .semibold,
//                        textColor: .white,
//                        width: nil,
//                        height: 56,
//                        cornerRadius: 16,
//                        action: {
//                            onApply()
//                            isPresented = false
//                        }
//                    )
//                }
//            }
//            .padding(.horizontal, 24)
//            .padding(.bottom, 24)
//        }
//        .background(Color.white)
//    }
//}
//
//
//import SwiftUI
//
//struct PriceRangeSlider: View {
//    @Binding var range: ClosedRange<Double>
//    let minPrice: Double
//    let maxPrice: Double
//
//    var body: some View {
//        VStack(spacing: 12) {
//            GeometryReader { geometry in
//                let width = geometry.size.width
//                let trackHeight: CGFloat = 20
//                let thumbSize: CGFloat = 16
//
//                ZStack(alignment: .leading) {
//                    RoundedRectangle(cornerRadius: trackHeight / 2)
//                        .fill(Color.gray.opacity(0.3))
//                        .frame(height: trackHeight)
//
//                    RoundedRectangle(cornerRadius: trackHeight / 2)
//                        .fill(Color("Violet"))
//                        .frame(
//                            width: CGFloat((range.upperBound - range.lowerBound) / (maxPrice - minPrice)) * width,
//                            height: trackHeight
//                        )
//                        .offset(x: CGFloat((range.lowerBound - minPrice) / (maxPrice - minPrice)) * width)
//
//                    // Lower thumb
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: thumbSize, height: thumbSize)
//                        .overlay(Circle().stroke(Color("Violet"), lineWidth: 3))
//                        .offset(x: CGFloat((range.lowerBound - minPrice) / (maxPrice - minPrice)) * width - thumbSize / 50)
//                        .gesture(
//                            DragGesture()
//                                .onChanged { value in
//                                    let location = max(0, min(Double(value.location.x), width))
//                                    let newValue = minPrice + (location / width) * (maxPrice - minPrice)
//                                    let clampedValue = max(minPrice, min(range.upperBound, newValue))
//                                    range = clampedValue...range.upperBound
//                                }
//                        )
//
//                    // Upper thumb
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: thumbSize, height: thumbSize)
//                        .overlay(Circle().stroke(Color("Violet"), lineWidth: 3))
//                        .offset(x: CGFloat((range.upperBound - minPrice) / (maxPrice - minPrice)) * width - thumbSize)
//                        .gesture(
//                            DragGesture()
//                                .onChanged { value in
//                                    let location = max(0, min(Double(value.location.x), width))
//                                    let newValue = minPrice + (location / width) * (maxPrice - minPrice)
//                                    let clampedValue = max(range.lowerBound, min(maxPrice, newValue))
//                                    range = range.lowerBound...clampedValue
//                                }
//                        )
//                }
//            }
//            .frame(height: 28)
//
//            // Price labels
//            HStack {
//                Text("$\(Int(range.lowerBound))")
//                    .font(CustomFont.font(.small))
//                    .foregroundColor(.gray)
//                Spacer()
//                Text("$\(Int(range.upperBound))")
//                    .font(CustomFont.font(.small))
//                    .foregroundColor(.gray)
//            }
//        }
//    }
//}
//
//#Preview {
//    PriceFilterSheet(
//        isPresented: .constant(true),
//        priceRange: .constant(100...800),
//        minPrice: 0,
//        maxPrice: 1000,
//        averagePrice: 250,
//        onApply: {}
//    )
//}
