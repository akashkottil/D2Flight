import SwiftUI

// MARK: - HOTEL LOADER
struct AnimatedHotelLoader: View {
    // === Customize here ===
    var hotelAssetName: String = "HotelIcon"           // your asset in Assets.xcassets
    // Fallback to SF Symbol if asset not found: "building.2.crop.circle.fill"
    var hotelSize: CGSize = .init(width: 140, height: 140)

    // (Motion/Exit props kept for API compatibility but unused)
    var bobAmplitudeY: CGFloat = 12
    var swayAmplitudeX: CGFloat = 10
    var floatDuration: Double = 1.8
    var wobbleDegrees: Double = 3.5
    var checkOutDistanceY: CGFloat = 520
    var checkOutDuration: Double = 0.8

    // Clouds
    var cloudColor: Color = .white.opacity(0.42)
    var cloudOpacity: Double = 0.75
    /// base speed: higher = slower (we reuse it with multipliers for parallax)
    var baseCloudSpeed: Double = 11.0

    // Text
    let messages = [
        "searching.best.hotels.for.your.stay".localized,
        "checking.availability.and.reviews".localized,
        "locking.in.top.deals.for.you".localized
    ]

    // Visibility bridge (same as your flight loader)
    @Binding var isVisible: Bool

    // State
    @State private var animateClouds = false
    @State private var currentTextIndex = 0

    var body: some View {
        ZStack {
            // Background: keep your app gradient
            GradientColor.Primary
                .ignoresSafeArea(.all)

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    // CLOUD LAYERS (parallax + diagonal drift)
                    VStack(spacing: 56) {
                        HStack(spacing: 120) {
                            HotelCloudView(
                                startOffset: .init(width: -260, height: -40),
                                endOffset:   .init(width: 260,  height: 40),
                                animate: animateClouds,
                                delay: 0.0,
                                size: 70,
                                color: cloudColor,
                                duration: baseCloudSpeed * 0.9
                            )
                            HotelCloudView(
                                startOffset: .init(width: 300, height: -30),
                                endOffset:   .init(width: -300, height: 30),
                                animate: animateClouds,
                                delay: 1.1,
                                size: 48,
                                color: cloudColor.opacity(0.9),
                                duration: baseCloudSpeed * 1.15
                            )
                        }

                        HStack(spacing: 100) {
                            HotelCloudView(
                                startOffset: .init(width: -230, height: 35),
                                endOffset: .init(width: 230, height: -35),
                                animate: animateClouds,
                                delay: 0.6,
                                size: 60,
                                color: cloudColor,
                                duration: baseCloudSpeed
                            )
                            HotelCloudView(
                                startOffset: .init(width: 320, height: 20),
                                endOffset: .init(width: -320, height: -20),
                                animate: animateClouds,
                                delay: 2.0,
                                size: 42,
                                color: cloudColor,
                                duration: baseCloudSpeed * 1.25
                            )
                        }

                        HStack(spacing: 140) {
                            HotelCloudView(
                                startOffset: .init(width: -280, height: 10),
                                endOffset: .init(width: 280, height: -10),
                                animate: animateClouds,
                                delay: 1.5,
                                size: 54,
                                color: cloudColor.opacity(0.85),
                                duration: baseCloudSpeed * 0.95
                            )
                            HotelCloudView(
                                startOffset: .init(width: 290, height: -18),
                                endOffset: .init(width: -290, height: 18),
                                animate: animateClouds,
                                delay: 2.6,
                                size: 36,
                                color: cloudColor,
                                duration: baseCloudSpeed * 1.05
                            )
                        }
                    }
                    .opacity(cloudOpacity)

                    // HOTEL ICON (static, centered, no animation)
                    hotelImage
                        .frame(width: hotelSize.width, height: hotelSize.height)
                        .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
                }
                .frame(height: 300)

                // TEXT
                VStack(spacing: 10) {
                    Text("looking.for.best.hotel.deals".localized)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)

                    Text(messages[currentTextIndex])
                        .font(CustomFont.font(.medium))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .id(currentTextIndex)
                        .animation(.easeInOut(duration: 0.45), value: currentTextIndex)
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .onAppear { startAnimations() }
        .onDisappear { resetAnimations() }
    }

    // MARK: - Image (asset or SF Symbol fallback)
    @ViewBuilder
    private var hotelImage: some View {
        if UIImage(named: hotelAssetName) != nil {
            Image(systemName: "building.2.crop.circle.fill") // fallback if asset not found
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
        } else {
            Image(systemName: "building.2.crop.circle.fill") // fallback if asset not found
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
        }
    }

    // MARK: - Animations (clouds + text only; hotel is static)
    private func startAnimations() {
        // Clouds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.linear(duration: baseCloudSpeed).repeatForever(autoreverses: false)) {
                animateClouds = true
            }
        }

        // Text cycle
        loopTextAnimation()

        // Simulated completion → hide after same total delay as before
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.2 + 0.12 + 0.25) {
            withAnimation(.easeOut(duration: 0.35)) {
                isVisible = false
            }
        }
    }

    private func resetAnimations() {
        animateClouds = false
        currentTextIndex = 0
    }

    private func loopTextAnimation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if isVisible {
                withAnimation(.easeInOut(duration: 0.45)) {
                    currentTextIndex = (currentTextIndex + 1) % messages.count
                }
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Parallax diagonal cloud
struct HotelCloudView: View {
    let startOffset: CGSize
    let endOffset: CGSize
    let animate: Bool
    var delay: Double = 0.0
    var size: CGFloat = 56
    var color: Color = .white.opacity(0.4)
    var duration: Double = 11.0

    @State private var running = false

    var body: some View {
        Image(systemName: "cloud.fill")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size * 0.65)
            .foregroundColor(color)
            .offset(running ? endOffset : startOffset)
            .onAppear {
                guard animate else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(Animation.linear(duration: duration).repeatForever(autoreverses: true)) {
                        running = true
                    }
                }
            }
            .onDisappear { running = false }
    }
}

#Preview {
    // Try different assets or SF Symbol fallback
    AnimatedHotelLoader(hotelAssetName: "building.2.crop.circle.fill",
                        isVisible: .constant(true))
}
