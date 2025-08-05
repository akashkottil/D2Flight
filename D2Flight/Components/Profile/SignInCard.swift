import SwiftUI

struct SignInCard: View {
    @Binding var isLoggedIn: Bool
    @State private var showLoginView = false
    
    var body: some View {
        VStack(alignment: .leading) {
            // Profile/Welcome Section
            HStack {
                if isLoggedIn {
                    Image("ProfileImg")
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Akash kottil")
                            .font(CustomFont.font(.medium, weight: .bold))
                        Text("kottilakash@gmail.com")
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
                if isLoggedIn {
                    // Account Settings Button
                    Button(action: {
                        // Handle account settings navigation
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
                    // Sign In Button - Now navigates to LoginView
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
        // Present LoginView as a full screen cover
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView(isLoggedIn: $isLoggedIn)
        }
    }
}
