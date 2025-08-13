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
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // Observe the managers to get selected values
    @StateObject private var countryManager = CountryManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared
    
    private var topItems: [ProfileItem] {
            [
                ProfileItem(
                    icon: "RegionIcon",
                    // ✅ LOCALIZED: Using localized title
                    title: "region".localized,
                    trailing: settingsManager.getSelectedCountryName(),
                    destination: AnyView(Country()),
                    showsArrow: true
                ),
                ProfileItem(
                    icon: "CurrencyIcon",
                    // ✅ LOCALIZED: Using localized title
                    title: "currency".localized,
                    trailing: settingsManager.getSelectedCurrencyCode(),
                    destination: AnyView(Currency()),
                    showsArrow: true
                )
            ]
        }
    
    var bottomItems: [ProfileItem] {
        var items: [ProfileItem] = [
            ProfileItem(
                icon: "RequestIcon",
                // ✅ LOCALIZED: Using localized title
                title: "request.a.feature".localized,
                trailing: nil,
                destination: AnyView(DemoScreen()),
                showsArrow: true
            ),
            ProfileItem(
                icon: "ContactIcon",
                // ✅ LOCALIZED: Using localized title
                title: "contact.us".localized,
                trailing: nil,
                destination: AnyView(DemoScreen()),
                showsArrow: true
            ),
            ProfileItem(
                icon: "PrivacyIcon",
                // ✅ LOCALIZED: Using localized title
                title: "privacy.policy".localized,
                trailing: nil,
                destination: AnyView(DemoScreen()),
                showsArrow: true
            ),
            ProfileItem(
                icon: "AboutIcon",
                // ✅ LOCALIZED: Using localized title
                title: "about.us".localized,
                trailing: nil,
                destination: AnyView(AboutUs()),
                showsArrow: true
            ),
            ProfileItem(
                icon: "RateIcon",
                // ✅ LOCALIZED: Using localized title
                title: "rate.our.app".localized,
                trailing: nil,
                destination: AnyView(DemoScreen()),
                showsArrow: true
            ),
        ]
        
        if isLoggedIn {
            items.insert(
                ProfileItem(
                    icon: "AccountIcon",
                    // ✅ LOCALIZED: Using localized title
                    title: "account.settings".localized,
                    trailing: nil,
                    destination: AnyView(AccountSettings()),
                    showsArrow: true
                ),
                at: 1
            )
            items.append(
                ProfileItem(
                    icon: "LogoutIcon",
                    // ✅ LOCALIZED: Using localized title
                    title: "logout".localized,
                    trailing: nil,
                    destination: nil,
                    showsArrow: false
                )
            )
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
            print("   Language: \(localizationManager.currentLanguage)")
        }
        // ✅ IMPORTANT: Listen to language changes to update the UI
        .onReceive(localizationManager.$currentLanguage) { _ in
            print("🌐 Language changed, UI will refresh")
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
                            if item.title == "logout".localized {
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
        // ✅ LOCALIZED: Using localized text
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
