//
//  MessageManager.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/11/24.
//
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class MessageManager: ObservableObject {
    @Published var messages: [Message] = []
    @Published var unreadMessageCount: Int = 0 
    private var db = Firestore.firestore()
    private var chatListener: ListenerRegistration?
    private var sentMessagesListener: ListenerRegistration?
    private var receivedMessagesListener: ListenerRegistration?
    static let shared = MessageManager()

    
    func fetchUserName(userId: String) async throws -> String {
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data(), let name = userData["name"] as? String else {
            throw NSError(domain: "MessageManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User name not found"])
        }
        return name
    }

    // Send message using async/await
    func sendMessage(
        chatId: String,
        senderId: String,
        receiverId: String,
        senderName: String,
        receiverName: String,
        content: String,
        timestamp: Date,
        senderProfileImage: String?,
        receiverProfileImage: String?
    ) async throws {
        // Fetch senderName from UserAccountModel
        let senderName: String
        do {
            senderName = try await fetchUserName(userId: senderId)
        } catch {
            print("Error fetching sender name: \(error)")
            throw error
        }

        // Create the new message object
        let newMessage = Message(
            id: UUID().uuidString,
            senderId: senderId,
            receiverId: receiverId,
            senderName: senderName,
            receiverName: receiverName,
            content: content,
            timestamp: timestamp,
            senderProfileImage: senderProfileImage,
            receiverProfileImage: receiverProfileImage,
            isRead: false
        )

        // Message data dictionary
        let messageData: [String: Any] = [
            "id": newMessage.id ?? UUID().uuidString,
            "senderId": senderId,
            "receiverId": receiverId,
            "content": content,
            "timestamp": timestamp,
            "senderName": senderName,
            "receiverName": receiverName,
            "senderProfileImage": senderProfileImage ?? "",
            "receiverProfileImage": receiverProfileImage ?? "",
            "isRead": false
        ]

        let senderRef = db.collection("users").document(senderId).collection("sentMessages").document(newMessage.id!)
        let receiverRef = db.collection("users").document(receiverId).collection("receivedMessages").document(newMessage.id!)

        // Save the message in both sender's and receiver's collections
        try await senderRef.setData(messageData)
        try await receiverRef.setData(messageData)

        // Create notification for the receiver
        let notificationId = UUID().uuidString
        let notificationData: [String: Any] = [
            "id": notificationId,
            "type": "message",
            "fromUserId": senderId,
            "toUserId": receiverId,
            "content": content,
            "timestamp": timestamp,
            "senderName": senderName,
            "senderProfileImage": senderProfileImage ?? ""
        ]

        let notificationRef = db.collection("users").document(receiverId).collection("notifications").document(notificationId)

        // Save the notification
        try await notificationRef.setData(notificationData)

        // Optionally, append to local array for instant UI update
        DispatchQueue.main.async {
            self.messages.append(newMessage)
        }
    }
    // Fetch messages for a specific chat using async/await
    func fetchMessages(chatId: String, userId: String) async throws -> [Message] {
        let snapshot = try await db.collection("users").document(userId).collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Message.self)
        }
    }
    // Fetch all sent and received messages for the current user
    func fetchMessagesForUser(currentUserId: String) async throws {
        let sentMessagesRef = db.collection("users").document(currentUserId).collection("sentMessages")
        let receivedMessagesRef = db.collection("users").document(currentUserId).collection("receivedMessages")
        
        let sentSnapshot = try await sentMessagesRef.getDocuments()
        let receivedSnapshot = try await receivedMessagesRef.getDocuments()
        
        var fetchedMessages: [Message] = []
        var unreadMessages = 0 // Local counter for unread messages
        
        // Loop through sent messages
        for document in sentSnapshot.documents {
            let data = document.data()
            let message = Message(
                id: document.documentID,
                senderId: data["senderId"] as? String ?? "",
                receiverId: data["receiverId"] as? String ?? "",
                senderName: data["senderName"] as? String ?? "",
                receiverName: data["receiverName"] as? String ?? "",
                content: data["content"] as? String ?? "",
                timestamp: data["timestamp"] as? Date ?? Date(),
                senderProfileImage: data["senderProfileImage"] as? String ?? "",
                receiverProfileImage: data["receiverProfileImage"] as? String ?? "",
                isRead: data["isRead"] as? Bool ?? false
            )
            fetchedMessages.append(message)
        }
        
        // Loop through received messages
        for document in receivedSnapshot.documents {
            let data = document.data()
            let message = Message(
                id: document.documentID,
                senderId: data["senderId"] as? String ?? "",
                receiverId: data["receiverId"] as? String ?? "",
                senderName: data["senderName"] as? String ?? "",
                receiverName: data["receiverName"] as? String ?? "",
                content: data["content"] as? String ?? "",
                timestamp: data["timestamp"] as? Date ?? Date(),
                senderProfileImage: data["senderProfileImage"] as? String ?? "",
                receiverProfileImage: data["receiverProfileImage"] as? String ?? "",
                isRead: data["isRead"] as? Bool ?? false
            )
            fetchedMessages.append(message)
            // Increment unread count for received messages
            if message.isRead == false {
                unreadMessages += 1
                
                // Notify NotificationManager of the new unread message
                NotificationManager.shared.scheduleMessageNotification(
                        fromUserName: message.senderName,
                        message: message.content
                    )
//                NotificationManager.shared.scheduleMessageNotification(message: "New message from \(message.senderName): \(message.content)")
            }
        }
        
        // Update unread message count
        DispatchQueue.main.async {
            self.unreadMessageCount = unreadMessages
            NotificationManager.shared.unreadMessageCount = unreadMessages
        }
        
        // Sort messages by timestamp
        fetchedMessages.sort { $0.timestamp < $1.timestamp }
        
        // Update the messages array
        DispatchQueue.main.async {
            self.messages = fetchedMessages
        }
    }


    // Fetch sent messages by current user using async/await
    func fetchMessagesSentByUser(currentUserId: String) async throws -> [Message] {
        let snapshot = try await db.collection("users").document(currentUserId).collection("sentMessages").getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Message.self)
        }
    }
    

    // Fetch received messages by current user using async/await
    func fetchMessagesReceivedByUser(currentUserId: String) async throws -> [Message] {
        let snapshot = try await db.collection("users").document(currentUserId).collection("receivedMessages").getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Message.self)
        }
    }

    // Fetch conversation between two users using async/await
    func fetchUserMessages(currentUserId: String, otherUserId: String) async throws {
        let chatId = getOrCreateChatId(currentUserId: currentUserId, otherUserId: otherUserId)
        
        let snapshot = try await db.collection("users").document(currentUserId).collection("chats")
            .document(chatId).collection("messages")
            .order(by: "timestamp")
            .getDocuments()
        
        self.messages = snapshot.documents.compactMap { document in
            try? document.data(as: Message.self)
        }
    }

    // Create or fetch chat ID for two users using async/await
     func getOrCreateChatId(currentUserId: String?, otherUserId: String?) -> String {
        guard let currentUserId = currentUserId, let otherUserId = otherUserId else { return "unknown" }
        let chatId = currentUserId < otherUserId ? "\(currentUserId)_\(otherUserId)" : "\(otherUserId)_\(currentUserId)"
        
        Task {
            do {
                let chatDocRef = db.collection("users").document(currentUserId).collection("chats").document(chatId)
                
                let chatSnapshot = try await chatDocRef.getDocument()
                
                if !chatSnapshot.exists {
                    // Create a new chat if it doesn't exist
                    try await chatDocRef.setData(["createdAt": FieldValue.serverTimestamp()])
                    
                    // Optionally, create chat data for the other user
                    let otherUserChatRef = db.collection("users").document(otherUserId).collection("chats").document(chatId)
                    try await otherUserChatRef.setData(["createdAt": FieldValue.serverTimestamp()])
                }
            } catch {
                print("Error creating or fetching chat: \(error.localizedDescription)")
            }
        }
        return chatId
    }

    // Mark message as read using async/await
    func markMessageAsRead(chatId: String, messageId: String) async throws {
        let messageRef = db.collection("chats").document(chatId).collection("messages").document(messageId)
        try await messageRef.updateData(["isRead": true])
    }
    
    func startListeningForUserMessages(currentUserId: String) {
        stopListeningForUserMessages()

        // Listener for received messages
        receivedMessagesListener = db.collection("users").document(currentUserId).collection("receivedMessages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching received messages: \(error.localizedDescription)")
                    return
                }
                self?.processSnapshot(snapshot, isReceived: true)
            }
    }


    // Stop real-time listeners
    func stopListeningForUserMessages() {
        sentMessagesListener?.remove()
        receivedMessagesListener?.remove()
    }

    // Process snapshot updates and update messages and unread count
    private func processSnapshot(_ snapshot: QuerySnapshot?, isReceived: Bool) {
        guard let snapshot = snapshot else { return }
        var newUnreadCount = 0
        
        for document in snapshot.documents {
            if let message = try? document.data(as: Message.self), !(message.isRead ?? false) {
                newUnreadCount += 1
            }
        }

        DispatchQueue.main.async {
            if isReceived {
                self.unreadMessageCount = newUnreadCount
                NotificationManager.shared.unreadMessageCount = newUnreadCount
            }
        }
    }
    // Setup listener to receive messages in real time
        func startListeningForMessages(chatId: String) {
            let db = Firestore.firestore()
            chatListener = db.collection("chats").document(chatId).collection("messages")
                .order(by: "timestamp")
                .addSnapshotListener { [weak self] snapshot, error in
                    if let error = error {
                        print("Error fetching messages: \(error.localizedDescription)")
                        return
                    }
                    guard let snapshot = snapshot else { return }
                    self?.messages = snapshot.documents.compactMap { doc in
                        try? doc.data(as: Message.self)
                    }
                }
        }

    // Stop listening to real-time updates
    func stopListening() {
        chatListener?.remove()
    }
}
struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var senderId: String
    var receiverId: String
    var senderName: String
    var receiverName: String
    var content: String
    var timestamp: Date
    var senderProfileImage: String?
    var receiverProfileImage: String?
    var isRead: Bool? // Optional for backward compatibility
}

extension String {
    func toUIImage() -> UIImage? {
        guard let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) else {
            return nil
        }
        return UIImage(data: data)
    }
}
