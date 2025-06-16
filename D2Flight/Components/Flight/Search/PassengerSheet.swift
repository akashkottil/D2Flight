

import SwiftUI

struct PassengerSheet: View {
    @Binding var isPresented: Bool
    @Binding var adults: Int
    @Binding var children: Int
    @Binding var infants: Int
    @Binding var selectedClass: TravelClass
    @State private var childrenAges: [Int] = []
    
    var onDone: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Traveler and Class")
                    .font(CustomFont.font(.large, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(CustomFont.font(.large, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.bottom,20)
            
            ScrollView {
                VStack(spacing: 32) {
                    // Select Class Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Select Class")
                                .font(CustomFont.font(.regular, weight: .semibold))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        
                        VStack(spacing: 20) {
                            classSelectionRow(title: "Economy", class: .economy)
                            classSelectionRow(title: "Premium Economy", class: .premiumEconomy)
                            classSelectionRow(title: "Business", class: .business)
                            classSelectionRow(title: "First Class", class: .firstClass)
                        }
                    }
                    
                    // Select Travellers Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Select Travellers")
                                .font(CustomFont.font(.regular, weight: .semibold))
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        
                        VStack(spacing: 24) {
                            passengerCountRow(
                                title: "Adults",
                                subtitle: "Over 11",
                                count: $adults,
                                minCount: 1
                            )
                            
                            passengerCountRow(
                                title: "Children",
                                subtitle: "2-11",
                                count: $children,
                                minCount: 0
                            )
                            
                            passengerCountRow(
                                title: "Infants",
                                subtitle: "Under 2",
                                count: $infants,
                                minCount: 0
                            )
                        }
                    }
                    
                    // Select Children Age Section (only show if children > 0)
                    if children > 0 {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Select Children Age")
                                    .font(CustomFont.font(.regular, weight: .semibold))
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            
                            VStack(spacing: 16) {
                                ForEach(0..<children, id: \.self) { index in
                                    childAgeRow(childNumber: index + 1, age: getChildAge(for: index))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 100) // Space for apply button
            }
            
            
            Spacer()
            
            // Apply Button
            VStack{
                PrimaryButton(title: "Apply", font: CustomFont.font(.large), fontWeight: .semibold, textColor: .white, width: 543, height: 56, horizontalPadding: 24, cornerRadius: 16, action: {
                    let totalTravelers = adults + children + infants
                    let travelersText = "\(totalTravelers) Traveller\(totalTravelers > 1 ? "s" : ""), \(selectedClass.displayName)"
                    onDone(travelersText)
                    isPresented = false
                })
            }
            .padding()
            .padding(.bottom,24)
        }
        .onChange(of: children) {
            updateChildrenAges()
        }
    }
    
    private func classSelectionRow(title: String, class: TravelClass) -> some View {
        Button(action: {
            selectedClass = `class`
        }) {
            HStack {
                Text(title)
                    .font(CustomFont.font(.medium, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                ZStack {
                    if selectedClass == `class` {
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

            }
        }
    }
    
    private func passengerCountRow(
        title: String,
        subtitle: String,
        count: Binding<Int>,
        minCount: Int
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CustomFont.font(.regular, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(CustomFont.font(.small))
                    .foregroundColor(.gray)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    if count.wrappedValue > minCount {
                        count.wrappedValue -= 1
                    }
                }) {
                    Image(systemName: "minus")
                        .font(CustomFont.font(.medium, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(count.wrappedValue > minCount ? Color("Violet") : Color.gray.opacity(0.3))
                        )
                }
                .disabled(count.wrappedValue <= minCount)
                
                Text("\(count.wrappedValue)")
                    .font(CustomFont.font(.large, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(minWidth: 20)
                
                Button(action: {
                    if count.wrappedValue < 9 {
                        count.wrappedValue += 1
                    }
                }) {
                    Image(systemName: "plus")
                        .font(CustomFont.font(.medium, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(count.wrappedValue < 9 ? Color("Violet") : Color.gray.opacity(0.3))
                        )
                }
                .disabled(count.wrappedValue >= 9)
            }
        }
    }
    
    private func childAgeRow(childNumber: Int, age: Binding<Int>) -> some View {
        HStack {
            Text("Children \(childNumber)")
                .font(CustomFont.font(.regular, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer()
            
            Menu {
                ForEach(2...11, id: \.self) { ageOption in
                    Button("\(ageOption) years") {
                        age.wrappedValue = ageOption
                    }
                }
            } label: {
                HStack {
                    Text("\(age.wrappedValue) years")
                        .font(CustomFont.font(.medium))
                        .foregroundColor(.black)
                    
                    Image(systemName: "chevron.down")
                        .font(CustomFont.font(.small))
                        .foregroundColor(.gray)
                }
                
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(14)
            }
        }
    }
    
    private func updateChildrenAges() {
        while childrenAges.count < children {
            childrenAges.append(2) // Default age
        }
        while childrenAges.count > children {
            childrenAges.removeLast()
        }
    }
    
    private func getChildAge(for index: Int) -> Binding<Int> {
        return Binding(
            get: {
                guard index < childrenAges.count else { return 2 }
                return childrenAges[index]
            },
            set: { newValue in
                guard index < childrenAges.count else { return }
                childrenAges[index] = newValue
            }
        )
    }
}

enum TravelClass: String, CaseIterable {
    case economy = "Economy"
    case premiumEconomy = "Premium Economy"
    case business = "Business"
    case firstClass = "First Class"
    
    var displayName: String {
        switch self {
        case .economy:
            return "Economy"
        case .premiumEconomy:
            return "Premium Economy"
        case .business:
            return "Business"
        case .firstClass:
            return "First Class"
        }
    }
}

#Preview {
    PassengerSheet(
        isPresented: .constant(true),
        adults: .constant(1),
        children: .constant(2),
        infants: .constant(1),
        selectedClass: .constant(.business)
    ) { _ in }
}
