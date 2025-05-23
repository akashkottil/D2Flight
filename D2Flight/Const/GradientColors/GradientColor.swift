

import SwiftUI

struct GradientColor {
    
    static let Primary = LinearGradient(
        gradient: Gradient(colors: [
                    Color(hex: "#141738"),
                    Color(hex: "#121965")
                ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let Secondary = LinearGradient(
        gradient: Gradient(colors: [
                    Color(hex: "#FE6439"),
                    Color(hex: "#F92E12")
                ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let BlueWhite = LinearGradient(
        gradient: Gradient(colors: [
                    Color(hex: "#DACFFF"),
                    Color(hex: "#F8F5FF")
                ]),
        startPoint: .top,
        endPoint: .bottom
    )
}
