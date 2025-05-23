////
////  Color+Hex.swift.swift
////  M2-Flight-Ios
////
////  Created by Akash Kottill on 21/05/25.
////
//
//import SwiftUI
//
//extension Color {
//    init(hex: String) {
//        let scanner = Scanner(string: hex)
//        _ = scanner.scanString("#") // Skip the # if present
//
//        var rgb: UInt64 = 0
//        scanner.scanHexInt64(&rgb)
//
//        let r = Double((rgb >> 16) & 0xFF) / 255
//        let g = Double((rgb >> 8) & 0xFF) / 255
//        let b = Double(rgb & 0xFF) / 255
//
//        self.init(red: r, green: g, blue: b)
//    }
//}


//
//  Color+Hex.swift
//  M2-Flight-Ios
//
//  Created by Akash Kottill on 21/05/25.
//  Updated for calendar customization support
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b, a: Double
        switch hex.count {
        case 6:
            (r, g, b, a) = (
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255,
                1.0
            )
        case 8:
            (r, g, b, a) = (
                Double((int >> 24) & 0xFF) / 255,
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255
            )
        default:
            (r, g, b, a) = (1, 1, 1, 1) // default to white on error
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
