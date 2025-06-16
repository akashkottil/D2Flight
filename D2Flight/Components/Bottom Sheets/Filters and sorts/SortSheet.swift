//
//  SortSheet.swift
//  D2Flight
//
//  Created by Assistant on 31/05/25.
//

import SwiftUI

struct SortSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedSortOption: SortOption
    var onApply: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Sort")
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
                VStack(spacing: 0) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        sortSelectionRow(
                            title: option.displayName,
                            option: option,
                            isSelected: selectedSortOption == option
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Apply Button
            VStack {
                PrimaryButton(
                    title: "Apply",
                    font: CustomFont.font(.large),
                    fontWeight: .semibold,
                    textColor: .white,
                    width: nil,
                    height: 56,
                    horizontalPadding: 24,
                    cornerRadius: 16,
                    action: {
                        onApply()
                        isPresented = false
                    }
                )
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(Color.white)
    }
    
    private func sortSelectionRow(title: String, option: SortOption, isSelected: Bool) -> some View {
        Button(action: {
            selectedSortOption = option
        }) {
            HStack {
                Text(title)
                    .font(CustomFont.font(.medium, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                ZStack {
                    if isSelected {
                        Circle()
                            .stroke(Color("Violet"), lineWidth: 6)
                            .frame(width: 20, height: 20)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SortSheet(
        isPresented: .constant(true),
        selectedSortOption: .constant(.best),
        onApply: {}
    )
}
