

import SwiftUI

struct ProfileView: View {
    
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false){
                    VStack {
                        SignInCard(isLoggedIn: $isLoggedIn)
                                            ProfileLists(isLoggedIn: $isLoggedIn)
                    }
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.inline) 
                }
            }
    }
        }

#Preview {
    ProfileView()
}
