//
//  NewMessageFormView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/11/24.
//

import SwiftUI

//struct NewMessageFormView: View {
//    @StateObject private var messageManager = MessageManager()
//    @State private var recipientId = ""
//    @State private var messageContent = ""
//    @State private var recipientName = ""
//    @State private var isFetchingName = false
//    let currentUserId: String
//    let currentUserName: String
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            TextField("Recipient User ID", text: $recipientId)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//            TextField("Message", text: $messageContent)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//            
//            Button(action: {
//                let chatId = createChatId(currentUserId: currentUserId, otherUserId: recipientId)
//                messageManager.sendMessage(chatId: chatId, currentUserId: currentUserId, otherUserId: recipientId, content: messageContent, senderName: currentUserName, receiverName: recipientName)
//            }) {
//                Text("Send")
//            }
//            .disabled(isFetchingName || recipientName.isEmpty || messageContent.isEmpty)
//        }
//    }
//    private func fetchRecipientName(userId: String) {
//        guard !userId.isEmpty else {
//            recipientName = ""
//            return
//        }
//        isFetchingName = true
//        messageManager.fetchName(userId: userId) { name in
//            self.recipientName = name
//            self.isFetchingName = false
//        }
//    }
//    func createChatId(currentUserId: String, otherUserId: String) -> String {
//            return currentUserId < otherUserId ? "\(currentUserId)_\(otherUserId)" : "\(otherUserId)_\(currentUserId)"
//        }
//}
//
//#Preview {
//    NewMessageFormView(currentUserId: "user 2", currentUserName: "Don")
//}
