//
//  BottomBarNavigator.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/7/24.
//

import SwiftUI

struct BottomBarNavigator: View {
    @EnvironmentObject var userAccountModel: UserAccountModel
    let tabColor = Color("thirdColor")
    
    var body: some View {
        TabView {
            HomeScreenView(userAccountModel: UserAccountModel(authManager: AuthManager()))
                .tabItem {
                    Label("Home", systemImage: "house")
                        .foregroundColor(tabColor)
                }
            
            SearchScreenView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                        .foregroundColor(tabColor)
                }
            
            AddItem()
                .tabItem {
                    Label("Add Item", systemImage: "plus")
                        .foregroundColor(tabColor)
                }
            
            SwappedView()
                .tabItem {
                    Label("Swaps", systemImage: "rectangle.2.swap")
                        .foregroundColor(tabColor)
                }
            
            CurrentUserItemsView()
                .tabItem {
                    Label("Account", systemImage: "list.clipboard")
                        .foregroundColor(tabColor)
                }
        }
        .accentColor(Color("mainColor"))
    }
}

#Preview {
    // Pass a valid instance of `UserAccountModel` in the preview
    BottomBarNavigator()
        .environmentObject(UserAccountModel(authManager: AuthManager()))
        .environmentObject(ItemManager())
}
