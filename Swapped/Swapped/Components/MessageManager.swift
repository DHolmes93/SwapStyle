//
//  MessageManager.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/11/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class MessageManager: ObservableObject {
    @Published var messages: [Message] = []
    @Published var viewModel = UserAccountModel()
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func fetchMessages(chatId: String, currentUserId: String, otherUserId: String) {
        listener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("No documents")
                    return
                }
                self.messages = documents.compactMap { document -> Message? in
                    try? document.data(as: Message.self)
                }
            }
    }
    
    func fetchMessagesSentByUser(currentUserId: String, completion: @escaping ([Message]) -> Void) {
        db.collection("chats")
            .whereField("senderId", isEqualTo: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error)")
                    completion([])
                    return
                }
                let messages = snapshot?.documents.compactMap { document -> Message? in
                    try? document.data(as: Message.self)
            } ?? []
        completion(messages)
    }
}
    func fetchMessagesReceivedByUser(currentUserId: String, completion: @escaping ([Message]) -> Void) {
        db.collection("chats")
            .whereField("receiverId", isEqualTo: currentUserId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error)")
                    completion([])
                    return
                }
                let messages = snapshot?.documents.compactMap { document -> Message? in
                    try? document.data(as: Message.self)
                } ?? []
                completion(messages)
            }
    }
    func sendMessage(chatId: String, currentUserId: String, otherUserId: String, content: String) {
        let dispatchGroup = DispatchGroup()
        guard !content.isEmpty else { return }
        var senderName: String?
        var receiverName: String?
        var senderProfileImage: String?
        var receiverProfileImage: String?
        
        dispatchGroup.enter()
        viewModel.fetchNameAndProfileImage(userId: currentUserId) { name, profileImage in
            senderName = name
            senderProfileImage = profileImage?.toBase64()
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        viewModel.fetchNameAndProfileImage(userId: otherUserId) { name, profileImage in
            receiverName = name
            receiverProfileImage = profileImage?.toBase64()
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            guard let senderName = senderName,
                  let receiverName = receiverName else {
                print("Error fetching names")
                return
            }
            
        
            let message = Message(senderId: currentUserId, receiverId: otherUserId, senderName: senderName, receiverName: receiverName, content: content, timestamp: Date(), senderProfileImage: senderProfileImage, receiverProfileImage: receiverProfileImage)
            do {
                try self.db.collection("chats").document(chatId).collection("messages").addDocument(from: message) { error in
                    if let error = error {
                        print("Error adding message: \(error)")
                    }
                }
            } catch {
                print("Error adding message: \(error)")
            }
        }
    }
    func fetchNamesAndProfileImages(currentUserId: String, otherUserId: String, completion: @escaping (String, String, UIImage?, UIImage?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var senderName = ""
        var receiverName = ""
        var senderProfileImage: UIImage?
        var receiverProfileImage: UIImage?
        
        dispatchGroup.enter()
        viewModel.fetchNameAndProfileImage(userId: otherUserId) { name, profileImage in
            senderName = name
            senderProfileImage = profileImage
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        viewModel.fetchNameAndProfileImage(userId: otherUserId) { name, profileImage in
            receiverName = name
            receiverProfileImage = profileImage
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            completion(senderName, receiverName, senderProfileImage, receiverProfileImage)
        }
    }
     func fetchNameAndProfileImage(userId: String, completion: @escaping (String, UIImage?) -> Void) {
         if let name = viewModel.otherUserNames[userId], let profileImage = viewModel.otherUserProfileImages[userId] {
             completion(name, profileImage)
             return
         }
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let name = document.data()?["name"] as? String ?? "Unknown"
                self.viewModel.otherUserNames[userId] = name
                if let profileImageUrl = document.data()?["profileImageUrl"] as? String {
                    self.viewModel.fetchProfileImage(from: profileImageUrl) { image in
                        self.viewModel.otherUserProfileImages[userId] = image
                        completion(name, image)
                    }
                }
                
                 
            } else {
                print("Document does not exist")
            }
        }
    }
    func fetchUsers(completion: @escaping ([User]) -> Void) {
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                completion([])
                return
            }
            let users = snapshot?.documents.compactMap { document in
                try? document.data(as: User.self)
            } ?? []
            completion(users)
        }
    }
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

//        var senderProfileImage: UIImage?
//        var receiverProfileImage:UIImage?
