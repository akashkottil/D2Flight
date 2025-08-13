import SwiftUI

// MARK: - Ad Card View Component (Updated to use AdResponseModel)
struct AdCardView: View {
    let ad: AdResponseModel
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Ad indicator
            HStack {
                Text("Sponsored")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Ad content
            Button(action: {
                onTap()
                // Open the ad URL
                if let url = URL(string: ad.deepLink) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 16) {
                    // Ad image
                    AsyncImage(url: URL(string: ad.backgroundImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Ad text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ad.headline)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .lineLimit(2)
                        
                        Text(ad.description)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(3)
                        
                        HStack {
                            Text(ad.companyName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color("Violet"))
                            
                            Spacer()
                            
                            // Action button
                            Text(ad.bookingButtonText)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color("Violet"))
                                .cornerRadius(16)
                        }
                        .padding(.top, 4)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Violet").opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    let sampleAd = AdResponseModel(
        rank: 1,
        backgroundImageUrl: "https://example.com/hotel-image.jpg",
        impressionUrl: "https://example.com/impression",
        bookingButtonText: "Book Now",
        productType: "hotel",
        headline: "Book Hotels with 50% Off",
        site: "TravelDeals.com",
        companyName: "TravelDeals.com",
        logoUrl: "https://example.com/logo.jpg",
        trackUrl: "https://example.com/track",
        deepLink: "https://example.com/hotel-deals",
        description: "Find the best deals on hotels worldwide. Limited time offer for new users."
    )
    
    VStack(spacing: 16) {
        AdCardView(ad: sampleAd) {
            print("Ad tapped")
        }
        
        // Show next to a flight card for comparison
        Text("Flight results would appear here")
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
