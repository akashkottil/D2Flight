import Foundation
struct MasonryImage: Identifiable, Equatable, Hashable {
    let id = UUID()
    let imageName: String
    let height: CGFloat
    let isRemote: Bool
    let title: String
    let subtitle: String?
    let iataCode: String
}
