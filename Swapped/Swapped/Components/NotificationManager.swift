//
//  NotificationManager.swift
//  Just Swap
//
//  Created by Donovan Holmes on 12/1/24.
//

import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private init() {}

    // Request Permission to Show Notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Failed to request authorization: \(error.localizedDescription)")
            }
        }
    }

    // Schedule a Notification for New Messages
    func scheduleMessageNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Message"
        content.body = message
        content.sound = .default

        // Trigger the notification in 1 second (for testing)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // Create a request with a unique identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // Add notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }

    // Handle Notifications when App is in Foreground
    func handleForegroundNotifications() {
        UNUserNotificationCenter.current().delegate = AppDelegate.shared
    }
}
