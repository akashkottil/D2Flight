import SwiftUI

struct AnimatedResultLoader: View {
    @State private var animateClouds = false
    @State private var animatePlane = false
    @State private var flyAway = false
    @State private var currentTextIndex = 0
    @Binding var isVisible: Bool
    
    let messages = [
        "Searching for best price for your journey",
        "Scanning hundreds of airlines",
        "Finalizing your best deals"
    ]
    
    var body: some View {
        ZStack {
            // Full-screen background
            GradientColor.Primary
                .ignoresSafeArea(.all) // Ignore all safe areas for true full-screen
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    // Background clouds with better positioning
                    VStack(spacing: 60) {
                        HStack(spacing: 120) {
                            CloudView(offsetX: animateClouds ? -280 : 280, delay: 0, size: 60)
                            CloudView(offsetX: animateClouds ? 300 : -300, delay: 1.5, size: 45)
                        }
                        
                        HStack(spacing: 100) {
                            CloudView(offsetX: animateClouds ? 250 : -250, delay: 2.5, size: 55)
                            CloudView(offsetX: animateClouds ? -320 : 320, delay: 0.8, size: 40)
                        }
                        
                        HStack(spacing: 140) {
                            CloudView(offsetX: animateClouds ? -270 : 270, delay: 1.2, size: 50)
                            CloudView(offsetX: animateClouds ? 290 : -290, delay: 3, size: 35)
                        }
                    }
                    .opacity(0.6)
                    
                    // Main plane animation
                    Image("AnimatedFlyFlight")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .foregroundColor(.white)
                        .offset(
                            x: flyAway ? 600 : 0,
                            y: animatePlane ? -10 : 10
                        )
                        .animation(
                            flyAway ?
                                .easeIn(duration: 1) :
                                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: flyAway
                        )
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: animatePlane
                        )
                }
                .frame(height: 300)
                
                VStack(spacing: 12) {
                    Text("looking.for.best.deals".localized)
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
        // Start plane floating animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            animatePlane = true
        }
        
        // Start cloud animations with slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                animateClouds = true
            }
        }
        
        // Start text cycling
        loopTextAnimation()
        
        // Simulate loading complete after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            withAnimation(.easeIn(duration: 1)) {
                flyAway = true
            }
            
            // Hide the loader after plane flies away
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    isVisible = false
                }
            }
        }
    }
    
    private func resetAnimations() {
        animateClouds = false
        animatePlane = false
        flyAway = false
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

struct CloudView: View {
    let offsetX: CGFloat
    var delay: Double = 0
    var size: CGFloat = 50
    
    @State private var animate = false
    
    var body: some View {
        Image(systemName: "cloud.fill")
            .resizable()
            .frame(width: size, height: size * 0.6)
            .foregroundColor(.white.opacity(0.4))
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
    AnimatedResultLoader(isVisible: .constant(true))
}
