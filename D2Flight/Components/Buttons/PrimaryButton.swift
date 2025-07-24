

import SwiftUI

struct PrimaryButton: View {
    var title: String
    var font: Font = CustomFont.font(.medium)
    var fontWeight: Font.Weight = .bold
    var textColor: Color = .white
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var verticalPadding: CGFloat = nil ?? 0
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
                .background(GradientColor.Secondary)
                .cornerRadius(cornerRadius)
        }
    }
}
