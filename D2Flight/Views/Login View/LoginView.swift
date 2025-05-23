
import SwiftUI

struct LoginView : View {
    var body: some View {
        
        VStack{
            HStack(){
                Spacer()
                Image(systemName: "multiply")
                    .foregroundColor(.white)
                    .font(.system(size: 24))
            }
            .padding()
            Image("LoginFlight")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading){
                Text("Let's find  great deals for you!")
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Sign in to save up to 50% when you book a flight last minute and anytime 😊.")
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding()
            .foregroundColor(.white)
            Spacer()
            VStack{
                
                SignInButton(text: "Continue with Facebook", imageName: "GoogleIcon") {
                    print("Google Sign In tapped")
                }
                
                SignInButton(text: "Continue with Facebook", imageName: "FacebookIcon") {
                    print("Continue with Facebook")
                }
            }
            
            Text("By creating or logging into an account you’re agreeing with our **Terms and conditions** and **Privacy policy**")
                .foregroundColor(.gray)
                .padding(.vertical)
                
            
            
        }
        .frame(maxWidth: .infinity)
        .background(GradientColor.Primary)
    }
}


#Preview {
    LoginView()
}
