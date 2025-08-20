import SwiftUI

struct AccountSettings: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("BlackArrow")
                            .padding(.horizontal)
                    }

                    Spacer()
                    
                    Text("account.settings".localized)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.trailing, 44) // To balance the left button spacing
                }
                .padding()
                Divider()
                
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 16) {
                        VStack {
                            // First Name
                            HStack {
                                Text("first.name".localized)
                                    .font(CustomFont.font(.medium))
                                Spacer()
                                Text("akash".localized)
                                    .font(CustomFont.font(.medium))
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            .padding()
                            
                            Divider().padding(.leading, 40)
                            
                            // Last Name
                            HStack {
                                Text("last.name".localized)
                                    .font(CustomFont.font(.medium))
                                Spacer()
                                Text("kottil".localized)
                                    .font(CustomFont.font(.medium))
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            .padding()
                            
                            Divider().padding(.leading, 40)
                            
                            // Email
                            HStack {
                                Text("email".localized)
                                    .font(CustomFont.font(.medium))
                                Spacer()
                                Text("kottilakash.gmail.com".localized)
                                    .font(CustomFont.font(.medium))
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            .padding()
                        }
                        .background(Color("Light"))
                        .cornerRadius(10)
                        
                        // Delete Account Section
                        VStack(alignment: .leading) {
                            HStack{
                                Text("delete.account".localized)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color("Light"))
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
}

#Preview {
    AccountSettings()
}
