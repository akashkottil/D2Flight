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
                    
                    Text("Account Settings")
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
                                Text("First Name")
                                    .font(CustomFont.font(.medium))
                                Spacer()
                                Text("Akash")
                                    .font(CustomFont.font(.medium))
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            .padding()
                            
                            Divider().padding(.leading, 40)
                            
                            // Last Name
                            HStack {
                                Text("Last Name")
                                    .font(CustomFont.font(.medium))
                                Spacer()
                                Text("Kottil")
                                    .font(CustomFont.font(.medium))
                                    .foregroundColor(.black.opacity(0.5))
                            }
                            .padding()
                            
                            Divider().padding(.leading, 40)
                            
                            // Email
                            HStack {
                                Text("Email")
                                    .font(CustomFont.font(.medium))
                                Spacer()
                                Text("kottilakash@gmail.com")
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
                                Text("Delete Account")
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
