//
//  SignInButton.swift
//  D2Flight
//
//  Created by Akash Kottill on 23/05/25.
//

import SwiftUI

struct SignInButton: View {
    var text: String
    var imageName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(imageName)
                    .resizable()
                    .frame(width: 20, height: 20)
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(width: 340, height: 56)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}
