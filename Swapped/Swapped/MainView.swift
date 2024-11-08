//
//  MainView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
import SwiftUI

struct MainView: View {
    @EnvironmentObject var userAccountModel: UserAccountModel
    
    var body: some View {
        BottomBarNavigator()
    }
}

#Preview {
    // Ensure that you provide an environment object for the preview
    MainView()
        .environmentObject(UserAccountModel(authManager: AuthManager()))  // Pass the model as an environment object
}
