//
//  BottomBarNavigator.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/7/24.
//

import SwiftUI

struct BottomBarNavigator: View {
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
    @EnvironmentObject var userAccountModel: UserAccountModel
    @EnvironmentObject var themeManager: ThemeManager
    let tabColor = Color("thirdColor")
    
    var body: some View {
        TabView {
            HomeScreenView(userAccountModel: UserAccountModel(authManager: AuthManager()))
                .tabItem {
                    Label("Home", systemImage: "house")
                        .foregroundColor(themeManager.theme.thirdColor)
                }
            
            SearchScreenView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                        .foregroundColor(themeManager.theme.thirdColor)
                }
            
            AddItem()
                .tabItem {
                    Label("Add Item", systemImage: "plus")
                        .foregroundColor(themeManager.theme.thirdColor)
                }
            
            SwappedView()
                .tabItem {
                    Label("Swaps", systemImage: "rectangle.2.swap")
                        .foregroundColor(themeManager.theme.thirdColor)
                }
            
            CurrentUserItemsView()
                .tabItem {
                    Label("Account", systemImage: "list.clipboard")
                        .foregroundColor(themeManager.theme.thirdColor)
                }
        }
        .accentColor(Color(themeManager.theme.mainColor))
    }
}

//#Preview {
//    // Pass a valid instance of `UserAccountModel` in the preview
//    BottomBarNavigator()
//        .environmentObject(UserAccountModel(authManager: AuthManager()))
//        .environmentObject(ItemManager())
//}
