//
//  NotificationsView.swift
//  Just Swap
//
//  Created by Donovan Holmes on 12/7/24.
//

import SwiftUI
//
//struct NotificationsView: View {
//    @EnvironmentObject private var notificationManager: NotificationManager
//
//    var body: some View {
//        VStack {
//            Text("Notifications")
//                .font(.largeTitle)
//                .bold()
//                .padding()
//
//            if notificationManager.notificationCount > 0 {
//                Text("You have \(notificationManager.notificationCount) unread notifications.")
//            } else {
//                Text("No new notifications.")
//                    .foregroundColor(.gray)
//            }
////            .padding()
////            .foregroundColor(.white)
////            .background(Color.blue)
////            .cornerRadius(8)
//        }
//        .padding()
//    }
//}
//import SwiftUI
//
//struct NotificationsView: View {
//    @EnvironmentObject private var notificationManager: NotificationManager
//
//    var body: some View {
//        VStack {
//            Text("Notifications")
//                .font(.largeTitle)
//                .bold()
//                .padding()
//
//            if notificationManager.notificationCount > 0 {
//                ScrollView {
//                    VStack(alignment: .leading, spacing: 10) {
//                        ForEach(notificationManager.notifications, id: \.id) { notification in
//                            HStack {
//                                if notification.type == .message {
//                                    Text("Message from \(notification.fromUserName)")
//                                        .font(.body)
//                                        .foregroundColor(.primary)
//                                } else if notification.type == .swapRequest {
//                                    Text("Swap request from \(notification.fromUserName)")
//                                        .font(.body)
//                                        .foregroundColor(.blue)
//                                }
//                            }
//                            .padding()
//                            .background(Color(UIColor.secondarySystemBackground))
//                            .cornerRadius(8)
//                        }
//                    }
//                }
//            } else {
//                Text("No new notifications.")
//                    .foregroundColor(.gray)
//            }
//        }
//        .padding()
//    }
//}
//struct NotificationsView: View {
//    @EnvironmentObject private var notificationManager: NotificationManager
//
//    var body: some View {
//        VStack {
//            Text("Notifications")
//                .font(.largeTitle)
//                .bold()
//                .padding()
//
//            if notificationManager.notificationCount > 0 {
//                ScrollView {
//                    VStack(alignment: .leading, spacing: 10) {
//                        ForEach(notificationManager.notifications, id: \.id) { notification in
//                            HStack {
//                                if notification.type == .message {
//                                    Text("Message from \(notification.fromUserName)")
//                                        .font(.body)
//                                        .foregroundColor(.primary)
//                                } else if notification.type == .swapRequest {
//                                    Text("Swap request from \(notification.fromUserName)")
//                                        .font(.body)
//                                        .foregroundColor(.blue)
//                                }
//                            }
//                            .padding()
//                            .background(Color(UIColor.secondarySystemBackground))
//                            .cornerRadius(8)
//                        }
//                    }
//                }
//            } else {
//                Text("No new notifications.")
//                    .foregroundColor(.gray)
//            }
//        }
//        .padding()
//        .onAppear {
//            print("Notification count: \(notificationManager.notificationCount)")
//            print("Notifications: \(notificationManager.notifications)")
//        }
//    }
//}
//struct NotificationsView: View {
//    @EnvironmentObject private var notificationManager: NotificationManager
//    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())
//    var fromUserId: String
//    var fromUserName: String
//    var message: String
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Notifications")
//                    .font(.largeTitle)
//                    .bold()
//                    .padding()
//
//                if notificationManager.notifications.isEmpty {
//                    Text("No new notifications.")
//                        .foregroundColor(.gray)
//                        .font(.body)
//                } else {
//                    ScrollView {
//                        LazyVStack(alignment: .leading, spacing: 15) {
//                            ForEach(notificationManager.notifications) { notification in
//                                NotificationRow(notification: notification)
//                                    .padding(.horizontal)
//                            }
//                        }
//                        .padding(.top)
//                    }
//                }
//            }
//        }
//        .onAppear {
//            // Load test notifications
//            notificationManager.notifications = [
//                AppNotification(type: .message, fromUserId: fromUserId, fromUserName: fromUserName, message: message),
//                AppNotification(type: .swapRequest, fromUserId: fromUserId, fromUserName: fromUserName, message: "Swap request for your item."),
//            ]
//
//            print("Loaded test notifications.")
//
//            // Fetch user profile asynchronously
//            Task {
//                do {
//                    try await viewModel.fetchUserProfile(userUID: fromUserId)
//                } catch {
//                    print("Failed to fetch user profile: \(error.localizedDescription)")
//                }
//            }
//        }
//
//
//    }
//}
//
//struct NotificationRow: View {
//    let notification: AppNotification
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(notificationTitle(for: notification.type))
//                .font(.headline)
//                .foregroundColor(titleColor(for: notification.type))
//            Text(notification.message ?? defaultMessage(for: notification.type))
//                .font(.subheadline)
//                .foregroundColor(.primary)
//            Text("From: \(notification.fromUserName)")
//                .font(.caption)
//                .foregroundColor(.secondary)
//        }
//        .padding()
//        .background(Color(UIColor.secondarySystemBackground))
//        .cornerRadius(10)
//        .onAppear {
//            print("Rendering NotificationRow for: \(notification)")
//        }
//    }
//
//
//    private func notificationTitle(for type: NotificationType) -> String {
//        switch type {
//        case .message: return "Message"
//        case .swapRequest: return "Swap Request"
//        case .profileUpdate: return "Profile Update"
//        case .systemAlert: return "System Alert"
//        }
//    }
//
//    private func titleColor(for type: NotificationType) -> Color {
//        switch type {
//        case .message: return .blue
//        case .swapRequest: return .green
//        case .profileUpdate: return .orange
//        case .systemAlert: return .red
//        }
//    }
//
//    private func defaultMessage(for type: NotificationType) -> String {
//        switch type {
//        case .message: return "You have a new message."
//        case .swapRequest: return "Someone wants to swap an item."
//        case .profileUpdate: return "Your profile has been updated."
//        case .systemAlert: return "You have received a system alert."
//        }
//    }
//}
//struct NotificationsView: View {
//    @EnvironmentObject private var notificationManager: NotificationManager
//    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())
//    var fromUserId: String
//    var fromUserName: String
//    var message: String
//
//    @State private var userNames: [String: String] = [:]
//    @State private var userProfileImages: [String: String?] = [:]
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Notifications")
//                    .font(.largeTitle)
//                    .bold()
//                    .padding()
//
//                if notificationManager.notifications.isEmpty {
//                    Text("No new notifications.")
//                        .foregroundColor(.gray)
//                        .font(.body)
//                } else {
//                    ScrollView {
//                        LazyVStack(alignment: .leading, spacing: 15) {
//                            ForEach(notificationManager.notifications) { notification in
//                                NotificationRow(
//                                    notification: notification,
//                                    userName: userNames[notification.fromUserId] ?? "Unknown",
//                                    profileImageUrl: userProfileImages[notification.fromUserId] ?? nil
//                                )
//                                    .padding(.horizontal)
//                                    .onAppear {
//                                        loadUserProfile(for: notification.fromUserId)
//                                    }
//                            }
//                        }
//                        .padding(.top)
//                    }
//                }
//            }
//        }
//        .onAppear {
//            // Load test notifications
//            notificationManager.notifications = [
//                AppNotification(type: .message, fromUserId: fromUserId, fromUserName: fromUserName, message: message),
//                AppNotification(type: .swapRequest, fromUserId: fromUserId, fromUserName: fromUserName, message: "Swap request for your item."),
//            ]
//            print("Loaded test notifications.")
//
//            // Fetch user profile asynchronously
//            Task {
//                do {
//                    try await viewModel.fetchUserProfile(userUID: fromUserId)
//                } catch {
//                    print("Failed to fetch user profile: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//
//    // Function to load user profile for a notification
//    private func loadUserProfile(for userId: String) {
//        Task {
//            let (name, profileImageUrl) = await viewModel.fetchNameAndProfileImage(userId: userId)
//            userNames[userId] = name
//            userProfileImages[userId] = profileImageUrl
//        }
//    }
//}
//
//struct NotificationRow: View {
//    let notification: AppNotification
//    let userName: String
//    let profileImageUrl: String?
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(notificationTitle(for: notification.type))
//                .font(.headline)
//                .foregroundColor(titleColor(for: notification.type))
//            Text(notification.message ?? defaultMessage(for: notification.type))
//                .font(.subheadline)
//                .foregroundColor(.primary)
//            HStack {
//                if let profileImageUrl = profileImageUrl {
//                    AsyncImage(url: URL(string: profileImageUrl)) { image in
//                        image.resizable()
//                            .scaledToFit()
//                            .frame(width: 40, height: 40)
//                            .clipShape(Circle())
//                    } placeholder: {
//                        Circle()
//                            .fill(Color.gray)
//                            .frame(width: 40, height: 40)
//                    }
//                } else {
//                    Circle()
//                        .fill(Color.gray)
//                        .frame(width: 40, height: 40)
//                }
//                Text("From: \(userName)")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .padding()
//        .background(Color(UIColor.secondarySystemBackground))
//        .cornerRadius(10)
//        .onAppear {
//            print("Rendering NotificationRow for: \(notification)")
//        }
//    }
//
//    private func notificationTitle(for type: NotificationType) -> String {
//        switch type {
//        case .message: return "Message"
//        case .swapRequest: return "Swap Request"
//        case .profileUpdate: return "Profile Update"
//        case .systemAlert: return "System Alert"
//        }
//    }
//
//    private func titleColor(for type: NotificationType) -> Color {
//        switch type {
//        case .message: return .blue
//        case .swapRequest: return .green
//        case .profileUpdate: return .orange
//        case .systemAlert: return .red
//        }
//    }
//
//    private func defaultMessage(for type: NotificationType) -> String {
//        switch type {
//        case .message: return "You have a new message."
//        case .swapRequest: return "Someone wants to swap an item."
//        case .profileUpdate: return "Your profile has been updated."
//        case .systemAlert: return "You have received a system alert."
//        }
//    }
//}
//struct NotificationsView: View {
//    @EnvironmentObject private var notificationManager: NotificationManager
//    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())
//    
//    @State private var userNames: [String: String] = [:]
//    @State private var userProfileImages: [String: String?] = [:]
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Notifications")
//                    .font(.largeTitle)
//                    .bold()
//                    .padding()
//
//                if notificationManager.notifications.isEmpty {
//                    Text("No new notifications.")
//                        .foregroundColor(.gray)
//                        .font(.body)
//                } else {
//                    ScrollView {
//                        LazyVStack(alignment: .leading, spacing: 15) {
//                            ForEach(notificationManager.notifications) { notification in
//                                NotificationRow(
//                                    notification: notification,
//                                    userName: userNames[notification.fromUserId] ?? "Unknown",
//                                    profileImageUrl: userProfileImages[notification.fromUserId] ?? nil
//                                )
//                                    .padding(.horizontal)
//                                    .onAppear {
//                                        loadUserProfile(for: notification.fromUserId)
//                                    }
//                            }
//                        }
//                        .padding(.top)
//                    }
//                }
//            }
//            .onAppear {
//                loadTestNotifications()
//            }
//        }
//    }
//    
//    // MARK: - Load Test Notifications
//    private func loadTestNotifications() {
//        notificationManager.notifications = [
//            AppNotification(type: .message, fromUserId: "user1", fromUserName: "Alice", message: "Hey, how are you?"),
//            AppNotification(type: .swapRequest, fromUserId: "user2", fromUserName: "Bob", message: "Interested in swapping items?")
//        ]
//        print("Loaded test notifications.")
//    }
//    
//    // MARK: - Load User Profile
//    private func loadUserProfile(for userId: String) {
//        Task {
//            guard userNames[userId] == nil else { return } // Avoid redundant fetching
//            let (name, profileImageUrl) = await viewModel.fetchNameAndProfileImage(userId: userId)
//            DispatchQueue.main.async {
//                userNames[userId] = name
//                userProfileImages[userId] = profileImageUrl
//            }
//        }
//    }
//}
//
//struct NotificationRow: View {
//    let notification: AppNotification
//    let userName: String
//    let profileImageUrl: String?
//    
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(notificationTitle(for: notification.type))
//                .font(.headline)
//                .foregroundColor(titleColor(for: notification.type))
//            Text(notification.message ?? defaultMessage(for: notification.type))
//                .font(.subheadline)
//                .foregroundColor(.primary)
//            HStack {
//                if let profileImageUrl = profileImageUrl {
//                    AsyncImage(url: URL(string: profileImageUrl)) { image in
//                        image.resizable()
//                            .scaledToFit()
//                            .frame(width: 40, height: 40)
//                            .clipShape(Circle())
//                    } placeholder: {
//                        Circle()
//                            .fill(Color.gray)
//                            .frame(width: 40, height: 40)
//                    }
//                } else {
//                    Circle()
//                        .fill(Color.gray)
//                        .frame(width: 40, height: 40)
//                }
//                Text("From: \(userName)")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .padding()
//        .background(Color(UIColor.secondarySystemBackground))
//        .cornerRadius(10)
//        .onAppear {
//            print("Rendering NotificationRow for: \(notification)")
//        }
//    }
//    
//    private func notificationTitle(for type: NotificationType) -> String {
//        switch type {
//        case .message: return "Message"
//        case .swapRequest: return "Swap Request"
//        case .profileUpdate: return "Profile Update"
//        case .systemAlert: return "System Alert"
//        }
//    }
//
//    private func titleColor(for type: NotificationType) -> Color {
//        switch type {
//        case .message: return .blue
//        case .swapRequest: return .green
//        case .profileUpdate: return .orange
//        case .systemAlert: return .red
//        }
//    }
//
//    private func defaultMessage(for type: NotificationType) -> String {
//        switch type {
//        case .message: return "You have a new message."
//        case .swapRequest: return "Someone wants to swap an item."
//        case .profileUpdate: return "Your profile has been updated."
//        case .systemAlert: return "You have received a system alert."
//        }
//    }
//}
struct NotificationsView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())

    @State private var userNames: [String: String] = [:]
    @State private var userProfileImages: [String: String?] = [:]

    var body: some View {
        NavigationView {
            VStack {
                Text("Notifications")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                if notificationManager.notifications.isEmpty {
                    Text("No new notifications.")
                        .foregroundColor(.gray)
                        .font(.body)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            if !swapRequests.isEmpty {
                                Section(header: Text("Swap Requests").font(.headline).padding(.leading)) {
                                    ForEach(swapRequests) { notification in
                                        NotificationRow(
                                            notification: notification,
                                            userName: userNames[notification.fromUserId] ?? "Unknown",
                                            profileImageUrl: userProfileImages[notification.fromUserId] ?? nil
                                        )
                                            .padding(.horizontal)
                                            .onAppear {
                                                loadUserProfile(for: notification.fromUserId)
                                            }
                                    }
                                }
                            }

                            if !messages.isEmpty {
                                Section(header: Text("Messages").font(.headline).padding(.leading)) {
                                    ForEach(messages) { notification in
                                        NotificationRow(
                                            notification: notification,
                                            userName: userNames[notification.fromUserId] ?? "Unknown",
                                            profileImageUrl: userProfileImages[notification.fromUserId] ?? nil
                                        )
                                            .padding(.horizontal)
                                            .onAppear {
                                                loadUserProfile(for: notification.fromUserId)
                                            }
                                    }
                                }
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .onAppear {
                loadUserNotifications()
            }
        }
    }

    // MARK: - Helper Properties
    private var swapRequests: [AppNotification] {
        let requests = notificationManager.notifications.filter { $0.type == .swapRequest }
        print("Swap Requests: \(requests)")  // Debugging print statement
        return requests
    }

    private var messages: [AppNotification] {
        let msgs = notificationManager.notifications.filter { $0.type == .message }
        print("Messages: \(msgs)")  // Debugging print statement
        return msgs
    }

    // MARK: - Load User Notifications

    private func loadUserNotifications() {
        Task {
            notificationManager.notifications = await viewModel.fetchUserNotifications()
            print("Loaded user notifications: \(notificationManager.notifications)")  // Check if notifications are being loaded
        }
    }


    // MARK: - Load User Profile

    private func loadUserProfile(for userId: String) {
        Task {
            guard userNames[userId] == nil else { return } // Avoid redundant fetching
            let (name, profileImageUrl) = await viewModel.fetchNameAndProfileImage(userId: userId)
            DispatchQueue.main.async {
                userNames[userId] = name
                userProfileImages[userId] = profileImageUrl
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    let userName: String
    let profileImageUrl: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(notificationTitle(for: notification.type))
                .font(.headline)
                .foregroundColor(titleColor(for: notification.type))
            Text(notification.message ?? defaultMessage(for: notification.type))
                .font(.subheadline)
                .foregroundColor(.primary)
            HStack(spacing: 10) {
                if let profileImageUrl = profileImageUrl {
                    AsyncImage(url: URL(string: profileImageUrl)) { image in
                        image.resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 40, height: 40)
                    }
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 40, height: 40)
                }
                Text("From: \(userName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .onAppear {
            print("Rendering NotificationRow for: \(notification)")
        }
    }

    private func notificationTitle(for type: NotificationType) -> String {
        switch type {
        case .message: return "Message"
        case .swapRequest: return "Swap Request"
        case .profileUpdate: return "Profile Update"
        case .systemAlert: return "System Alert"
        }
    }

    private func titleColor(for type: NotificationType) -> Color {
        switch type {
        case .message: return .blue
        case .swapRequest: return .green
        case .profileUpdate: return .orange
        case .systemAlert: return .red
        }
    }

    private func defaultMessage(for type: NotificationType) -> String {
        switch type {
        case .message: return "You have a new message."
        case .swapRequest: return "Someone wants to swap an item."
        case .profileUpdate: return "Your profile has been updated."
        case .systemAlert: return "You have received a system alert."
        }
    }
}

