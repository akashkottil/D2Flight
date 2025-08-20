import SwiftUI

struct CardData {
    let title: String
    let subtitle: String
    let iconName: String
    let backgroundImageName: String
    let iconImage : String
}

struct AutoSlidingCardsView: View {
    @State private var currentIndex: CGFloat = 0
    @State private var timer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    @State private var dragOffset: CGFloat = 0
    
    let cards = [
        CardData(
            title: "why.last.minute.flights".localized,
            subtitle: "compare.flights.from.various.airlines.to.find.the.best.prices".localized,
            iconName: "airplane",
            backgroundImageName: "slide1",
            iconImage: "priceHand"
        ),
        CardData(
            title: "book.smart.travel.easy".localized,
            subtitle: "save.money.by.comparing.affordable.flights.from.top.airlines.quickly".localized,
            iconName: "star.fill",
            backgroundImageName: "slide2",
            iconImage: "calendarTime"
        ),
        CardData(
            title: "247.customer.support".localized,
            subtitle: "find.flights.instantly.then.book.directly.with.your.chosen.provider".localized,
            iconName: "phone.fill",
            backgroundImageName: "slide3",
            iconImage: "tickets"
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
            
            RoundedRectangle(cornerRadius: 20)
            Image(card.backgroundImageName)
                    .resizable()
//                    .scaledToFill()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            
            
            
            // Content
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    // Icon circle
                    ZStack {
                        
                        Image(card.iconImage)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 8) {

                        
                        Text(card.subtitle)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                .padding(.leading, 14)
                .padding(.vertical, 24)
                
                Spacer()
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}


struct AutoSlidingCardsView_Previews: PreviewProvider {
    static var previews: some View {
        AutoSlidingCardsView()
    }
}
