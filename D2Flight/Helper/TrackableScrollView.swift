//
//  TrackableScrollView.swift
//  D2Flight
//
//  Created by Akash Kottil on 12/09/25.
//


import SwiftUI
import UIKit

struct TrackableScrollView<Content: View>: View {
    let showsIndicators: Bool
    let content: Content
    @Binding var offsetY: CGFloat
    @Binding var scrollView: UIScrollView?  // New binding to scroll view

    init(showsIndicators: Bool = true,
         offsetY: Binding<CGFloat>,
         scrollView: Binding<UIScrollView?>,  // Pass the scroll view reference here
         @ViewBuilder content: () -> Content) {
        self._offsetY = offsetY
        self.showsIndicators = showsIndicators
        self.content = content()
        self._scrollView = scrollView
    }

    var body: some View {
        Representable(showsIndicators: showsIndicators, offsetY: $offsetY, scrollView: $scrollView, content: content)
    }

    private struct Representable<Content: View>: UIViewRepresentable {
        let showsIndicators: Bool
        @Binding var offsetY: CGFloat
        @Binding var scrollView: UIScrollView?  // Add binding for scrollView
        let content: Content

        func makeCoordinator() -> Coordinator { Coordinator(self) }

        func makeUIView(context: Context) -> UIScrollView {
            let scroll = UIScrollView()
            self.scrollView = scroll  // Assign the scroll view reference here
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
