//
//  SwappedApp.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//

import SwiftUI
import UIKit
import Firebase
import CoreLocation



class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) ->
    Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct SwappedApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var swapCart = SwapCart.shared
    @StateObject private var categoryManager = CategoryManager.shared
    @StateObject private var itemManager = ItemManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var viewModel = UserAccountModel()
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
    var body: some Scene {
        WindowGroup {
            ContentView()
                    .environmentObject(authManager)
                    .environmentObject(swapCart)
                    .environmentObject(categoryManager)
                    .environmentObject(itemManager)
                    .environmentObject(locationManager)
                    .environmentObject(viewModel)
        }
    }
}

