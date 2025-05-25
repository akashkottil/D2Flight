import SwiftUI

struct ResultHeader: View {
@Environment(\.dismiss) private var dismiss
    var body: some View {
        
        HStack{
            Button(action: {
dismiss() // Navigate back to previous screen
}) {
Image("BlackArrow")
    .padding(.trailing, 10)
}
            VStack(alignment: .leading) {
                
                Text("KCH to LON")
                    .font(.system(size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Text("Wed 17 Oct, 1 Traveler, 1 Economy")
                    .font(.system(size: 12))
                    .fontWeight(.light)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing){
                Image("EditIcon")
                    .frame(width: 14,height: 14)
                Text("Edit")
                    .font(.system(size: 12))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            }
        }
//        .padding(.horizontal)
        
        VStack(alignment: .leading, spacing: 8) {

            

            // Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                
                HStack(spacing: 12) {
                    HStack{
                        Image("SortIcon")
                        Text("Sort: Best")
                    }.font(.system(size: 12, weight: .semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background( Color.gray.opacity(0.1))
                        .foregroundColor( .gray)
                        .cornerRadius(20)
                    FilterButton(title: "Stops", isSelected: true)
                    FilterButton(title: "Time")
                    FilterButton(title: "Airlines")
                    FilterButton(title: "Bags")
                }
            }
        }
    }
}

#Preview {
    ResultHeader()
}




//import SwiftUI
//
//struct ResultHeader: View {
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        
//        HStack{
//            Button(action: {
//                dismiss() // Navigate back to previous screen
//            }) {
//                Image("BlackArrow")
//                    .padding(.trailing, 10)
//            }
//            
//            VStack(alignment: .leading) {
//                Text("KCH to LON")
//                    .font(.system(size: 14))
//                    .fontWeight(.semibold)
//                    .foregroundColor(.black)
//                Text("Wed 17 Oct, 1 Traveler, 1 Economy")
//                    .font(.system(size: 12))
//                    .fontWeight(.light)
//                    .foregroundColor(.gray)
//            }
//            Spacer()
//            VStack(alignment: .trailing){
//                Image("EditIcon")
//                    .frame(width: 14,height: 14)
//                Text("Edit")
//                    .font(.system(size: 12))
//                    .fontWeight(.semibold)
//                    .foregroundColor(.black)
//            }
//        }
////        .padding(.horizontal)
//        
//        VStack(alignment: .leading, spacing: 8) {
//
//            
//
//            // Filter Buttons
//            ScrollView(.horizontal, showsIndicators: false) {
//                
//                HStack(spacing: 12) {
//                    HStack{
//                        Image("SortIcon")
//                        Text("Sort: Best")
//                    }.font(.system(size: 12, weight: .semibold))
//                        .padding(.vertical, 8)
//                        .padding(.horizontal, 16)
//                        .background( Color.gray.opacity(0.1))
//                        .foregroundColor( .gray)
//                        .cornerRadius(20)
//                    FilterButton(title: "Stops", isSelected: true)
//                    FilterButton(title: "Time")
//                    FilterButton(title: "Airlines")
//                    FilterButton(title: "Bags")
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    ResultHeader()
//}
