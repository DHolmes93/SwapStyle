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
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    
    var unreadMessageCount: Int = 0 {
        didSet {
            // Update the app's badge with the number of unread messages
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = self.unreadMessageCount
            }
        }
    }
    
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
    
    // MARK: - Schedule Message Notification
    func scheduleMessageNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Message"
        content.body = message
        content.sound = .default
        content.userInfo = ["type": "message"]
        
        // Update unread message count
        unreadMessageCount += 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully.")
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
        
        // Check the notification type and handle accordingly
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "message":
                // Handle messaging notification in foreground
                print("Received a message notification in foreground")
                // Optionally, navigate to the messaging screen
            case "swapRequest":
                // Handle swap request notification in foreground
                print("Received a swap request notification in foreground")
                // Optionally, navigate to the swap screen
            default:
                break
            }
        }
        
        // Customize which notifications to show while the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: - Background/Action Notification Handling
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("User tapped on notification with userInfo: \(userInfo)")
        
        // Handle the notification action based on the type
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "message":
                // Handle message notification action (e.g., open the messaging screen)
                print("User tapped on message notification")
                // Optionally, navigate to the message thread
            case "swapRequest":
                // Handle swap request notification action (e.g., open the swap request screen)
                print("User tapped on swap request notification")
                // Optionally, navigate to the swap request screen
            default:
                break
            }
        }
        
        completionHandler()
    }
}

// MARK: - AppDelegate
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var profileItem: ProfileData?
    var userSession: UserSession?

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
        Messaging.messaging().delegate = NotificationManager.shared as? any MessagingDelegate

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
