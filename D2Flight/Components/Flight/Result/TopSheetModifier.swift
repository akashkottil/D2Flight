import SwiftUI

// MARK: - Enhanced Top Sheet Presentation Modifier with Dynamic Height
struct TopSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let sheetContent: () -> SheetContent
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                // Background overlay with tap to dismiss
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
                
                // Sheet content with dynamic height
                VStack(spacing: 0) {
                    // Content with dynamic sizing
                    sheetContent()
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ContentHeightPreferenceKey.self,
                                    value: geometry.size.height
                                )
                            }
                        )
                        .background(Color.clear)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    // Spacer that captures taps to dismiss
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }
                }
                .ignoresSafeArea(.container, edges: .top)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
    }
}

// MARK: - Preference Key for Content Height
struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
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
