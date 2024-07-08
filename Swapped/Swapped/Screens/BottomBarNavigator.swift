//
//  BottomBarNavigator.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/7/24.
//

import SwiftUI

struct BottomBarNavigator: View {
    var body: some View {
        TabView {
            HomeScreenView()
                .tabItem {
                    Label("Home", systemImage: "house")}
            SearchScreenView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            AddItem()
                .tabItem {
                    Label("Add Item", systemImage: "plus")
                }
            SwappedView()
                .tabItem {
                    Label("Swaps", systemImage: "rectangle.2.swap")
                }
            CurrentUserItemsView()
                .tabItem {
                    Label("Account", systemImage: "person")
                }
        }
    }
}
        
#Preview {
    BottomBarNavigator()
}
//extension Color {
//    static let mainColor = Color("mainColor")
//    static let secondColor = Color("secondColor")
//    static let unselectedColor = Color("secondColor")
// 
//}
//
//init() {
//       let appearance = UITabBarAppearance()
//       appearance.configureWithOpaqueBackground()
//       appearance.backgroundColor = UIColor(named: "mainColor")
//    UITabBar.appearance().standardAppearance = appearance
//            UITabBar.appearance().scrollEdgeAppearance = appearance
//            UITabBar.appearance().tintColor = UIColor(named: "secondColor")
//            UITabBar.appearance().unselectedItemTintColor = UIColor(named: "secondColor")
//    Divider()
//        .background(Color("mainColor"))
//    let selectedColor = UIColor(named: "secondColor")
//    let unselectedColor = UIColor(named: "secondColor")
//    
//    UITabBar.appearance().tintColor = selectedColor
//    UITabBar.appearance().unselectedItemTintColor = unselectedColor
//}

//static let tabBarBackgroundColor = Color("mainColor")
//static let tabBarSelectedColor = Color("secondColor")
//static let tabBarUnselectedColor = Color("secondColor")
