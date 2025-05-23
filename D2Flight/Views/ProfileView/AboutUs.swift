//
//  AboutUs.swift
//  M2-Flight-Ios
//
//  Created by Akash Kottill on 21/05/25.
//

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
                    
                    Text("About Us")
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
                        Text("Last Minute Flights")
                            .font(.system(size: 18, weight: .bold))
                        Text("Version: 1.02")
                            .font(.system(size: 15))
                            .fontWeight(.light)
                            .foregroundColor(Color.black.opacity(0.5))
                    }
                    VStack(spacing:16){
                        Text("Welcome to our flight price comparison app! We know that planning a trip can be stressful, especially when it comes to finding the best deals on flights. That's where we come in. Our app makes it easy for you to compare prices from multiple airlines, so you can find the best option for your budget and schedule.")
                            .multilineTextAlignment(.center)
                            .font(.system(size: 18))
                            .fontWeight(.light)
                        Text("Our team is passionate about helping travelers save money and have a great trip. We are constantly updating our app with the latest deals and features to make your search even easier. With our user-friendly interface and reliable price comparisons, you can book your next flight with confidence.")
                            .multilineTextAlignment(.center)
                            .font(.system(size: 18))
                            .fontWeight(.light)
                        Text("Thank you for choosing our app. We hope you have a wonderful journey!")
                            .multilineTextAlignment(.center)
                            .font(.system(size: 18))
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
