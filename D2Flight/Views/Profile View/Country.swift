import SwiftUI

struct Country: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var countryManager = CountryManager.shared
    @State private var selectedCountry: CountryInfo?
    @State private var searchText: String = ""
    
    // Filtered countries based on search
    private var filteredCountries: [CountryInfo] {
        if searchText.isEmpty {
            return countryManager.countries
        } else {
            return countryManager.searchCountries(query: searchText)
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
                    
                    Text("Select country")
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
                    
                    TextField("Search country", text: $searchText)
                        .font(.system(size: 16))
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
                if countryManager.isLoading {
                    // Loading State
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading countries...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                    
                } else if let errorMessage = countryManager.errorMessage {
                    // Error State
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("Error loading countries")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            countryManager.loadCountries()
                        }
                        .foregroundColor(.blue)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                    
                } else if filteredCountries.isEmpty {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No countries found")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Try searching with a different keyword")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                    .padding()
                    
                } else {
                    // Country List (same design as Currency.swift)
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredCountries) { country in
                                HStack(spacing: 20) {
                                    // Selection Radio Button (same as Currency)
                                    ZStack {
                                        if selectedCountry?.countryCode == country.countryCode {
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
                                    
                                    Text(country.countryName)
                                        .foregroundColor(.primary)
                                        .font(.system(size: 16))
                                    
                                    Spacer()
                                    
                                    Text(country.countryCode.uppercased())
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCountry = country
                                    print("🌍 Selected country: \(country.countryName) (\(country.countryCode))")
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
            // Set default selection to United States if available
            if selectedCountry == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    selectedCountry = countryManager.countries.first { $0.countryCode.lowercased() == "us" }
                }
            }
        }
    }
}

#Preview {
    Country()
}
