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
    @EnvironmentObject var messageManager: MessageManager
    @EnvironmentObject var itemManager: ItemManager
    @EnvironmentObject var swapCaet: SwapCart
    let tabColor = Color("thirdColor")
    
    
    var body: some View {
        TabView {
            HomeScreenView(userAccountModel: UserAccountModel(authManager: AuthManager()))
                .environmentObject(MessageManager.shared)
                .environmentObject(SwapCart.shared)
                .environmentObject(NotificationManager.shared)
            
                .tabItem {
                    Label("Home", systemImage: "house")
                        .foregroundStyle(Color("thirdColor"))
                }
            
            SearchScreenView(itemManager: ItemManager.shared, swapCart: SwapCart.shared)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                        .foregroundStyle(Color("thirdColor"))
                }
            
            AddItem()
                .tabItem {
                    Label("Add Item", systemImage: "plus")
                        .foregroundStyle(Color("thirdColor"))
                }
            
            SwappedView()
                .tabItem {
                    Label("Swaps", systemImage: "rectangle.2.swap")
                        .foregroundStyle(Color("thirdColor"))
                }
            
            CurrentUserItemsView()
                .tabItem {
                    Label("Items", systemImage: "list.clipboard")
                        .foregroundStyle(Color("thirdColor"))
                }
        }
        .accentColor(Color("mainColor"))
    }
}

//#Preview {
//    // Pass a valid instance of `UserAccountModel` in the preview
//    BottomBarNavigator()
//        .environmentObject(UserAccountModel(authManager: AuthManager()))
//        .environmentObject(ItemManager())
//}
