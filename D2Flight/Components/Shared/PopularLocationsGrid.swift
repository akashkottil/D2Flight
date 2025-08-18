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
    
    private let images: [MasonryImage] = [
        .init(imageName: "kochiImg", height: 250, isRemote: false, title: "kochi".localized, subtitle: "gods.own.country".localized, iataCode: "COK"),
        .init(imageName: "sydneyImg", height: 180, isRemote: false, title: "sydney".localized, subtitle: "harbor.city".localized, iataCode: "SYD"),
        .init(imageName: "milanImg", height: 210, isRemote: false, title: "milan".localized, subtitle: "fashion.capital".localized, iataCode: "MXP"),
        .init(imageName: "berlinImg", height: 250, isRemote: false, title: "berlin".localized, subtitle: "historic.germany".localized, iataCode: "BER"),
        .init(imageName: "riodeImg", height: 250, isRemote: false, title: "rio.de.janeiro".localized, subtitle: "city.of.samba".localized, iataCode: "GIG"),
        .init(imageName: "cairoImg", height: 220, isRemote: false, title: "cairo".localized, subtitle: "land.of.pyramids".localized, iataCode: "CAI"),
    ]


    
    var body: some View {
        VStack(alignment: .leading) {
            // Section Header
            HStack {
                Text(sectionTitle)
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .padding(.top)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // MasonryGrid with tap handling
            MasonryGrid(data: images, columns: numberOfColumns) { item in
                GeometryReader { geo in
                    let width = geo.size.width
                    let adjustedHeight = item.height * (width / 200)

                    Button(action: {
                        onLocationTapped(item)
                    }) {
                        ZStack {
                            // Background Image
                            Group {
                                if item.isRemote {
                                    AsyncImage(url: URL(string: item.imageName)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.3)
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
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(height: item.height)
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
