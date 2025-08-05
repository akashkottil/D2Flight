import SwiftUI

struct SignInCard: View {
    @Binding var isLoggedIn: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showLoginView = false
    
    var body: some View {
        VStack(alignment: .leading) {
            // Profile/Welcome Section
            HStack {
                if authManager.isAuthenticated, let user = authManager.currentUser {
                    // User profile image or placeholder
                    AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image("ProfileImg")
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(user.name)
                            .font(CustomFont.font(.medium, weight: .bold))
                        Text(user.email)
                            .font(CustomFont.font(.small))
                            .fontWeight(.medium)
                            .foregroundColor(Color.gray)
                    }
                } else {
                    VStack(alignment: .leading) {
                        Text("More offers awaits you")
                            .font(CustomFont.font(.medium, weight: .bold))
                        Text("Sign up and access to our exclusive deals")
                            .font(CustomFont.font(.small))
                            .fontWeight(.medium)
                            .foregroundColor(Color.gray)
                    }
                }
            }
            .padding()
            .foregroundColor(Color.white)
            
            // Action Button Section
            VStack {
                if authManager.isAuthenticated {
                    // Account Settings Button
                    Button(action: {
                        print("Navigate to Account Settings")
                    }) {
                        HStack {
                            Text("Account Settings")
                                .font(CustomFont.font(.medium, weight: .medium))
                            Spacer()
                            Image("RedArrow")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.0))
                        .foregroundColor(.white)
                    }
                } else {
                    // Sign In Button
                    Button(action: {
                        showLoginView = true
                    }) {
                        HStack {
                            Text("Sign in Now")
                                .font(CustomFont.font(.medium, weight: .medium))
                            Spacer()
                            Image("WhiteArrow")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("Violet"))
                        .foregroundColor(.white)
                    }
                }
            }
            .foregroundColor(Color.white)
        }
        .background(GradientColor.Primary)
        .cornerRadius(16)
        .padding()
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView(isLoggedIn: $isLoggedIn)
                .environmentObject(authManager)
        }
        .onReceive(authManager.$isAuthenticated) { authenticated in
            isLoggedIn = authenticated
        }
    }
}
