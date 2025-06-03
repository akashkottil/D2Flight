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
            GradientColor.Primary
                    .ignoresSafeArea()
            VStack(spacing: 32) {
                ZStack {
                    // Clouds
                    HStack(spacing: 80) {
                        CloudView(offsetX: animateClouds ? -250 : 250)
                        CloudView(offsetX: animateClouds ? -300 : 300, delay: 2)
                        
                    }

                    VStack(spacing: 20) {
                        CloudView(offsetX: animateClouds ? -250 : 250)
                        CloudView(offsetX: animateClouds ? -300 : 300, delay: 2)
                        CloudView(offsetX: animateClouds ? -300 : 300, delay: 1)
                    }
                    // Plane
                    Image("AnimatedFlyFlight")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .foregroundColor(.white)
                        .offset(x: flyAway ? 600 : 0, y: animatePlane ? -10 : 10)
//                        .rotationEffect(.degrees(90))
                        .animation(flyAway ? .easeIn(duration: 1) : .easeInOut(duration: 1).repeatForever(autoreverses: true), value: flyAway)
                }

                VStack(spacing: 8) {
                    Text("Looking For Best Deals")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    Text(messages[currentTextIndex])
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .id(currentTextIndex)
                }
                .animation(.easeInOut(duration: 0.5), value: currentTextIndex)
            }
        }
        .onAppear {
            animatePlane = true
            animateClouds = true
            loopTextAnimation()

            // Simulate loading complete after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    flyAway = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isVisible = false
                }
            }
        }
    }

    // Auto-text switcher
    func loopTextAnimation() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
            currentTextIndex = (currentTextIndex + 1) % messages.count
            if !isVisible {
                timer.invalidate()
            }
        }
    }
}

struct CloudView: View {
    let offsetX: CGFloat
    var delay: Double = 0

    @State private var animate = false

    var body: some View {
        Image(systemName: "cloud.fill")
            .resizable()
            .frame(width: 50, height: 30)
            .foregroundColor(.white.opacity(0.3))
            .offset(x: animate ? offsetX : -offsetX)
            .onAppear {
                withAnimation(Animation.linear(duration: 6).delay(delay).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}


#Preview {
    AnimatedResultLoader(isVisible: .constant(true))
}
