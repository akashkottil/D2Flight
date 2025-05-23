import SwiftUI
struct FilterButton: View {
    let title: String
    var isSelected: Bool = false

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(isSelected ? Color("Violet") : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(20)
    }
}



#Preview {
    FilterButton(title: "Best", isSelected: true)
}
