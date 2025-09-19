import SwiftUI

struct AccountSettings: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthenticationManager
    
    // Delete account states
    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    
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
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            VStack(alignment: .leading) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.red)
                                    } else {
                                        Text("delete.account".localized)
                                            .foregroundColor(.red)
                                    }
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color("Light"))
                            .cornerRadius(10)
                        }
                        .disabled(authManager.isLoading)
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .confirmationDialog(
            "delete.account.confirmation.title".localized,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("delete.account.confirm".localized, role: .destructive) {
                handleDeleteAccount()
            }
            Button("cancel".localized, role: .cancel) { }
        } message: {
            Text("delete.account.confirmation.message".localized)
        }
        .alert("delete.account.error.title".localized, isPresented: $showDeleteError) {
            Button("ok".localized, role: .cancel) { }
        } message: {
            Text(deleteErrorMessage.isEmpty ? "delete.account.error.message".localized : deleteErrorMessage)
        }
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
    
    // MARK: - Delete Account Functionality
    
    private func handleDeleteAccount() {
        Task {
            await performDeleteAccount()
        }
    }
    
    @MainActor
    private func performDeleteAccount() async {
        do {
            await authManager.deleteAccount()
            
            // Check if deletion was successful by checking authentication state
            if !authManager.isAuthenticated {
                // Account deleted successfully - dismiss view and return to main screen
                presentationMode.wrappedValue.dismiss()
            } else if let errorMessage = authManager.errorMessage {
                // Show the specific error from AuthenticationManager
                showDeleteError(message: errorMessage)
            } else {
                // Fallback error if deletion didn't work but no specific error
                showDeleteError(message: nil)
            }
        }
    }
    
    private func showDeleteError(message: String?) {
        deleteErrorMessage = message ?? ""
        
        // Check if the error requires re-authentication
        if let message = message, message.contains("requires recent login") || message.contains("sign in again") {
            // Instead of showing re-auth dialog, sign out user and close screen
            handleReAuthenticationRequired()
        } else {
            showDeleteError = true
        }
    }
    
    private func handleReAuthenticationRequired() {
        // Sign out the user since re-authentication is required
        Task {
            authManager.signOut()
            
            // Close the account settings screen
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    AccountSettings()
        .environmentObject(AuthenticationManager.shared)
}
