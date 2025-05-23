import SwiftUI

struct SecondaryButton: View {
    var title: String
    var font: Font = .system(size: 16)
    var fontWeight: Font.Weight = .bold
    var textColor: Color = .white
    var backgroundColor: Color = .gray.opacity(0.2)
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var verticalPadding: CGFloat = 0
    var horizontalPadding: CGFloat = 0
    var cornerRadius: CGFloat = 12
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .fontWeight(fontWeight)
                .foregroundColor(textColor)
                .frame(
                    maxWidth: width ?? .infinity,
                    maxHeight: height
                )
                .padding(.vertical, verticalPadding)
                .padding(.horizontal, horizontalPadding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundColor)
                )
        }
    }
}
