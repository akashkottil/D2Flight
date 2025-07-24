//
//  MasonryVStack.swift
//  D2Flight
//
//  Created by Akash Kottil on 09/07/25.
//

import SwiftUI

public struct MasonryVStack: Layout {

    private var columns: Int
    private var spacing: Double

    public init(columns: Int = 2, spacing: Double = 8.0) {
        self.columns = columns
        self.spacing = spacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        return calculateSize(for: subviews, in: proposal)
    }
    
    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        calculateSize(for: subviews, in: proposal, placeInBounds: bounds)
    }

    @discardableResult
    private func calculateSize(
        for subviews: Subviews,
        in proposal: ProposedViewSize,
        placeInBounds bounds: CGRect? = nil
    ) -> CGSize {
        guard let maxWidth = proposal.width else { return .zero }
        let itemWidth = (maxWidth - spacing * Double(columns - 1)) / Double(columns)

        var xIndex: Int = 0
        var columnsHeights: [Double] = Array(repeating: bounds?.minY ?? 0, count: columns)

        subviews.forEach { view in
            let proposed = ProposedViewSize(
                width: itemWidth,
                height: view.sizeThatFits(.unspecified).height
            )

            if let bounds {
                let x = (itemWidth + spacing) * Double(xIndex) + bounds.minX
                view.place(
                    at: .init(x: x, y: columnsHeights[xIndex]),
                    anchor: .topLeading,
                    proposal: proposed
                )
            }

            let height = view.dimensions(in: proposed).height
            columnsHeights[xIndex] += height + spacing
            let minimum = columnsHeights.enumerated().min {
                $0.element < $1.element
            }?.offset ?? 0
            xIndex = minimum
        }

        guard let maxHeight = columnsHeights.max() else { return .zero }

        return .init(
            width: maxWidth,
            height: maxHeight - spacing
        )
    }

    public static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .vertical
        return properties
    }
}

// MARK: - Sample Data
struct ImageData: Identifiable {
    let id = UUID()
    let imageName: String
    let height: CGFloat
    let caption: String
}

// MARK: - Preview Content View
struct MasonryImageView: View {
    let imageData: ImageData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Using SF Symbols for demo - replace with actual images
            Image(systemName: imageData.imageName)
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: imageData.height)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
            
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Main Content View
struct ContentView: View {
    let sampleImages: [ImageData] = [
        ImageData(imageName: "photo.artframe", height: 120, caption: "Beautiful landscape with mountains"),
        ImageData(imageName: "camera.fill", height: 80, caption: "Photography"),
        ImageData(imageName: "paintbrush.fill", height: 150, caption: "Digital art creation tools"),
        ImageData(imageName: "music.note", height: 100, caption: "Music note"),
        ImageData(imageName: "book.fill", height: 130, caption: "Reading collection"),
        ImageData(imageName: "gamecontroller.fill", height: 90, caption: "Gaming"),
        ImageData(imageName: "airplane", height: 110, caption: "Travel adventures"),
        ImageData(imageName: "leaf.fill", height: 140, caption: "Nature and environment"),
        ImageData(imageName: "heart.fill", height: 95, caption: "Favorite items"),
        ImageData(imageName: "star.fill", height: 125, caption: "Featured content"),
        ImageData(imageName: "moon.fill", height: 85, caption: "Night mode"),
        ImageData(imageName: "sun.max.fill", height: 115, caption: "Bright and sunny day")
    ]
    
    var body: some View {
        ScrollView {
            MasonryVStack(columns: 2, spacing: 16) {
                ForEach(sampleImages) { imageData in
                    MasonryImageView(imageData: imageData)
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Masonry Layout")
        .background(Color.gray.opacity(0.05))
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContentView()
        }
    }
}
