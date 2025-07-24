import SwiftUI

struct CustomFont {
    enum Size: CGFloat {
        case tiny = 10
        case small = 12
        case regular = 14
        case medium = 16
        case large = 18
        case title = 32
    }

    static func font(_ size: Size, weight: Font.Weight = .regular) -> Font {
        return .system(size: size.rawValue, weight: weight)
    }
}

