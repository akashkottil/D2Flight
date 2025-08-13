import SwiftUI

struct Currency: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var currencyManager = CurrencyManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var searchText: String = ""
    
    // Filtered currencies based on search
    private var filteredCurrencies: [CurrencyInfo] {
        if searchText.isEmpty {
            return currencyManager.currencies
        } else {
            return currencyManager.searchCurrencies(query: searchText)
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
                                    // Selection Radio Button (using same design as original)
                                    ZStack {
                                        if settingsManager.selectedCurrency?.code == currency.code {
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
                                    // ✅ UPDATED: Save selection to SettingsManager
                                    settingsManager.setSelectedCurrency(currency)
                                    print("💰 Selected currency: \(currency.displayName) (\(currency.code))")
                                    
                                    // Auto-dismiss after selection
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
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
        .onAppear {
            // ✅ UPDATED: Set default selection if none exists
            if settingsManager.selectedCurrency == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let defaultCurrency = currencyManager.currencies.first(where: { $0.code == "INR" }) {
                        settingsManager.setSelectedCurrency(defaultCurrency)
                    }
                }
            }
        }
    }
}

#Preview {
    Currency()
}
