//
//  FilterSheet+PriceUpdates.swift
//  D2Flight
//
//  Fixed extension to provide enhanced price functionality for FilterSheet
//

import SwiftUI

extension UnifiedFilterSheet {
    
    // ✅ FIXED: Enhanced price content with proper binding and method access
    var enhancedPriceContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Pricing Info Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("daily.local.taxes.fees".localized)
                        .font(CustomFont.font(.medium, weight: .semibold))
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                
                Text("Average price is ₹\(Int(averagePrice))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // ✅ FIXED: Use proper method call instead of dynamic member
                if filterViewModel.isPriceFilterActive() {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Color("Violet"))
                            .font(.caption)
                        Text("Price filter is active")
                            .font(.caption)
                            .foregroundColor(Color("Violet"))
                    }
                    .padding(.top, 4)
                }
            }
            
            // ✅ FIXED: Enhanced Price Slider with proper change tracking
            EnhancedPriceRangeSlider(
                range: Binding(
                    get: { filterViewModel.priceRange },
                    set: { newRange in
                        // Update the range immediately for UI responsiveness
                        filterViewModel.priceRange = newRange
                    }
                ),
                minPrice: minPrice,
                maxPrice: maxPrice
            ) { newRange in
                // ✅ CRITICAL: This is called when user finishes dragging
                print("🔧 Price range changed in FilterSheet:")
                print("   New range: ₹\(newRange.lowerBound) - ₹\(newRange.upperBound)")
                
                // ✅ FIXED: Use the correct method name
                filterViewModel.updatePriceRange(newRange: newRange)
            }
            
            // ✅ Current filter status
            if filterViewModel.isPriceFilterActive() {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Filter will be applied: ₹\(Int(filterViewModel.priceRange.lowerBound)) - ₹\(Int(filterViewModel.priceRange.upperBound))")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // ✅ FIXED: Enhanced clear filters for price
    func clearPriceFilters() {
        print("🗑️ Clearing price filters in FilterSheet")
        // ✅ FIXED: Use proper method call instead of dynamic member
        filterViewModel.resetPriceFilter()
    }
}

// ✅ Usage instructions for updating your existing FilterSheet.swift:
/*
 
 REPLACE the existing priceContent computed property with:
 
 var priceContent: some View {
     enhancedPriceContent
 }
 
 AND UPDATE the clearFilters() method's .price case to:
 
 case .price:
     clearPriceFilters()
 
 */
