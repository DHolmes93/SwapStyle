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
    @EnvironmentObject private var userAccountModel: UserAccountModel
    @State private var messageManager = MessageManager()
    @State private var newMessage = ""
    
    let currentUserId: String
    let otherUserId: String
    let chatId: String
    @State private var otherUserName: String = ""
//    let userAccount: UserAccountModel
    var body: some View {
        VStack {
            Text("To: \(otherUserName)")
                    .font(.headline)
                    .padding()
            ScrollView {
                ForEach(messageManager.messages) { message in
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
                
                Button(action: {
                    userAccountModel.fetchName(userId: otherUserId) { otherUserName in
                        messageManager.sendMessage(chatId: chatId, currentUserId: currentUserId, otherUserId: otherUserId, content: newMessage)
                        newMessage = ""
                    }
                }) {
                    Text("Send")
                }
            }
            .padding()
        }
        .onAppear {
            messageManager.fetchMessages(chatId: chatId, currentUserId: currentUserId, otherUserId: otherUserId)
            userAccountModel.fetchName(userId: otherUserId) { name in
                otherUserName = name
            }
        }
        .onDisappear {
            messageManager.stopListening()
        }
    }
}



#Preview {
    MessagingScreenView(currentUserId: "user2", otherUserId: "user1", chatId: "chat1")
}

