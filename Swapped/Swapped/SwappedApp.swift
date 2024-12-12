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
/// Comprehensive Notification Management System
class NotificationManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate, ObservableObject {
    /// Singleton instance for app-wide notification management
    static let shared = NotificationManager()
    
    @Published var unreadMessageCount: Int = 0 // New property to track unread messages
    @Published var unreadSwapRequestCount: Int = 0 // Add this property

    
    /// Tracked notifications
    @Published var notifications: [AppNotification] = []
    
    /// Detailed notification tracking
    @Published private(set) var notificationCounts: [NotificationType: Int] = [
        .message: 0,
        .swapRequest: 0,
        .profileUpdate: 0,
        .systemAlert: 0
    ]
    
    /// Combined total notification count
    @Published private(set) var totalNotificationCount: Int = 0 {
        didSet {
            // Update app icon badge number
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = self.totalNotificationCount
            }
        }
    }
    
    /// Private initializer to enforce singleton pattern
    private override init() {
        super.init()
        setupNotificationHandling()
    }
    
    func updateUnreadSwapRequestCount(count: Int) { // Add a method to update the count
          DispatchQueue.main.async {
              self.unreadSwapRequestCount = count
          }
      }
    func updateUnreadMessageCount(count: Int) {
          DispatchQueue.main.async {
              self.unreadMessageCount = count
          }
      }
    /// Setup initial notification handling configurations
    private func setupNotificationHandling() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    
    /// Add a new notification to the system
    /// - Parameter notification: The AppNotification to be added
    func addNotification(_ notification: AppNotification) {
        // Append to notifications array
        notifications.append(notification)
        
        // Increment count for specific notification type
        notificationCounts[notification.type, default: 0] += 1
        
        // Recalculate total notification count
        updateTotalNotificationCount()
        
        // Broadcast system-wide notification
        NotificationCenter.default.postAppNotification(notification)
        
        // Schedule local notification
        scheduleLocalNotification(for: notification)
        
        // Limit stored notifications
        trimNotifications()
    }
    
    /// Update total notification count
    private func updateTotalNotificationCount() {
        totalNotificationCount = notificationCounts.values.reduce(0, +)
    }
    
    /// Limit number of stored notifications
    private func trimNotifications(limit: Int = 100) {
        if notifications.count > limit {
            notifications.removeFirst(notifications.count - limit)
        }
    }
    
    /// Schedule a local notification for a given AppNotification
    private func scheduleLocalNotification(for notification: AppNotification) {
        let content = UNMutableNotificationContent()
        content.title = titleForNotificationType(notification.type)
        content.body = bodyForNotification(notification)
        content.sound = .default
        
        // Create trigger (immediate in this case)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create notification request
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )
        
        // Add to notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Generate title for different notification types
    private func titleForNotificationType(_ type: NotificationType) -> String {
        switch type {
        case .message: return "New Message"
        case .swapRequest: return "Swap Request"
        case .profileUpdate: return "Profile Update"
        case .systemAlert: return "System Notification"
        }
    }
    
    /// Generate body text for a notification
    private func bodyForNotification(_ notification: AppNotification) -> String {
        switch notification.type {
        case .message:
            return notification.message ?? "You have a new message"
        case .swapRequest:
            return "\(notification.fromUserName) wants to swap an item"
        case .profileUpdate:
            return "Your profile has been updated"
        case .systemAlert:
            return notification.message ?? "System notification received"
        }
    }
    
    /// Clear notifications of a specific type
    func clearNotifications(ofType type: NotificationType) {
        // Remove notifications of specific type
        notifications.removeAll { $0.type == type }
        
        // Reset count for that type
        notificationCounts[type] = 0
        
        // Recalculate total count
        updateTotalNotificationCount()
    }
    
    /// Clear all notifications
    func clearAllNotifications() {
        notifications.removeAll()
        notificationCounts = notificationCounts.mapValues { _ in 0 }
        totalNotificationCount = 0
    }
    /// Listen to Firestore for swap request notifications
       func startListeningForSwapRequests(userId: String) {
           let db = Firestore.firestore()
           let swapRequestsRef = db.collection("users").document(userId).collection("swapRequests")
           
           swapRequestsRef.addSnapshotListener { [weak self] snapshot, error in
               guard let self = self else { return }
               if let error = error {
                   print("Error fetching swap requests: \(error.localizedDescription)")
                   return
               }
               
               guard let documents = snapshot?.documents else {
                   print("No swap requests found.")
                   return
               }
               
               let newSwapRequests = documents.compactMap { document -> AppNotification? in
                   let data = document.data()
                   return self.createNotification(from: data, type: .swapRequest)
               }
               
               DispatchQueue.main.async {
                   self.notifications.append(contentsOf: newSwapRequests)
                   self.unreadSwapRequestCount += newSwapRequests.count
                   self.updateTotalNotificationCount()
                   
                   newSwapRequests.forEach { self.scheduleLocalNotification(for: $0) }
               }
           }
       }
       
       /// Listen to Firestore for message notifications
       func startListeningForMessages(userId: String) {
           let db = Firestore.firestore()
           let messagesRef = db.collection("users").document(userId).collection("messages")
           
           messagesRef.addSnapshotListener { [weak self] snapshot, error in
               guard let self = self else { return }
               if let error = error {
                   print("Error fetching messages: \(error.localizedDescription)")
                   return
               }
               
               guard let documents = snapshot?.documents else {
                   print("No messages found.")
                   return
               }
               
               let newMessages = documents.compactMap { document -> AppNotification? in
                   let data = document.data()
                   return self.createNotification(from: data, type: .message)
               }
               
               DispatchQueue.main.async {
                   self.notifications.append(contentsOf: newMessages)
                   self.unreadMessageCount += newMessages.count
                   self.updateTotalNotificationCount()
                   
                   newMessages.forEach { self.scheduleLocalNotification(for: $0) }
               }
           }
       }
       
       /// Helper to create AppNotification from Firestore data
       private func createNotification(from data: [String: Any], type: NotificationType) -> AppNotification? {
           guard
               let fromUserId = data["fromUserId"] as? String,
               let fromUserName = data["fromUserName"] as? String,
               let timestamp = data["timestamp"] as? Timestamp
           else {
               print("Invalid notification data.")
               return nil
           }
           
           let message = data["message"] as? String
           return AppNotification(
               type: type,
               fromUserId: fromUserId,
               fromUserName: fromUserName,
               message: message,
               timestamp: timestamp.dateValue()
           )
       }
    
    func scheduleSwapRequestNotification(fromUserName: String, itemName: String) {
          let content = UNMutableNotificationContent()
          content.title = "New Swap Request"
          content.body = "\(fromUserName) has requested a swap for your item: \(itemName)"
          content.sound = .default

          let request = UNNotificationRequest(
              identifier: UUID().uuidString,
              content: content,
              trigger: nil
          )

          UNUserNotificationCenter.current().add(request) { error in
              if let error = error {
                  print("Failed to schedule swap request notification: \(error.localizedDescription)")
              }
          }
      }
    
    // MARK: - Notification Authorization
    
    /// Request notification permissions
    func requestNotificationAuthorization(application: UIApplication) {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
                return
            }
            
            guard granted else {
                print("User denied notification permissions")
                return
            }
            
            // Register for remote notifications if authorized
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
    
    // MARK: - Firebase Messaging Delegate Methods
    
    /// Handle FCM token registration
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        print("FCM Token: \(token)")
        
        // Update token in user's Firestore document
        updateFirestoreToken(token)
    }
    
    /// Update FCM token in Firestore
    private func updateFirestoreToken(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No authenticated user to update token")
            return
        }
        
        let userRef = Firestore.firestore().collection("users").document(uid)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }
            
            // Update token if different or not exists
            userRef.setData(["fcmToken": token], merge: true) { error in
                if let error = error {
                    print("Error updating FCM token: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Notification Presentation Handling
    
    /// Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("Foreground notification received: \(userInfo)")
        
        // Show notification while app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle user interaction with notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("Notification tapped: \(userInfo)")
        
        // Here you can add logic to navigate to specific views based on notification type
        completionHandler()
    }
}

enum NotificationType: String {
    case message = "message"
    case swapRequest = "swapRequest"
    case profileUpdate = "profileUpdate"
    case systemAlert = "systemAlert"
}


/// A concise and type-safe Notification model
struct AppNotification: Identifiable, Hashable {
    /// Unique identifier for the notification
    let id: String

    /// Type of notification to enable precise handling
    let type: NotificationType

    /// Sender's user identifier
    let fromUserId: String

    /// Sender's display name
    let fromUserName: String

    /// Optional message content
    let message: String?

    /// Timestamp of the notification
    let timestamp: Date

    /// Creates a new notification
    /// - Parameters:
    ///   - type: The type of notification
    ///   - fromUserId: Unique identifier of the sender
    ///   - fromUserName: Display name of the sender
    ///   - message: Optional additional message details
    init(
        type: NotificationType,
        fromUserId: String,
        fromUserName: String,
        message: String? = nil,
        id: String? = nil,
        timestamp: Date? = nil
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.fromUserId = fromUserId
        self.fromUserName = fromUserName
        self.message = message
        self.timestamp = Date()
    }
}

// Convenience extension for easy notification posting
extension NotificationCenter {
    /// Post an app-wide notification
    func postAppNotification(_ notification: AppNotification) {
        post(
            name: .appNotification,
            object: nil,
            userInfo: ["notification": notification]
        )
    }
}

// Custom notification name
extension Notification.Name {
    static let appNotification = Notification.Name("appWideNotification")
}

// MARK: - AppDelegate
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var profileItem: ProfileData?
    var userSession: UserSession?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure Firebase with error handling
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        } else {
            print("Firebase is already configured.")
        }

        // Provide Google Places API key
        GMSPlacesClient.provideAPIKey("AIzaSyBKCMrXkHDRwh4UYdGt6YaQ3_kU190e6CI")

        // Request notification authorization
        NotificationManager.shared.requestNotificationAuthorization(application: application)

        // Set delegates for notification handling
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        Messaging.messaging().delegate = NotificationManager.shared

        return true
    }

    // Handle URL callback from Google Sign-In
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        } else {
            print("Failed to handle Google Sign-In URL")
            return false
        }
    }

    // Remote notification registration success
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    // Remote notification registration failure
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationManager.shared.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    // Handle remote notifications
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if let messageID = userInfo["gcm.message_id"] {
            print("Message ID: \(messageID)")
        }

        // Process notification data via NotificationManager
        NotificationManager.shared.handleIncomingNotification(userInfo: userInfo)

        completionHandler(.newData)
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
          guard let currentUserId = Auth.auth().currentUser?.uid else { return }
          NotificationManager.shared.startListeningForSwapRequests(userId: currentUserId)
          NotificationManager.shared.startListeningForMessages(userId: currentUserId)
      }
}

// Extend NotificationManager for AppDelegate-specific calls
extension NotificationManager {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func handleIncomingNotification(userInfo: [AnyHashable: Any]) {
        print("Notification received: \(userInfo)")
        
        guard let notificationData = parseNotificationData(userInfo) else {
            print("Failed to parse notification data.")
            return
        }
        
        addNotification(notificationData)
        
        // Schedule a local notification for immediate alert
        scheduleMessageNotification(
            fromUserName: notificationData.fromUserName.isEmpty ? "Unknown User" : notificationData.fromUserName,
            message: notificationData.message ?? "No message content."
        )
    }
    
    private func parseNotificationData(_ userInfo: [AnyHashable: Any]) -> AppNotification? {
        guard
            let typeString = userInfo["type"] as? String,
            let type = NotificationType(rawValue: typeString),
            let fromUserId = userInfo["fromUserId"] as? String
        else {
            print("Missing or invalid notification type/fromUserId.")
            return nil
        }
        
        let fromUserName = userInfo["fromUserName"] as? String ?? "Unknown User Name"
        let message = userInfo["message"] as? String
        return AppNotification(
            type: NotificationType(rawValue: UUID().uuidString)!,  // Assuming you have an 'unknown' case in your enum
            fromUserId: type.rawValue,  // Assuming `type` is a `NotificationType` with a raw value of `String`
            fromUserName: fromUserId,
            message: fromUserName,
            id: UUID().uuidString,
            timestamp: Date()
        )
    }
    
    func scheduleMessageNotification(fromUserName: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(fromUserName) sent you a message"
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
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
    @StateObject private var messageManager = MessageManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
    @StateObject private var profile = Profile()
    @StateObject private var profileItem = ProfileData()
    // Integrate AppDelegate
    
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
                .environmentObject(messageManager)
                .environmentObject(notificationManager)
        }
    }
}
