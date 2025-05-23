//
//  ProfileView.swift
//  M2-Flight-Ios
//
//  Created by Akash Kottill on 21/05/25.
//

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
