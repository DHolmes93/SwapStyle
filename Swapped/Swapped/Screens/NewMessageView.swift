//
//  NewMessageView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/11/24.
//

import SwiftUI

struct NewMessageView: View {
    @State private var users: [User] = []
    @State private var searchText = ""
    let currentUserId: String
    @StateObject private var messageManager = MessageManager()
    @State private var showRecipientNameAlert = false
    @State private var showUserNotFoundAlert = false
    @State private var recipientName = ""
    @State private var navigateToMessagingScreen = false
    @State private var newChatId = ""
    @State private var newRecipientId = ""
    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                TextField("Search Names", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                ScrollView {
                    List {
                        ForEach(users.filter { user in
                            searchText.isEmpty ?  true : user.name.contains(searchText)
                        }) { user in
                            NavigationLink(destination: MessagingScreenView(currentUserId: currentUserId, otherUserId: user.id, chatId: createChatId(currentUserId: currentUserId, otherUserId: user.id))) {
                                Text(user.name)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showRecipientNameAlert = true
                    }) {
                        Image(systemName: "plus.message")
                            .foregroundStyle(Color.red)
                            .padding()
//                            .background(Color.blue)
            }
            .alert("Enter Recipient Name", isPresented: $showRecipientNameAlert) {
                TextField("Name", text: $recipientName)
                Button("Cancel", role: .cancel) {
                    showRecipientNameAlert = false
                }
                Button("OK") {
                    if let recipient = users.first(where: { $0.name == recipientName}) {
                        newChatId = createChatId(currentUserId: currentUserId, otherUserId: recipient.id)
                        newRecipientId = recipient.id
                        navigateToMessagingScreen(recipient: recipient)
                    } else {
                        showUserNotFoundAlert = true
                    }
                    showRecipientNameAlert = false
                }
            }
            .alert("User Not Found", isPresented: $showUserNotFoundAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
            .padding()
                .onAppear {
                    messageManager.fetchUsers { fetchedUsers in
                        self.users = fetchedUsers
                    }
                }
            }
        
    }
    func createChatId(currentUserId: String, otherUserId: String) -> String {
        return currentUserId < otherUserId ? "\(currentUserId)_\(otherUserId)" : "\(otherUserId)_\(currentUserId)"
    }
    func navigateToMessagingScreen(recipient: User) {
           if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController as? UINavigationController {
               let messagingScreen = UIHostingController(rootView: MessagingScreenView(currentUserId: currentUserId, otherUserId: recipient.id, chatId: newChatId))
               rootViewController.pushViewController(messagingScreen, animated: true)
           }
       }
   
}

#Preview {
    NewMessageView(currentUserId: "user1")
}
