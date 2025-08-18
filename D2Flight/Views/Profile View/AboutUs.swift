
import SwiftUI

struct AboutUs : View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationStack{
            VStack(){
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("BlackArrow")
                            .padding(.horizontal)
                    }

                    Spacer()
                    
                    Text("about.us".localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.trailing, 44)
                }
                .padding()
                Divider()
//                MARK: about
                ScrollView{
                    VStack(){
                        Image("AboutLogo")
                            .frame(width: 60, height: 60)
                        Text("last.minute.flights".localized)
                            .font(CustomFont.font(.large, weight: .bold))
                        Text("version.1.02".localized)
                            .font(.system(size: 15))
                            .fontWeight(.light)
                            .foregroundColor(Color.black.opacity(0.5))
                    }
                    VStack(spacing:16){
                        Text("welcome.to.our.flight.price.comparison.app.we.know.that.plan".localized)
                            .multilineTextAlignment(.center)
                            .font(CustomFont.font(.large))
                            .fontWeight(.light)
                        Text("our.team.is.passionate.about.helping.travelers.save.money.an".localized)
                            .multilineTextAlignment(.center)
                            .font(CustomFont.font(.large))
                            .fontWeight(.light)
                        Text("thank.you.for.choosing.our.app.we.hope.you.have.a.wonderful".localized)
                            .multilineTextAlignment(.center)
                            .font(CustomFont.font(.large))
                            .fontWeight(.light)
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    Image("AboutImg")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
            }
            .padding(.horizontal,0)
            .padding(.bottom,0)
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
}


#Preview {
    AboutUs()
}
