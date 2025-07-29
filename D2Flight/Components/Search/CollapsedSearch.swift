import SwiftUI

struct CollapsedSearch: View {
    var body: some View {
        VStack{
            HStack{
                Image("SearchIcon")
                    .frame(width:25, height: 25)
                VStack(alignment: .leading){
                    HStack{
                        Text("NYC-LHR")
                        Text("•")
                        Text("12 Jun")
                    }
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(Color.black)
                    HStack{
                        Text("1 Traveller,")
                        Text("Economy")
                    }
                    .font(.system(size: 14))
                    .fontWeight(.regular)
                    .foregroundColor(Color.gray)
                }
                Spacer()
                
                PrimaryButton(
                    title: "Search",
                    font: CustomFont.font(.medium),
                    fontWeight: .bold,
                    textColor: .white,
                    width: 120,  // Set width
                    verticalPadding: 20,  // Set verticalPadding
                    cornerRadius:10,
                    action: {
                        // Action here
                    }
                )


            }
        }
        .background(Color.white)
        .padding()
    }
}


#Preview {
    CollapsedSearch()
}
