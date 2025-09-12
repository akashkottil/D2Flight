//
//  TrackableScrollView.swift
//  D2Flight
//
//  Created by Akash Kottil on 12/09/25.
//


import SwiftUI
import UIKit

// UIKit-backed TrackableScrollView (unchanged from demo)
struct TrackableScrollView<Content: View>: View {
    let showsIndicators: Bool
    let content: Content
    @Binding var offsetY: CGFloat

    init(showsIndicators: Bool = true,
         offsetY: Binding<CGFloat>,
         @ViewBuilder content: () -> Content) {
        self._offsetY = offsetY
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    var body: some View {
        Representable(showsIndicators: showsIndicators, offsetY: $offsetY, content: content)
    }

    private struct Representable<Content: View>: UIViewRepresentable {
        let showsIndicators: Bool
        @Binding var offsetY: CGFloat
        let content: Content

        func makeCoordinator() -> Coordinator { Coordinator(self) }

        func makeUIView(context: Context) -> UIScrollView {
            let scroll = UIScrollView()
            scroll.alwaysBounceVertical = true
            scroll.showsVerticalScrollIndicator = showsIndicators
            scroll.delegate = context.coordinator

            let host = UIHostingController(rootView: VStack(spacing: 0) { content })
            host.view.translatesAutoresizingMaskIntoConstraints = false
            host.view.backgroundColor = .clear

            scroll.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
                host.view.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
                host.view.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
            ])
            return scroll
        }

        func updateUIView(_ uiView: UIScrollView, context: Context) {}

        class Coordinator: NSObject, UIScrollViewDelegate {
            var parent: Representable
            init(_ parent: Representable) { self.parent = parent }
            func scrollViewDidScroll(_ scrollView: UIScrollView) {
                parent.offsetY = max(scrollView.contentOffset.y, 0)
            }
        }
    }
}

// Visual blur used by the sticky header
struct VisualEffectBlur: View {
    var body: some View {
        #if os(iOS)
        Rectangle().fill(.ultraThinMaterial)
        #else
        Rectangle().fill(.regularMaterial)
        #endif
    }
}

// Linear interpolation
@inline(__always)
func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
