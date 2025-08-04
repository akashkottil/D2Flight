//
//  ScrollDetectionModifier.swift
//  D2Flight
//
//  Created by Akash Kottil on 29/07/25.
//


// Add this extension to detect scroll behavior and auto-collapse
// File: D2Flight/Extensions/ScrollViewExtension.swift (NEW FILE)

import SwiftUI

struct ScrollDetectionModifier: ViewModifier {
    let onScrollUp: () -> Void
    let onScrollDown: () -> Void
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                // Detect scroll direction based on offset changes
                // You can implement scroll direction detection here
            }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func detectScroll(onScrollUp: @escaping () -> Void, onScrollDown: @escaping () -> Void) -> some View {
        modifier(ScrollDetectionModifier(onScrollUp: onScrollUp, onScrollDown: onScrollDown))
    }
}