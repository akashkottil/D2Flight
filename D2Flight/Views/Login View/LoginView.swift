import SwiftUI

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isLoggedIn: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    
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
                Text("lets.find.great.deals.for.you".localized)
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("sign.in.to.save.up.to.50.when.you.book.a.flight.last.minute.and.anytime".localized)
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
                    text: "continue.with.google".localized,
                    imageName: "GoogleIcon"
                ) {
                    Task {
                        await authManager.signInWithGoogle()
                    }
                }
                
                // Apple Sign In Button
                SignInButton(
                    text: "continue.with.apple".localized,
                    imageName: "AppleIcon"
                ) {
                    Task {
                        await authManager.signInWithFacebook()
                    }
                }
                
                // Show loading indicator if authenticating
                if authManager.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("signing.in".localized)
                            .font(CustomFont.font(.medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 8)
                }
                
                // Show error message if authentication failed
                if let error = authManager.errorMessage {
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
                
                Text("yes.keep.me.informed.with.the.latest.updates.alerts.and.offers.through.email.and.push.notifications".localized)
                    .font(CustomFont.font(.small))
                    .foregroundColor(Color.white)
                    .padding(.leading, 8)
            }
            .padding(.horizontal, 30)
            .padding(.vertical)
            
            Text("by.creating.or.logging.into.an.account.youre.agreeing.with.our.terms.and.conditions.and.privacy.policy".localized)
                .foregroundColor(.gray)
                .padding(.vertical)
                .padding(.horizontal)
                .font(CustomFont.font(.small))
        }
        .frame(maxWidth: .infinity)
        .background(GradientColor.Primary)
        .onChange(of: authManager.isAuthenticated) { authenticated in
            if authenticated {
                isLoggedIn = true
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
