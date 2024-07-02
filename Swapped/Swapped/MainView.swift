//
//  MainView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//
import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            HomeScreenView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            SearchScreenView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            SwappedView()
                .tabItem {
                    Label("Deeds", systemImage: "heart")
                }
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person")
                }
            
        }
    }
}

#Preview {
    MainView()
}
