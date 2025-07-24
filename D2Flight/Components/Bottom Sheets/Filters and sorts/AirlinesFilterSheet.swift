////
////  AirlinesFilterSheet.swift
////  D2Flight
////
////  Created by Assistant on 31/05/25.
////
//
//import SwiftUI
//
//struct AirlinesFilterSheet: View {
//    @Binding var isPresented: Bool
//    @Binding var selectedAirlines: Set<String>
//    let availableAirlines: [AirlineOption]
//    var onApply: () -> Void
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // Header
//            HStack {
//                Text("Airlines")
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
//                VStack(spacing: 0) {
//                    // Select All Option
//                    airlineSelectionRow(
//                        name: "Select All",
//                        code: "ALL",
//                        price: nil,
//                        isSelected: selectedAirlines.count == availableAirlines.count,
//                        isSelectAll: true
//                    )
//                    
//                    // Individual Airlines
//                    ForEach(availableAirlines) { airline in
//                        airlineSelectionRow(
//                            name: airline.name,
//                            code: airline.code,
//                            price: airline.price,
//                            isSelected: selectedAirlines.contains(airline.code)
//                        )
//                    }
//                }
//                .padding(.horizontal, 24)
//                .padding(.bottom, 100)
//            }
//            
//            Spacer()
//            
//            // Apply Button
//            VStack {
//                PrimaryButton(
//                    title: "Apply",
//                    font: CustomFont.font(.large),
//                    fontWeight: .semibold,
//                    textColor: .white,
//                    width: nil,
//                    height: 56,
//                    horizontalPadding: 24,
//                    cornerRadius: 16,
//                    action: {
//                        onApply()
//                        isPresented = false
//                    }
//                )
//            }
//            .padding()
//            .padding(.bottom, 24)
//        }
//        .background(Color.white)
//    }
//    
//    private func airlineSelectionRow(
//        name: String,
//        code: String,
//        price: Double?,
//        isSelected: Bool,
//        isSelectAll: Bool = false
//    ) -> some View {
//        Button(action: {
//            if isSelectAll {
//                if selectedAirlines.count == availableAirlines.count {
//                    // Deselect all
//                    selectedAirlines.removeAll()
//                } else {
//                    // Select all
//                    selectedAirlines = Set(availableAirlines.map { $0.code })
//                }
//            } else {
//                if selectedAirlines.contains(code) {
//                    selectedAirlines.remove(code)
//                } else {
//                    selectedAirlines.insert(code)
//                }
//            }
//        }) {
//            HStack(spacing: 16) {
//                // Checkbox
//                ZStack {
//                    RoundedRectangle(cornerRadius: 4)
//                        .stroke(isSelected ? Color("Violet") : Color.gray.opacity(0.3), lineWidth: 2)
//                        .frame(width: 20, height: 20)
//                        .background(
//                            RoundedRectangle(cornerRadius: 4)
//                                .fill(isSelected ? Color("Violet") : Color.clear)
//                        )
//                    
//                    if isSelected {
//                        Image(systemName: "checkmark")
//                            .font(CustomFont.font(.small, weight: .bold))
//                            .foregroundColor(.white)
//                    }
//                }
//                
//                // Airline Logo (only for individual airlines)
//                if !isSelectAll {
//                    // Placeholder for airline logo - you can replace with AsyncImage
//                    RoundedRectangle(cornerRadius: 8)
//                        .fill(Color.red.opacity(0.8))
//                        .frame(width: 32, height: 32)
//                        .overlay(
//                            Text(String(name.prefix(2)))
//                                .font(CustomFont.font(.small, weight: .bold))
//                                .foregroundColor(.white)
//                        )
//                }
//                
//                // Airline Name
//                Text(name)
//                    .font(CustomFont.font(.medium, weight: .semibold))
//                    .foregroundColor(.black)
//                    .multilineTextAlignment(.leading)
//                
//                Spacer()
//                
//                // Price (only for individual airlines)
//                if let price = price {
//                    Text("$\(Int(price))")
//                        .font(CustomFont.font(.medium, weight: .semibold))
//                        .foregroundColor(.black)
//                }
//            }
//            .padding(.vertical, 16)
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}
//
//#Preview {
//    AirlinesFilterSheet(
//        isPresented: .constant(true),
//        selectedAirlines: .constant(Set(["QR", "EK", "UK"])),
//        availableAirlines: [
//            AirlineOption(code: "QR", name: "Qatar Airways", logo: "", price: 350),
//            AirlineOption(code: "EK", name: "Emirates", logo: "", price: 350),
//            AirlineOption(code: "UK", name: "Vistara", logo: "", price: 350),
//            AirlineOption(code: "SG", name: "Spice Jet", logo: "", price: 350),
//            AirlineOption(code: "6E", name: "Indigo", logo: "", price: 350),
//            AirlineOption(code: "EY", name: "Etihad", logo: "", price: 350)
//        ],
//        onApply: {}
//    )
//}
