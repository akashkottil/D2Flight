import SwiftUI

struct CardData {
    let title: String
    let subtitle: String
    let iconName: String
    let backgroundImageName: String
}

struct AutoSlidingCardsView: View {
    @State private var currentIndex: CGFloat = 0
    @State private var timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    @State private var dragOffset: CGFloat = 0
    
    let cards = [
        CardData(
            title: "Why Last Minute Flights ?",
            subtitle: "Easily handle all your flight bookings in one simple place.",
            iconName: "airplane",
            backgroundImageName: "flight_bg"
        ),
        CardData(
            title: "Book Smart, Travel Easy",
            subtitle: "Find the best deals and compare prices instantly.",
            iconName: "star.fill",
            backgroundImageName: "travel_bg"
        ),
        CardData(
            title: "24/7 Customer Support",
            subtitle: "We're here to help you every step of your journey.",
            iconName: "phone.fill",
            backgroundImageName: "support_bg"
        )
    ]
    
    // Duplicate the array for infinite effect
    private var infiniteCards: [CardData] {
        return cards + cards + cards
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom page indicator
            HStack(spacing: 8) {
                Text(cards[Int(currentIndex) % cards.count].title)
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                Spacer()
                ForEach(0..<cards.count, id: \.self) { index in
                    Circle()
                        .fill(index == Int(currentIndex) % cards.count ? Color.red : Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == Int(currentIndex) % cards.count ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 10)

            // Main card container with infinite scroll
            GeometryReader { geometry in
                let cardWidth = geometry.size.width - 60
                let spacing: CGFloat = 20
                let totalWidth = cardWidth + spacing
                
                HStack(spacing: spacing) {
                    ForEach(0..<infiniteCards.count, id: \.self) { index in
                        CardView(card: infiniteCards[index])
                            .frame(width: cardWidth)
                    }
                }
                .offset(x: -(currentIndex * totalWidth) + dragOffset)
                .animation(.easeInOut(duration: 0.5), value: currentIndex)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width > 0 {
                                dragOffset = min(value.translation.width, 100)
                            }
                        }
                        .onEnded { value in
                            dragOffset = 0
                            if value.translation.width > 100 && currentIndex > 0 {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentIndex -= 1
                                }
                                resetTimer()
                            } else if value.translation.width < -100 && currentIndex < CGFloat(infiniteCards.count - 1) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentIndex += 1
                                }
                                resetTimer()
                            }
                        }
                )
                .onAppear {
                    // Start from the middle set to allow smooth infinite scrolling
                    currentIndex = CGFloat(cards.count)
                }
            }
            .frame(height: 200)
            .clipped()
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentIndex += 1
                }
                
                // Reset position when we've moved too far to maintain infinite effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if currentIndex >= CGFloat(cards.count * 2) {
                        // Reset to the first card without animation (to avoid reverse scrolling)
                        currentIndex = CGFloat(cards.count)
                    }
                }
            }
        }
        .padding(.leading, 10)
    }
    
    private func resetTimer() {
        timer.upstream.connect().cancel()
        timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    }
}

struct CardView: View {
    let card: CardData
    
    var body: some View {
        ZStack {
            // Background with gradient overlay
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.7),
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Airplane wing image overlay (simulated)
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Image(systemName: "airplane")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.2))
                        .rotationEffect(.degrees(45))
                        .offset(x: 20, y: 20)
                }
            }
            
            // Content
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    // Icon circle
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: card.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text(card.subtitle)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding(.leading, 24)
                .padding(.vertical, 24)
                
                Spacer()
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
