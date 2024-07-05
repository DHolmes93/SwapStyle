//
//  MessagingScreenView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/4/24.
//

import SwiftUI
import FirebaseFirestoreSwift
import FirebaseFirestore

struct MessagingScreenView: View {
    @State private var messages: [Message] = []
    @State private var newMessage = ""
    
    let currentUserId: String
    let otherUserId: String
    let chatId: String
    @State private var userName: String? = nil
    var body: some View {
        VStack {
            if let userName = userName {
                Text("To: \(userName)")
                    .font(.headline)
                    .padding()
            }
            ScrollView {
                ForEach(messages) { message in
                    HStack {
                        if message.senderId == currentUserId {
                            Spacer()
                            Text(message.content)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        } else {
                            Text(message.content)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        
                    }
                    .padding()
                }
            }
            HStack {
                TextField("Message", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: CGFloat(30))
                
                Button(action: sendMessage) {
                    Text("Send")
                }
            }
            .padding()
        }
        .onAppear(perform: fetchMessages)
        .onAppear(perform: fetchUserName)
    }
    
    func fetchMessages() {
        let db = Firestore.firestore()
        db.collection("users").document(currentUserId).collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("No documents")
                    return
                }
                self.messages = documents.compactMap { document -> Message? in try? document.data(as: Message.self)
            }
    }
}
func sendMessage() {
    guard !newMessage.isEmpty else { return }
    let db = Firestore.firestore()
    let message = Message(senderId: currentUserId, receiverId: otherUserId, content: newMessage, timestamp: Timestamp())
    do {
        _ = try db.collection("users").document(currentUserId).collection("chats").document(chatId).collection("messages").addDocument(from: message)
        _ = try db.collection("users").document(otherUserId).collection("chats").document(chatId).collection("messages").addDocument(from: message)
        newMessage = ""
    } catch {
        print("Error adding message: \(error)")
    }
    
}
    func fetchUserName() {
        let db = Firestore.firestore()
        db.collection("users").document(otherUserId).getDocument { document, error in
            if let document = document, document.exists {
                self.userName = document.data()?["name"] as? String
            } else {
                print("Document does not exist")
            }
        }
    }
}


struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var senderId: String
    var receiverId: String
    var content: String
    var timestamp: Timestamp
}

#Preview {
    MessagingScreenView(currentUserId: "user2", otherUserId: "user1", chatId: "chat1")
}

