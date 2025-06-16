import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = 0

    init() {
        // Set UITabBar appearance globally
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            
            FlightView()
                .tag(0)
                .tabItem {
                    Image(selectedTab == 0 ? "TabFlightActive" : "TabFlight")
                    Text("Flight")
                }

            RentalView()
                .tag(1)
                .tabItem {
                    Image(selectedTab == 1 ? "TabCarActive" : "TabCar")
                        
                    Text("Rental")
                }
            
//            HotelView()
//                .tag(2)
//                .tabItem {
//                    Image(selectedTab == 2 ? "TabHotelActive" : "TabHotel")
//                        
//                    Text("Hotel")
//                }
            
            
            
//            ExploreView()
//                .tag(3)
//                .tabItem {
//                    Image(selectedTab == 3 ? "TabExploreActive" : "TabExplore")
//                        
//                    Text("Explore")
//                }

            ProfileView()
                .tag(4)
                .tabItem {
                    Image(selectedTab == 4 ? "TabProfileActive" : "TabProfile")
                        
                    Text("Profile")
                }
        }
//        .accentColor(.tabActive)
    }
}

#Preview{
    RootTabView()
}
