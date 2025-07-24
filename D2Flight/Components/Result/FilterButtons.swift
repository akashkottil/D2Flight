import SwiftUI

struct FilterButton: View {
    let title: String
    var isSelected: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            action?()
        }) {
            Text(title)
                .font(CustomFont.font(.small, weight: .semibold))
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color("Violet") : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(20)
        }
    }
}

// MARK: - Alternative FilterButton for legacy usage without actions
struct StaticFilterButton: View {
    let title: String
    var isSelected: Bool = false

    var body: some View {
        Text(title)
            .font(CustomFont.font(.small, weight: .semibold))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? Color("Violet") : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(20)
    }
}

