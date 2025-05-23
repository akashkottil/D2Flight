//
//  SigninCard.swift
//  M2-Flight-Ios
//
//  Created by Akash Kottill on 21/05/25.
//

import SwiftUI

struct SignInCard: View {
    @Binding var isLoggedIn: Bool
    
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
                            .font(.system(size: 16, weight: .bold))
                        Text("kottilakash@gmail.com")
                            .font(.system(size: 12))
                            .fontWeight(.medium)
                            .foregroundColor(Color.gray)
                    }
                } else {
                    VStack(alignment: .leading) {
                        Text("More offers awaits you")
                            .font(.system(size: 16, weight: .bold))
                        Text("Sign up and access to our exclusive deals")
                            .font(.system(size: 12))
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
                                .font(.system(size: 16, weight: .medium))
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
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isLoggedIn = true
                        }
                    }) {
                        HStack {
                            Text("Sign in Now")
                                .font(.system(size: 16, weight: .medium))
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
    }
}


