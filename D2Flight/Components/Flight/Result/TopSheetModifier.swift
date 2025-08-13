import SwiftUI

struct TopSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let maxHeightRatio: CGFloat?          // e.g. 0.6
    let sheetContent: () -> SheetContent

    @State private var contentHeight: CGFloat = 0
    @State private var showBackdrop: Bool = false     // controls dim layer
    @State private var showSheet: Bool = false        // controls slide in/out

    private let duration: Double = 0.32

    private var fallbackHeight: CGFloat {
        if let ratio = maxHeightRatio { return UIScreen.main.bounds.height * ratio }
        return UIScreen.main.bounds.height * 0.5
    }

    private var currentHeight: CGFloat {
        contentHeight > 0 ? contentHeight : fallbackHeight
    }

    private var offsetY: CGFloat {
        showSheet ? 0 : -(currentHeight + 1)
    }

    func body(content: Content) -> some View {
        ZStack {
            content

            // Keep overlay alive while animating out
            if isPresented || showBackdrop {
                // Backdrop (can keep a slight fade)
                Color.black.opacity(showBackdrop ? 0.4 : 0.0)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                // Top sheet container (slides down)
                VStack(spacing: 0) {
                    sheetContent()
                        .frame(maxHeight: maxHeightRatio.map { UIScreen.main.bounds.height * $0 })
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear { contentHeight = geo.size.height }
                                    .onChange(of: geo.size.height) { contentHeight = $0 }
                            }
                        )
                        .offset(y: offsetY) // 👉 slide, no opacity transition
                        .animation(.easeInOut(duration: duration), value: showSheet)

                    // Tap-through area to dismiss
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { dismiss() }
                }
                .ignoresSafeArea(.container, edges: .top)
                .onAppear { animateInIfNeeded() }
            }
        }
        // Keep this listener to react when parent toggles `isPresented`
        .onChange(of: isPresented) { newValue in
            if newValue {
                animateInIfNeeded()
            } else {
                dismiss() // animate out when parent sets false
            }
        }
    }

    // MARK: - Animations
    private func animateInIfNeeded() {
        guard !showBackdrop else { return }
        // 1) show backdrop immediately
        showBackdrop = true
        // 2) after one runloop, slide in the sheet
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: duration)) {
                showSheet = true
            }
        }
    }

    private func dismiss() {
        // 1) slide sheet up
        withAnimation(.easeInOut(duration: duration)) {
            showSheet = false
        }
        // 2) after slide completes, hide backdrop and notify parent (if needed)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showBackdrop = false
            }
            // ensure binding reflects closed state
            if isPresented { isPresented = false }
        }
    }
}

extension View {
    func topSheet<Content: View>(
        isPresented: Binding<Bool>,
        maxHeightRatio: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(TopSheetModifier(isPresented: isPresented,
                                  maxHeightRatio: maxHeightRatio,
                                  sheetContent: content))
    }
}
