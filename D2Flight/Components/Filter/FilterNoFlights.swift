import SwiftUI

struct FilterNoFlights: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("NoFlightsImg") // You can replace with your no flights image
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 150)
            
            VStack(spacing: 8) {
                Text("No flights found")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                
                Text("Try adjusting your filters or search criteria to find more flights.")
                    .font(CustomFont.font(.regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}

#Preview {
    FilterNoFlights()
}
