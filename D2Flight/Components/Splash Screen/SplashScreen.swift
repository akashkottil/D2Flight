import SwiftUI

struct SplashScreen: View {
    @State private var flightPosition = CGSize(width: -600, height: 800)
    @State private var rotationAngle: Double = -30
    @State private var bounce = false

    @State private var flyByPosition = CGSize(width: 400, height: -600)
    @State private var flyByOpacity = 1.0
    @State private var showFlyBy = true

    

    var body: some View {
        ZStack {
            GradientColor.SplashGradient
                .ignoresSafeArea()

            // 1. Fly-by animation (zoomed, fades out)
            if showFlyBy {
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 800, height: 800)
                    .rotationEffect(.degrees(180))
                    .offset(flyByPosition)
                    .opacity(flyByOpacity)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            flyByPosition = CGSize(width: -800, height: 800)
                            flyByOpacity = 0.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showFlyBy = false
                        }
                    }
            }

            // 2. Main logo flight animation to center + text
            if !showFlyBy {
                VStack(spacing: 20) {
                    Image("SplashLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(rotationAngle))
                        .offset(flightPosition)
                        .scaleEffect(bounce ? 1.2 : 1.0)
                        .animation(.interpolatingSpring(stiffness: 800, damping: 100), value: bounce)


                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        flightPosition = .zero
                        rotationAngle = 0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        bounce = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
}
