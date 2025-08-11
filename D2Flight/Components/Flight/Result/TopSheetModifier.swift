//
//  TopSheetModifier.swift
//  D2Flight
//
//  Created by Akash Kottil on 11/08/25.
//


import SwiftUI

// MARK: - Top Sheet Presentation Modifier
struct TopSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let sheetContent: () -> SheetContent
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                // Background overlay
//                Color.black.opacity(0.3)
//                    .ignoresSafeArea()
//                    .transition(.opacity)
//                    .onTapGesture {
//                        withAnimation(.easeInOut(duration: 0.3)) {
//                            isPresented = false
//                        }
//                    }
                
                // Sheet content
                VStack {
                    sheetContent()
//                        .background(Color.white)
//                        .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
//                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
//                .ignoresSafeArea(.container, edges: .top)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

// MARK: - View Extension for Top Sheet
extension View {
    func topSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(TopSheetModifier(isPresented: isPresented, sheetContent: content))
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
