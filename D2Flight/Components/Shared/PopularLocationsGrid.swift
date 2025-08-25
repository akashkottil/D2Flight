//
//  PopularLocationsGrid.swift
//  D2Flight
//
//  Created by Akash Kottil on 08/08/25.
//

import SwiftUI

struct PopularLocationsGrid: View {
    let searchType: SearchType
    let selectedDates: [Date]
    let adults: Int
    let children: Int
    let infants: Int
    let selectedClass: TravelClass
    let rooms: Int // For hotel only
    let onLocationTapped: (MasonryImage) -> Void
    
    @State private var numberOfColumns: Int = 2
    
    // Make images static to prevent recreation
    private static let staticImages: [MasonryImage] = [
        .init(imageName: "kochiImg", height: 250, isRemote: false, title: "kochi".localized, subtitle: "gods.own.country".localized, iataCode: "COK"),
        .init(imageName: "sydneyImg", height: 180, isRemote: false, title: "sydney".localized, subtitle: "harbor.city".localized, iataCode: "SYD"),
        .init(imageName: "milanImg", height: 210, isRemote: false, title: "milan".localized, subtitle: "fashion.capital".localized, iataCode: "MXP"),
        .init(imageName: "berlinImg", height: 250, isRemote: false, title: "berlin".localized, subtitle: "historic.germany".localized, iataCode: "BER"),
        .init(imageName: "riodeImg", height: 250, isRemote: false, title: "rio.de.janeiro".localized, subtitle: "city.of.samba".localized, iataCode: "GIG"),
        .init(imageName: "cairoImg", height: 220, isRemote: false, title: "cairo".localized, subtitle: "land.of.pyramids".localized, iataCode: "CAI"),
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            // Section Header - Add id for stability
            HStack {
                Text(sectionTitle)
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .padding(.top)
                Spacer()
            }
            .padding(.horizontal, 20)
            .id("section-header-\(searchType)")
            
            // MasonryGrid with tap handling
            MasonryGrid(data: Self.staticImages, columns: numberOfColumns) { item in
                PopularLocationCard(
                    item: item,
                    onTapped: onLocationTapped
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var sectionTitle: String {
        switch searchType {
        case .flight:
            return "popular.destinations".localized
        case .hotel:
            return "popular.hotels".localized
        case .rental:
            return "popular.car.rentals".localized
        }
    }
}

// Extract card into separate view for better performance
struct PopularLocationCard: View {
    let item: MasonryImage
    let onTapped: (MasonryImage) -> Void
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let adjustedHeight = item.height * (width / 200)

            Button(action: {
                onTapped(item)
            }) {
                ZStack {
                    // Background Image - Add id for stability
                    Group {
                        if item.isRemote {
                            AsyncImage(url: URL(string: item.imageName)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure(_):
                                    Color.gray.opacity(0.3)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        )
                                case .empty:
                                    Color.gray.opacity(0.3)
                                        .overlay(
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        )
                                @unknown default:
                                    Color.gray.opacity(0.3)
                                }
                            }
                        } else {
                            Image(item.imageName)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .frame(width: width, height: adjustedHeight)
                    .clipped()
                    .cornerRadius(10)
                    .id("image-\(item.imageName)")
                    
                    // Text Overlay
                    VStack {
                        Spacer()
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(CustomFont.font(.medium, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.7), radius: 2, x: 1, y: 1)
                                
                                if let subtitle = item.subtitle {
                                    Text(subtitle)
                                        .font(CustomFont.font(.small, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                        .shadow(color: .black.opacity(0.7), radius: 1, x: 1, y: 1)
                                }
                            }
                            .padding(.bottom)
                            Spacer()
                        }
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.4)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(12)
                    }
                    .cornerRadius(10)
                    .id("overlay-\(item.imageName)")
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(height: item.height)
        .id("card-\(item.imageName)")
    }
}

// MARK: - Additional Optimizations

// Only add these extensions if MasonryImage doesn't already conform to these protocols

// If MasonryImage doesn't conform to Equatable, add this
/*
extension MasonryImage: Equatable {
    static func == (lhs: MasonryImage, rhs: MasonryImage) -> Bool {
        return lhs.imageName == rhs.imageName &&
               lhs.height == rhs.height &&
               lhs.isRemote == rhs.isRemote &&
               lhs.title == rhs.title &&
               lhs.subtitle == rhs.subtitle &&
               lhs.iataCode == rhs.iataCode
    }
}

// Make MasonryImage hashable for better performance
extension MasonryImage: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(imageName)
        hasher.combine(height)
        hasher.combine(isRemote)
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(iataCode)
    }
}
*/
