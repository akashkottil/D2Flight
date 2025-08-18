//
//  UserDebugPanel.swift
//  D2Flight
//
//  Created by Akash Kottil on 30/07/25.
//


import SwiftUI

struct UserDebugPanel: View {
    @ObservedObject private var userManager = UserManager.shared
    @State private var showDebugInfo = false
    
    var body: some View {
        if showDebugInfo {
            VStack(alignment: .leading, spacing: 8) {
                Text("user.debug.info".localized)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("User ID: \(userManager.userId?.description ?? "nil")")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text("Session ID: \(userManager.currentSessionId?.description ?? "nil")")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text("Created: \(userManager.isUserCreated ? "Yes" : "No")")
                    .font(.caption)
                    .foregroundColor(.white)
                
                if let installDate = userManager.installDate {
                    Text("Installed: \(installDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                Button("Clear User Data") {
                    userManager.clearUserData()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            .padding(8)
            .background(Color.black.opacity(0.8))
            .cornerRadius(8)
            .transition(.opacity)
        }
        
        Button(action: {
            withAnimation {
                showDebugInfo.toggle()
            }
        }) {
            Image(systemName: "person.circle")
                .foregroundColor(.gray)
                .opacity(0.6)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}