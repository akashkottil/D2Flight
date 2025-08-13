import SwiftUI

// MARK: - Ad Response Model (should match your actual API response)
struct AdResponse: Codable, Identifiable {
    let id: String
    let headline: String
    let description: String
    let companyName: String
    let imageUrl: String?
    let actionUrl: String
    let buttonText: String?
    
    enum CodingKeys: String, CodingKey {
        case id, headline, description, companyName, imageUrl, actionUrl, buttonText
    }
}

// MARK: - Ad Card View Component
struct AdCardView: View {
    let ad: AdResponse
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
                if let url = URL(string: ad.actionUrl) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 16) {
                    // Ad image
                    AsyncImage(url: URL(string: ad.imageUrl ?? "")) { image in
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
                            Text(ad.buttonText ?? "Learn More")
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
    let sampleAd = AdResponse(
        id: "ad_1",
        headline: "Book Hotels with 50% Off",
        description: "Find the best deals on hotels worldwide. Limited time offer for new users.",
        companyName: "TravelDeals.com",
        imageUrl: "https://example.com/hotel-image.jpg",
        actionUrl: "https://example.com/hotel-deals",
        buttonText: "Book Now"
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
