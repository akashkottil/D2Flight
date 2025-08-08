import Foundation

struct MasonryImage: Identifiable {
    let id = UUID()
    let imageName: String
    let height: CGFloat
    let isRemote: Bool
    let title: String        // Main title text
    let subtitle: String?    // Optional subtitle text
}
