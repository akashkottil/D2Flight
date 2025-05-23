import SwiftUI

struct ResultCard: View {
    var body: some View {
        VStack(spacing:20){
            HStack{
                VStack(spacing:20){
                    HStack(spacing:20){
                        VStack(alignment: .leading){
                            Text("18:50")
                                .font(.system(size: 14))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Text("COK")
                                .font(.system(size: 12))
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        VStack{
                            Text("2h 15m")
                                .font(.system(size: 11))
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            
                            Divider()
                                .padding(.horizontal)
                                .frame(width: 100)
                            
                            Text("1 Stop")
                                .font(.system(size: 11))
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading){
                            Text("18:50")
                                .font(.system(size: 14))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Text("COK")
                                .font(.system(size: 12))
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                    }
                    HStack(spacing:20){
                        VStack(alignment: .leading){
                            Text("18:50")
                                .font(.system(size: 14))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Text("COK")
                                .font(.system(size: 12))
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        VStack{
                            Text("2h 15m")
                                .font(.system(size: 11))
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            
                            Divider()
                                .padding(.horizontal)
                                .frame(width: 100)
                            
                            Text("1 Stop")
                                .font(.system(size: 11))
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading){
                            Text("18:50")
                                .font(.system(size: 14))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Text("COK")
                                .font(.system(size: 12))
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                    }
                }
                Spacer()
                                VStack{
                                    VStack(alignment: .trailing){
                                        Text("$234")
                                            .font(.system(size: 16))
                                            .fontWeight(.bold)
                                            .foregroundColor(Color("PriceGreen"))
                                        Text("per Adult")
                                            .font(.system(size: 12))
                                            .fontWeight(.light)
                                    }
                                }
            }
            .padding(.horizontal)
            Divider()
            HStack{
                HStack{
                    Image("AirlinesImg")
                        .frame(width: 21, height: 21)
                    Text("Indigo Airways")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.8))
                        .fontWeight(.light)
                }
                Spacer()
            }
            .padding(.leading)
        }
        .padding()
        .background(.white)
        .cornerRadius(16)
    }
    
}


#Preview {
    ResultCard()
}
