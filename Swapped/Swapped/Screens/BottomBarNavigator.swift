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
                    Label("Account", systemImage: "list.clipboard")
                    
                }
         
        }
        .accentColor(Color("secondColor"))
        
       
    }
    
}
        
#Preview {
    BottomBarNavigator()
}

