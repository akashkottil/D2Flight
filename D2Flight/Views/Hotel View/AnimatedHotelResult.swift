import SwiftUI

struct AnimatedHotelResult: View {
    @State private var animateCar = false
    @State private var carMoveAway = false
    @State private var currentTextIndex = 0
    @Binding var isVisible: Bool
    
    let messages = [
        "Finding the best route for your journey",
        "Checking road conditions",
        "Finalizing your best deals"
    ]
    
    var body: some View {
        ZStack {
            // Full-screen background (Gradient Color)
            GradientColor.Primary
                .ignoresSafeArea(.all) // Ignore all safe areas for true full-screen
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    // Background scene with trees and buildings
                    VStack(spacing: 60) {
                        HStack(spacing: 120) {
                            TreeView(offsetX: animateCar ? -280 : 280, delay: 0, size: 60)
                            BuildingView(offsetX: animateCar ? 300 : -300, delay: 1.5, size: 100)
                        }
                        
                        HStack(spacing: 100) {
                            TreeView(offsetX: animateCar ? 250 : -250, delay: 2.5, size: 70)
                            BuildingView(offsetX: animateCar ? -320 : 320, delay: 0.8, size: 120)
                        }
                        
                        HStack(spacing: 140) {
                            TreeView(offsetX: animateCar ? -270 : 270, delay: 1.2, size: 65)
                            BuildingView(offsetX: animateCar ? 290 : -290, delay: 3, size: 110)
                        }
                    }
                    .opacity(0.6)
                    
                    // Main car animation
                    Image("CarImage") // Replace with your car image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .foregroundColor(.white)
                        .offset(
                            x: carMoveAway ? 600 : 0,
                            y: animateCar ? -10 : 10
                        )
                        .animation(
                            carMoveAway ?
                                .easeIn(duration: 1) :
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: carMoveAway
                        )
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: animateCar
                        )
                }
                .frame(height: 300)
                
                VStack(spacing: 12) {
                    Text("looking.for.best.deals.2".localized)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(messages[currentTextIndex])
                        .font(CustomFont.font(.medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .id(currentTextIndex)
                        .animation(.easeInOut(duration: 0.5), value: currentTextIndex)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            // Reset states when view disappears
            resetAnimations()
        }
    }
    
    private func startAnimations() {
        // Start car moving animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            animateCar = true
        }
        
        // Start background objects (trees/buildings) animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                animateCar = true
            }
        }
        
        // Start text cycling
        loopTextAnimation()
        
        // Simulate loading complete after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            withAnimation(.easeIn(duration: 1)) {
                carMoveAway = true
            }
            
            // Hide the loader after car moves away
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    isVisible = false
                }
            }
        }
    }
    
    private func resetAnimations() {
        animateCar = false
        carMoveAway = false
        currentTextIndex = 0
    }
    
    // Auto-text switcher with timer management
    private func loopTextAnimation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if isVisible {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentTextIndex = (currentTextIndex + 1) % messages.count
                }
            } else {
                timer.invalidate()
            }
        }
    }
}

struct TreeView: View {
    let offsetX: CGFloat
    var delay: Double = 0
    var size: CGFloat = 50
    
    @State private var animate = false
    
    var body: some View {
        Image(systemName: "leaf.fill") // You can replace with a tree image
            .resizable()
            .frame(width: size, height: size)
            .foregroundColor(.green.opacity(0.4))
            .offset(x: animate ? offsetX : -offsetX)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(
                        Animation.linear(duration: 8)
                            .repeatForever(autoreverses: false)
                    ) {
                        animate = true
                    }
                }
            }
            .onDisappear {
                animate = false
            }
    }
}

struct BuildingView: View {
    let offsetX: CGFloat
    var delay: Double = 0
    var size: CGFloat = 50
    
    @State private var animate = false
    
    var body: some View {
        Image(systemName: "building.2.fill") // Replace with a building image
            .resizable()
            .frame(width: size, height: size * 1.2)
            .foregroundColor(.gray.opacity(0.4))
            .offset(x: animate ? offsetX : -offsetX)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(
                        Animation.linear(duration: 8)
                            .repeatForever(autoreverses: false)
                    ) {
                        animate = true
                    }
                }
            }
            .onDisappear {
                animate = false
            }
    }
}

#Preview {
    AnimatedHotelResult(isVisible: .constant(true))
}
