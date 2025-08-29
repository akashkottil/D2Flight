//
//  AnimatedDotsText.swift
//  D2Flight
//
//  Created by Akash Kottil on 25/08/25.
//
import SwiftUI

// Reusable animated dots text
struct AnimatedDotsText: View {
    let text: String
    let interval: TimeInterval
    let maxDots: Int
    var color: Color = Color("Violet")
    var font: Font = CustomFont.font(.small, weight: .semibold)

    @State private var dotCount: Int = 0

    var body: some View {
        Text("\(text)\(String(repeating: ".", count: dotCount))")
            .font(font)
            .foregroundColor(color)
            .monospaced() // keeps width stable while dots change
            .onReceive(Timer.publish(every: interval, on: .main, in: .common).autoconnect()) { _ in
                dotCount = (dotCount + 1) % (maxDots + 1)
            }
            .accessibilityLabel(Text("\(text)"))
    }
}


#Preview("Light") {
    AnimatedDotsText(
        text: "Searching flights",
        interval: 0.5,
        maxDots: 3
        // color and font use your defaults: Color("Violet") & CustomFont...
    )
    .padding()
    .previewLayout(.sizeThatFits)
}
