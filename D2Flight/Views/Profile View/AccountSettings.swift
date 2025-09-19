import SwiftUI

struct AccountSettings: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("BlackArrow")
                            .padding(.horizontal)
                    }

                    Spacer()
                    
                    Text("account.settings".localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.trailing, 44) // To balance the left button spacing
                }
                .padding()
                Divider()
                
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 16) {
                        VStack {
                            // First Name
                            HStack {
                                Text("first.name".localized)
                                    .font(CustomFont.font(.medium))
                                Spacer()
                                Text(getFirstName())
                                    .font(CustomFont.font(.medium))
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            .padding()
                            
                            Divider().padding(.leading, 40)
                            
                            // Last Name
                            HStack {
                                Text("last.name".localized)
                                    .font(CustomFont.font(.medium))
                                Spacer()
                                Text(getLastName())
                                    .font(CustomFont.font(.medium))
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            .padding()
                            
                            Divider().padding(.leading, 40)
                            
                            // Email
                            HStack {
                                Text("email".localized)
                                    .font(CustomFont.font(.medium))
                                Spacer()
                                Text(getEmail())
                                    .font(CustomFont.font(.medium))
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            .padding()
                        }
                        .background(Color("Light"))
                        .cornerRadius(10)
                        
                        // Delete Account Section
                        VStack(alignment: .leading) {
                            HStack{
                                Text("delete.account".localized)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color("Light"))
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
    
    // MARK: - Helper Methods
    
    private func getFirstName() -> String {
        guard let user = authManager.currentUser else {
            return "first.name.not.available".localized
        }
        
        // Parse first name from full name
        let nameComponents = user.name.components(separatedBy: " ")
        return nameComponents.first ?? "first.name.not.available".localized
    }
    
    private func getLastName() -> String {
        guard let user = authManager.currentUser else {
            return "last.name.not.available".localized
        }
        
        // Parse last name from full name
        let nameComponents = user.name.components(separatedBy: " ")
        if nameComponents.count > 1 {
            // Join all components except the first one as last name
            return nameComponents.dropFirst().joined(separator: " ")
        }
        return "last.name.not.available".localized
    }
    
    private func getEmail() -> String {
        guard let user = authManager.currentUser else {
            return "email.not.available".localized
        }
        
        return user.email.isEmpty ? "email.not.available".localized : user.email
    }
}

#Preview {
    AccountSettings()
        .environmentObject(AuthenticationManager.shared)
}
