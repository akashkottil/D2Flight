import SwiftUI

struct Currency: View {
    @Environment(\.presentationMode) var presentationMode
    @State var selectedCurrency: Bool = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("BlackArrow")
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    Text("Select currency")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                    
                    Image("search")
                        .padding(.horizontal)
                }
                .padding(.vertical)
                
                Divider()
                
                // Scrollable Content
                ScrollView {
                   
                        HStack(spacing: 20){
                            Image("search")
                            
                            Text("Search currency")
                            Spacer()
                        }
                        .padding()
                        .background(.gray.opacity(0.2))
                        .cornerRadius(20)

                    
                    VStack(spacing: 16) {
                        // Example currency item
                        HStack (spacing:10) {
                            
                            
                            ZStack {
                                if selectedCurrency {
                                    Circle()
                                        .stroke(Color("Violet"), lineWidth: 6)
                                        .frame(width: 20, height: 20)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 16, height: 16)
                                } else {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                }
                            }
                            Text("US Dollar")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("USD")
                        }
                        .padding()
                        .onTapGesture {
                            selectedCurrency.toggle()
                        }
                    }

                }
                .padding()
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    Currency()
}
