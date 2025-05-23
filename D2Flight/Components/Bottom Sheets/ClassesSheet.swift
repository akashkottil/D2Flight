//
//  ClassesSheet.swift
//  D2Flight
//
//  Created by Akash Kottill on 23/05/25.
//

import SwiftUI

struct ClassesSheet: View {
    var body: some View {
        VStack (spacing: 0){
            HStack {
                Text("Classes")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.bottom, 20)
            
            ScrollView{
                VStack{
                    classSelectionRow(title: "Economy")
                    classSelectionRow(title: "Premium Economy")
                    classSelectionRow(title: "Business")
                    classSelectionRow(title: "First Class")
                }
                .padding()
            }
        }
    }
}


private func classSelectionRow(title: String) -> some View {
    HStack {
        Circle()
            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            .frame(width: 20, height: 20)
        
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
    }
}

#Preview {
    ClassesSheet()
}
