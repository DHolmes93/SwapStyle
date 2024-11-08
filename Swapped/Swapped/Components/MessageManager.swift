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
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // Fetch users from UserAccountModel
//    func fetchUsers(completion: @escaping ([UserAccountModel]) -> Void) {
//        db.collection("users").getDocuments { snapshot, error in
//            if let error = error {
//                print("Error fetching users: \(error)")
//                completion([])
//                return
//            }
//            let users = snapshot?.documents.compactMap { document in
//                try? document.data(as: UserAccountModel.self)
//            } ?? []
//            completion(users)
//        }
//    }

    // Fetch messages for the current user
    func fetchMessagesForUser(currentUserId: String) {
        var allMessages: [Message] = []

        // Fetch sent messages
        fetchMessagesSentByUser(currentUserId: currentUserId) { sentMessages in
            allMessages.append(contentsOf: sentMessages)

            // Fetch received messages
            self.fetchMessagesReceivedByUser(currentUserId: currentUserId) { receivedMessages in
                allMessages.append(contentsOf: receivedMessages)
                
                // Sort by timestamp
                self.messages = allMessages.sorted(by: { $0.timestamp < $1.timestamp })
            }
        }
    }

    // Fetch messages sent by the current user
    func fetchMessagesSentByUser(currentUserId: String, completion: @escaping ([Message]) -> Void) {
        db.collection("users").document(currentUserId).collection("sentMessages")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching sent messages: \(error)")
                    completion([])
                    return
                }
                let messages = snapshot?.documents.compactMap { document -> Message? in
                    try? document.data(as: Message.self)
                } ?? []
                completion(messages)
            }
    }

    // Fetch messages received by the current user
    func fetchMessagesReceivedByUser(currentUserId: String, completion: @escaping ([Message]) -> Void) {
        db.collection("users").document(currentUserId).collection("receivedMessages")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching received messages: \(error)")
                    completion([])
                    return
                }
                let messages = snapshot?.documents.compactMap { document -> Message? in
                    try? document.data(as: Message.self)
                } ?? []
                completion(messages)
            }
    }

    // Fetch conversation between two users
    func fetchUserMessages(currentUserId: String, otherUserId: String) {
        listener = db.collection("users").document(currentUserId).collection("messagesWith")
            .document(otherUserId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("No documents or error: \(String(describing: error))")
                    return
                }
                self.messages = documents.compactMap { document -> Message? in
                    try? document.data(as: Message.self)
                }
            }
    }

    // Send a message and save in both sender's and receiver's collections
    func sendMessage(currentUserId: String, otherUserId: String, content: String) {
        guard !content.isEmpty else { return }

        let message = Message(
            senderId: currentUserId,
            receiverId: otherUserId,
            senderName: "",  // Fetch in UI if needed
            receiverName: "", // Fetch in UI if needed
            content: content,
            timestamp: Date()
        )
        
        do {
            // Save message in sender's sentMessages
            let senderMessagesRef = db.collection("users").document(currentUserId).collection("sentMessages")
            try senderMessagesRef.addDocument(from: message)
            
            // Save message in receiver's receivedMessages
            let receiverMessagesRef = db.collection("users").document(otherUserId).collection("receivedMessages")
            try receiverMessagesRef.addDocument(from: message)
            
        } catch {
            print("Error sending message: \(error)")
        }
    }

    // Stop listening for real-time updates
    func stopListening() {
        listener?.remove()
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
}

extension UIImage {
    func toBase64() -> String? {
        return self.pngData()?.base64EncodedString()
    }
}
