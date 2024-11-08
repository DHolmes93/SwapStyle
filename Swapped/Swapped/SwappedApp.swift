//
//  SwappedApp.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//
import SwiftUI
import UIKit
import Firebase
import UserNotifications
import FirebaseMessaging
import FirebaseCore
import GoogleSignIn
import FirebaseAuth
import GooglePlaces

// MARK: - NotificationManager
class NotificationManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    static let shared = NotificationManager()
    
    // MARK: - Request Notification Authorization
    func requestNotificationAuthorization(application: UIApplication) {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("Failed to request authorization for notifications: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                if granted {
                    application.registerForRemoteNotifications()
                } else {
                    print("User denied notifications.")
                }
            }
        }
    }
    
    // MARK: - APNs Token Handling
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass the token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        print("APNs Token registered with Firebase.")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - Firebase Messaging Delegate: FCM Token Handling
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("FCM Token: \(fcmToken)")
        
        if let uid = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(uid)
            
            userRef.getDocument { document, error in
                if let document = document, document.exists {
                    let currentToken = document.data()?["fcmToken"] as? String
                    if currentToken != fcmToken {
                        userRef.setData(["fcmToken": fcmToken], merge: true) { error in
                            if let error = error {
                                print("Error updating FCM token in Firestore: \(error.localizedDescription)")
                            } else {
                                print("FCM token updated successfully in Firestore.")
                            }
                        }
                    }
                }
            }
        } else {
            print("User is not logged in. Cannot update FCM token.")
        }
    }
    
    // MARK: - Foreground Notification Handling
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Foreground notification received with userInfo: \(userInfo)")
        
        // Customize which notifications to show while the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: - Background/Action Notification Handling
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("User tapped on notification with userInfo: \(userInfo)")
        
        // Handle notification action based on userInfo if needed
        completionHandler()
    }
}

// MARK: - AppDelegate
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var profileItem: ProfileData?

//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        // Configure Firebase
//        
//        FirebaseApp.configure()
//
//        // Request Notification Authorization
//        NotificationManager.shared.requestNotificationAuthorization(application: application)
//
//        // Set Delegates for Notifications
//        UNUserNotificationCenter.current().delegate = NotificationManager.shared
//        Messaging.messaging().delegate = NotificationManager.shared
//
//        return true
//    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase with proper error handling
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        } else {
            print("Firebase is already configured.")
        }
        GMSPlacesClient.provideAPIKey("AIzaSyBKCMrXkHDRwh4UYdGt6YaQ3_kU190e6CI")
        
        // Request Notification Authorization
        NotificationManager.shared.requestNotificationAuthorization(application: application)
        
        // Set Delegates for Notifications
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        Messaging.messaging().delegate = NotificationManager.shared

        return true
    }

    // Handle URL callback from Google Sign-In
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
//        return GIDSignIn.sharedInstance.handle(url)
//    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        } else {
            print("Failed to handle Google Sign-In URL")
            return false
        }
    }


    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationManager.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationManager.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }
        print(userInfo)
        completionHandler(.newData)
    }
}


// MARK: - SwiftUI App
@main
struct JustSwap: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var swapCart = SwapCart.shared
    @StateObject private var categoryManager = CategoryManager.shared
    @StateObject private var itemManager = ItemManager.shared
    @StateObject private var viewModel = UserAccountModel.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var profile = Profile()
    @StateObject private var profileItem = ProfileData()


    // Integrate AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
            // Assign the profileItem instance to the AppDelegate
            appDelegate.profileItem = profileItem
        }

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(swapCart)
                .environmentObject(categoryManager)
                .environmentObject(itemManager)
                .environmentObject(locationManager)
                .environmentObject(viewModel)
                .environmentObject(profile)
                .environmentObject(profileItem)
        }
    }
}

