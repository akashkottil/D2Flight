import SwiftUI

// MARK: - Improved Top Sheet Presentation Modifier
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
                
                // Sheet content - positioned at top half of screen
                VStack(spacing: 0) {
                    sheetContent()
                        .background(Color.clear)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    // Invisible spacer that also dismisses when tapped
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

// MARK: - View Extension for Top Sheet
extension View {
    func topSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(TopSheetModifier(isPresented: isPresented, sheetContent: content))
    }
}
