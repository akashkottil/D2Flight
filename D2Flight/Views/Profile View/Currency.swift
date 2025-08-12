import SwiftUI

struct Currency: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var searchText: String = ""
    
    // Filtered currencies based on search with selected currency on top
    private var filteredCurrencies: [CurrencyInfo] {
        let baseCurrencies: [CurrencyInfo]
        
        if searchText.isEmpty {
            baseCurrencies = currencyManager.currencies
        } else {
            baseCurrencies = currencyManager.searchCurrencies(query: searchText)
        }
        
        // Move selected currency to top of the list
        guard let selectedCurrency = currencyManager.selectedCurrency else {
            return baseCurrencies
        }
        
        // Remove selected currency from the list and add it at the beginning
        let otherCurrencies = baseCurrencies.filter { $0.code != selectedCurrency.code }
        
        // Check if selected currency exists in filtered results
        if baseCurrencies.contains(where: { $0.code == selectedCurrency.code }) {
            return [selectedCurrency] + otherCurrencies
        } else {
            return baseCurrencies
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("BlackArrow")
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    Text("Select currency")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.trailing, 44) // To balance the left button spacing
                    Spacer()
                    
                   
                }
                .padding(.vertical)
                
                Divider()
                
                // Search Bar
                HStack(spacing: 20) {
                    Image("search")
                        .frame(width: 14,height: 14)
                    
                    TextField("Search currency", text: $searchText)
                        .font(CustomFont.font(.medium))
                        .foregroundColor(.primary)
                    
                    // Clear button
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(.gray.opacity(0.2))
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.top)
                
                // Content Area
                if currencyManager.isLoading {
                    // Loading State
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading currencies...")
                            .font(CustomFont.font(.regular))
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                    
                } else if let errorMessage = currencyManager.errorMessage {
                    // Error State
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("Error loading currencies")
                            .font(CustomFont.font(.medium, weight: .semibold))
                        
                        Text(errorMessage)
                            .font(CustomFont.font(.regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            currencyManager.loadCurrencies()
                        }
                        .foregroundColor(.blue)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                    
                } else if filteredCurrencies.isEmpty {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No currencies found")
                            .font(CustomFont.font(.medium, weight: .semibold))
                        
                        Text("Try searching with a different keyword")
                            .font(CustomFont.font(.regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                    
                } else {
                    // Currency List
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredCurrencies) { currency in
                                HStack(spacing: 20) {
                                    // Selection Radio Button
                                    ZStack {
                                        if currencyManager.selectedCurrency?.code == currency.code {
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
                                    
                                    Text(currency.displayName)
                                        .foregroundColor(.primary)
                                        .font(CustomFont.font(.medium))
                                    
                                    Spacer()
                                    
                                    Text(currency.code)
                                        .font(CustomFont.font(.medium))
                                        .foregroundColor(.red)
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    currencyManager.selectCurrency(currency)
                                    // Auto-dismiss the screen after selection
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
    }
}
