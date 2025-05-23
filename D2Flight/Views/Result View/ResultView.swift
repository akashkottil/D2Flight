import SwiftUI

struct ResultView: View {
    var body: some View {
        ScrollView{
            ResultCard()
        }
        .padding()
        .background(.gray)
        
    }
       
}


#Preview {
    ResultView()
}
