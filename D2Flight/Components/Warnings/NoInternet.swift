import SwiftUI

struct NoInternet: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.black)
                .font(CustomFont.font(.medium))
            
            Text("No Internet connection. Try reconnecting")
                .font(CustomFont.font(.regular, weight: .medium))
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.yellow)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .onAppear {
            // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.prepare()
                generator.impactOccurred()
            
            // Auto dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isVisible = false
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            NoInternet(isVisible: .constant(true))
                .padding(.bottom, 100)
        }
    }
}
