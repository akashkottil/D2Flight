import SwiftUI

// MARK: - Profile Item Model
struct ProfileItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let trailing: String?
    let destination: AnyView?
    let showsArrow: Bool
}

// MARK: - ProfileLists View
struct ProfileLists: View {
    
    @Binding var isLoggedIn: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    
    // Observe the managers to get selected values
    @StateObject private var countryManager = CountryManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared
    
    // Top Section Items - now computed to show dynamic values
    var topItems: [ProfileItem] {
        let selectedCountryName = countryManager.selectedCountry?.countryName ?? "Loading..."
        let selectedCurrencyCode = currencyManager.selectedCurrency?.code ?? "Loading..."
        
        return [
            ProfileItem(icon: "RegionIcon", title: "Region", trailing: selectedCountryName, destination: AnyView(Country()), showsArrow: true),
            ProfileItem(icon: "CurrencyIcon", title: "Currency", trailing: selectedCurrencyCode, destination: AnyView(Currency()), showsArrow: true)
        ]
    }
    
    var bottomItems: [ProfileItem] {
        var items: [ProfileItem] = [
            ProfileItem(icon: "RequestIcon", title: "Request a Feature", trailing: nil, destination: AnyView(DemoScreen()), showsArrow: true),
            ProfileItem(icon: "ContactIcon", title: "Contact Us", trailing: nil, destination: AnyView(DemoScreen()), showsArrow: true),
            ProfileItem(icon: "PrivacyIcon", title: "Privacy Policy", trailing: nil, destination: AnyView(DemoScreen()), showsArrow: true),
            ProfileItem(icon: "AboutIcon", title: "About Us", trailing: nil, destination: AnyView(AboutUs()), showsArrow: true),
            ProfileItem(icon: "RateIcon", title: "Rate Our App", trailing: nil, destination: AnyView(DemoScreen()), showsArrow: true),
        ]
        
        if isLoggedIn {
            items.insert(ProfileItem(icon: "AccountIcon", title: "Account Settings", trailing: nil, destination: AnyView(AccountSettings()), showsArrow: true), at: 1)
            items.append(ProfileItem(icon: "LogoutIcon", title: "Logout", trailing: nil, destination: nil, showsArrow: false))
        }
        
        return items
    }
    
    var body: some View {
        VStack(spacing: 16) {
            profileCard(items: topItems)
            profileCard(items: bottomItems)
        }
        .padding()
        .onAppear {
            // Ensure managers are loaded when view appears
            print("📱 ProfileLists appeared - Current selections:")
            print("   Country: \(countryManager.selectedCountry?.countryName ?? "None")")
            print("   Currency: \(currencyManager.selectedCurrency?.code ?? "None")")
        }
    }
    
    // MARK: - Profile Card Builder
    func profileCard(items: [ProfileItem]) -> some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                
                Group {
                    if let destination = item.destination {
                        NavigationLink(destination: destination) {
                            ProfileListItem(
                                icon: item.icon,
                                title: item.title,
                                trailing: item.trailing,
                                showsArrow: item.showsArrow
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Button {
                            if item.title == "Logout" {
                                Task {
                                    await authManager.signOut()
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isLoggedIn = false
                                    }
                                }
                            } else {
                                print("Tapped on \(item.title)")
                            }
                        } label: {
                            ProfileListItem(
                                icon: item.icon,
                                title: item.title,
                                trailing: item.trailing,
                                showsArrow: item.showsArrow
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if index != items.count - 1 {
                    Divider().padding(.leading, 40)
                }
            }
        }
        .background(Color("Light"))
        .cornerRadius(10)
    }
}

// MARK: - Reusable List Item
struct ProfileListItem: View {
    let icon: String
    let title: String
    let trailing: String?
    let showsArrow: Bool
    
    var body: some View {
        HStack {
            Image(icon)
                .resizable()
                .frame(width: 29, height: 29)
            Text(title)
                .font(CustomFont.font(.medium))
            Spacer()
            if let trailingText = trailing {
                Text(trailingText)
                    .font(CustomFont.font(.medium))
                    .fontWeight(.bold)
                    .foregroundColor(.black.opacity(0.5))
            }
            if showsArrow {
                Image("TransparentArrow")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Demo Screens
struct DemoScreen: View {
    var body: some View {
        Text("Demo Screen")
            .navigationTitle("Demo")
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        ProfileLists(isLoggedIn: .constant(true))
            .environmentObject(AuthenticationManager.shared)
    }
}
