////
////  ClassesSheet.swift
////  D2Flight
////
////  Created by Akash Kottill on 23/05/25.
////
//
//import SwiftUI
//
//struct ClassesSheet: View {
//    @Binding var isPresented: Bool
//    @Binding var selectedClass: TravelClass
//    var onApply: () -> Void
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            HStack {
//                Text("classes".localized)
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
//                    ForEach(TravelClass.allCases, id: \.self) { travelClass in
//                        classSelectionRow(
//                            title: travelClass.displayName,
//                            travelClass: travelClass,
//                            isSelected: selectedClass == travelClass
//                        )
//                    }
//                }
//                .padding(.horizontal, 24)
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
//    private func classSelectionRow(title: String, travelClass: TravelClass, isSelected: Bool) -> some View {
//        Button(action: {
//            selectedClass = travelClass
//        }) {
//            HStack {
//                Text(title)
//                    .font(CustomFont.font(.medium, weight: .semibold))
//                    .foregroundColor(.black)
//                
//                Spacer()
//                
//                ZStack {
//                    if isSelected {
//                        Circle()
//                            .stroke(Color("Violet"), lineWidth: 6)
//                            .frame(width: 20, height: 20)
//                        
//                        Circle()
//                            .fill(Color.white)
//                            .frame(width: 16, height: 16)
//                    } else {
//                        Circle()
//                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
//                            .frame(width: 20, height: 20)
//                    }
//                }
//            }
//            .padding(.vertical, 16)
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}
//
//#Preview {
//    ClassesSheet(
//        isPresented: .constant(true),
//        selectedClass: .constant(.premiumEconomy),
//        onApply: {}
//    )
//}
