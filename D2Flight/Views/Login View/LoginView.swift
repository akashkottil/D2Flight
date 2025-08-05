import SwiftUI

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isLoggedIn: Bool
    
    // State for handling authentication
    @State private var isAuthenticating = false
    @State private var authError: String? = nil
    
    @State private var isChecked = false

    
    var body: some View {
        VStack {
            // Close button
            HStack {
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "multiply")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }
            }
            .padding()
            
            Image("LoginFlight")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading) {
                Text("Let's find great deals for you!")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Sign in to save up to 50% when you book a flight last minute and anytime 😊.")
                    .font(CustomFont.font(.medium))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding()
            .foregroundColor(.white)
            
            Spacer()
            
            VStack(spacing: 16) {
                // Google Sign In Button
                SignInButton(
                    text: "Continue with Google",
                    imageName: "GoogleIcon"
                ) {
                    handleGoogleSignIn()
                }
                
                // Facebook Sign In Button
                SignInButton(
                    text: "Continue with Facebook",
                    imageName: "FacebookIcon"
                ) {
                    handleFacebookSignIn()
                }
                
                // Show loading indicator if authenticating
                if isAuthenticating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Signing in...")
                            .font(CustomFont.font(.medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 8)
                }
                
                // Show error message if authentication failed
                if let error = authError {
                    Text(error)
                        .font(CustomFont.font(.small))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
            HStack(alignment: .center) {
                Button(action: {
                    isChecked.toggle()
                }) {
                    ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isChecked ? Color.red : Color.gray, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(isChecked ? Color.red : Color.clear)
                                    )

                                if isChecked {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                Text("Yes, keep me informed with the latest updates, alerts, and offers through email and push notifications")
                    .font(CustomFont.font(.small)) // replace with your custom font if needed
                    .foregroundColor(Color.white)
                    .padding(.leading, 8)
            }
            .padding(.horizontal,30)
            .padding(.vertical)
            
            
            Text("By creating or logging into an account you're agreeing with our **Terms and conditions** and **Privacy policy**")
                .foregroundColor(.gray)
                .padding(.vertical)
                .padding(.horizontal)
                .font(CustomFont.font(.small))
        }
        .frame(maxWidth: .infinity)
        .background(GradientColor.Primary)
    }
    
    // MARK: - Authentication Methods
    private func handleGoogleSignIn() {
        print("Google Sign In tapped")
        authenticateUser(provider: "Google")
    }
    
    private func handleFacebookSignIn() {
        print("Facebook Sign In tapped")
        authenticateUser(provider: "Facebook")
    }
    
    private func authenticateUser(provider: String) {
        isAuthenticating = true
        authError = nil
        
        // Simulate authentication process
        // Replace this with your actual authentication logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Simulate random success/failure for demo
            let authSuccess = Bool.random()
            
            if authSuccess {
                // Authentication successful
                print("✅ \(provider) authentication successful")
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoggedIn = true
                }
                presentationMode.wrappedValue.dismiss()
            } else {
                // Authentication failed
                print("❌ \(provider) authentication failed")
                authError = "Failed to sign in with \(provider). Please try again."
            }
            
            isAuthenticating = false
        }
        
        // TODO: Implement actual authentication logic here
        // This is where you would integrate with:
        // - Firebase Authentication
        // - Auth0
        // - Apple Sign In
        // - Your custom backend authentication
        //
        // Example integration points:
        // - Google: GoogleSignIn.signIn()
        // - Facebook: Facebook SDK login
        // - Apple: ASAuthorizationAppleIDProvider
        // - Custom: Your API calls
    }
}

// MARK: - Preview
#Preview {
    LoginView(isLoggedIn: .constant(false))
}
