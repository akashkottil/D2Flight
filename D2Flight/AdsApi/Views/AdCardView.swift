import SwiftUI

struct AdCard: View {
    let ad: AdResponse
    let onAdTapped: (() -> Void)?

    init(ad: AdResponse, onAdTapped: (() -> Void)? = nil) {
        self.ad = ad
        self.onAdTapped = onAdTapped
    }

    var body: some View {
        Button(action: handleAdTap) {
            // === Your original adCard design, unchanged visually ===
            VStack {
                HStack(alignment: .center) {
                    AsyncImage(url: URL(string: fullBackgroundImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image("cairoImg")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(0.6)
                    }
                    .frame(width: 70, height: 70)
                    .clipped()
                    .cornerRadius(10)

                    // Texts
                    VStack(alignment: .leading) {
                        Text(ad.headline)
                            .font(.system(size: 18))
                            .fontWeight(.semibold)
                            .lineLimit(2)

                        Text(ad.description)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .lineLimit(3)
                    }

                    // "ad" badge
                    VStack{
                        VStack {
                            Text("ad")
                                .fontWeight(.medium)
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.caption)
                            
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.white)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        )
                        Spacer()
                    }
                    
                }
            }
            .frame( height: 75)
            .padding(.vertical,10)
            .padding(.horizontal,10)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            // === end of your original visual ===
        }
        .buttonStyle(PlainButtonStyle()) // keep the card look when tappable
        .accessibilityLabel(Text("\(ad.companyName) ad: \(ad.headline)"))
    }
}

// MARK: - URL helpers (keep your relative path fixes)
private extension AdCard {
    var fullLogoUrl: String {
        if ad.logoUrl.starts(with: "/") { return "https://www.kayak.com\(ad.logoUrl)" }
        return ad.logoUrl
    }
    var fullBackgroundImageUrl: String {
        if ad.backgroundImageUrl.starts(with: "/") { return "https://www.kayak.com\(ad.backgroundImageUrl)" }
        return ad.backgroundImageUrl
    }
    var fullDeepLink: String {
        if ad.deepLink.starts(with: "/") { return "https://www.kayak.com\(ad.deepLink)" }
        return ad.deepLink
    }
}

// MARK: - Actions (ported from AdCardView)
private extension AdCard {
    func handleAdTap() {
        if !ad.impressionUrl.isEmpty { trackImpression() }
        openDeepLink()
        onAdTapped?()
    }

    func trackImpression() {
        let fullImpressionUrl: String =
            ad.impressionUrl.starts(with: "/")
            ? "https://www.kayak.com\(ad.impressionUrl)"
            : ad.impressionUrl

        guard let url = URL(string: fullImpressionUrl) else {
            print("🎯 Invalid impression URL: \(fullImpressionUrl)")
            return
        }
        Task {
            do {
                _ = try await URLSession.shared.data(from: url)
                print("🎯 Impression tracked for ad: \(ad.headline)")
            } catch {
                print("🎯 Failed to track impression: \(error)")
            }
        }
    }

    func openDeepLink() {
        guard let url = URL(string: fullDeepLink) else {
            print("🎯 Invalid deep link URL: \(fullDeepLink)")
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                if success {
                    print("🎯 Successfully opened deep link: \(fullDeepLink)")
                } else {
                    print("🎯 Failed to open deep link: \(fullDeepLink)")
                }
            }
        } else {
            print("🎯 Cannot open URL: \(fullDeepLink)")
        }
    }
}


struct AdCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AdCard(
                ad: AdResponse(
                    rank: 1,
                    backgroundImageUrl: "/rimg/trip-backgrounds/cairo.jpg",
                    impressionUrl: "/track/impression",
                    bookingButtonText: "Book Now",
                    productType: "flight",
                    headline: "Fly to Cairo for less",
                    site: "kayak",
                    companyName: "Kayak",
                    logoUrl: "/rimg/provider-logos/airlines/logo.png",
                    trackUrl: "/track/url",
                    deepLink: "/flights/cairo",
                    description: "Book your dream trip with exclusive discounts"
                )
            )
            .previewLayout(.sizeThatFits)
            .padding()

            AdCard(
                ad: AdResponse(
                    rank: 2,
                    backgroundImageUrl: "/rimg/trip-backgrounds/tokyo.jpg",
                    impressionUrl: "/track/impression",
                    bookingButtonText: "Explore Deals",
                    productType: "flight",
                    headline: "Discover Tokyo",
                    site: "kayak",
                    companyName: "Kayak",
                    logoUrl: "/rimg/provider-logos/airlines/logo.png",
                    trackUrl: "/track/url",
                    deepLink: "/flights/tokyo",
                    description: "Unforgettable experiences await in Japan"
                )
            )
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.dark)
        }
    }
}
