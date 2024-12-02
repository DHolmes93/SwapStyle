//
//  NewMessageView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/11/24.
//
//import SwiftUI
//
//struct NewMessageView: View {
//    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
//    
//    @State private var users: [UserAccountModel] = []  // Update type here
//    @State private var searchText = ""
////    @State private var currentUserId: String
//    @StateObject private var messageManager = MessageManager()
//    @State private var showRecipientNameAlert = false
//    @State private var showUserNotFoundAlert = false
//    @State private var recipientName = ""
//    @State private var newChatId = ""
//    @State private var newRecipientId = ""
//    @EnvironmentObject private var authManager: AuthManager
//
//    var body: some View {
//        NavigationStack {
//            VStack(alignment: .center) {
//                TextField("Search Messages", text: $searchText)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .padding()
//
//                List {
//                    // Show all the messages from the current user, filtered by search
//                    ForEach(messageManager.messages.filter { message in
//                        searchText.isEmpty ? true : message.content.contains(searchText)
//                    }) { message in
//                        NavigationLink(destination: MessagingScreenView(currentUserId: authManager.currentUser?.id, otherUserId: message.receiverId, chatId: createChatId(currentUserId: authManager.currentUser?.id, otherUserId: message.receiverId))) {
//                            VStack(alignment: .leading) {
//                                Text(message.receiverName)
//                                    .font(.headline)
//                                Text(message.content)
//                                    .font(.subheadline)
//                                    .foregroundColor(.gray)
//                                Text("\(message.timestamp, style: .time)")
//                                    .font(.footnote)
//                                    .foregroundColor(.gray)
//                            }
//                        }
//                    }
//                }
//                .listStyle(PlainListStyle())
//            }
//            .navigationTitle("Messages")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        showRecipientNameAlert = true
//                    }) {
//                        Image(systemName: "plus.message")
//                            .foregroundStyle(Color.red)
//                    }
//                }
//            }
//            .alert("User Not Found", isPresented: $showUserNotFoundAlert) {
//                Button("OK", role: .cancel) {}
//            } message: {
//                Text("The specified user could not be found.")
//            }
//            .sheet(isPresented: $showRecipientNameAlert) {
//                VStack {
//                    Text("Enter Recipient Name")
//                        .font(.headline)
//                        .padding()
//
//                    TextField("Name", text: $recipientName)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .padding()
//
//                    HStack {
//                        Button("Cancel") {
//                            showRecipientNameAlert = false
//                        }
//                        .padding()
//                        Spacer()
//                        Button("OK") {
//                            if let recipient = users.first(where: { $0.name == recipientName }) {  // Use username property from UserAccountModel
//                                newChatId = createChatId(currentUserId: authManager.currentUser?.id, otherUserId: recipient.id ?? "unknown")
//                                newRecipientId = recipient.id ?? "unknown"
//                                navigateToMessagingScreen(recipient: recipient)
//                            } else {
//                                showUserNotFoundAlert = true
//                            }
//                            showRecipientNameAlert = false
//                        }
//                        .padding()
//                    }
//                }
//                .padding()
//            }
//            .padding()
////            .onAppear {
////                messageManager.fetchUsers { fetchedUsers in
////                    self.users = fetchedUsers  // This should now work
////                }
////                // Fetch all messages for the current user
////                messageManager.fetchMessagesForUser(currentUserId: currentUserId)
////            }
//        }
//    }
//
//    func createChatId(currentUserId: String, otherUserId: String) -> String {
//        return currentUserId < otherUserId ? "\(currentUserId)_\(otherUserId)" : "\(otherUserId)_\(currentUserId)"
//    }
//
//    func navigateToMessagingScreen(recipient: UserAccountModel) {
//        // Implement navigation logic if needed
//    }
//}
//
//#Preview {
//    NewMessageView()
//}
import SwiftUI

struct NewMessageView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var users: [UserAccountModel] = []
    @State private var searchText = ""
    @StateObject private var messageManager = MessageManager()
    @State private var showRecipientNameAlert = false
    @State private var showUserNotFoundAlert = false
    @State private var recipientName = ""
    @State private var newChatId = ""
    @State private var newRecipientId = ""
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        NavigationStack {
            VStack {
                searchBar
                messagesList
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .alert("User Not Found", isPresented: $showUserNotFoundAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The specified user could not be found.")
            }
            .sheet(isPresented: $showRecipientNameAlert) {
                recipientNameSheet
            }
        }
    }
    
    private var searchBar: some View {
        TextField("Search Messages", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
    }
    
    private var messagesList: some View {
        List(filteredMessages) { message in
            NavigationLink(
                destination: MessagingScreenView(
                    currentUserId: authManager.currentUser!.id,
                    otherUserId: message.receiverId,
                    chatId: createChatId(
                        currentUserId: authManager.currentUser?.id,
                        otherUserId: message.receiverId
                    )
                )
            ) {
                messageRow(for: message)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var addButton: some View {
        Button(action: { showRecipientNameAlert = true }) {
            Image(systemName: "plus.message")
                .foregroundStyle(Color.red)
        }
    }
    
    private var recipientNameSheet: some View {
        VStack {
            Text("Enter Recipient Name")
                .font(.headline)
                .padding()
            
            TextField("Name", text: $recipientName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("Cancel") {
                    showRecipientNameAlert = false
                }
                .padding()
                Spacer()
                Button("OK") {
                    handleRecipientName()
                }
                .padding()
            }
        }
        .padding()
    }
    
    private func messageRow(for message: Message) -> some View {
        VStack(alignment: .leading) {
            Text(message.receiverName)
                .font(.headline)
            Text(message.content)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("\(message.timestamp, style: .time)")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
    
    private var filteredMessages: [Message] {
        messageManager.messages.filter { message in
            searchText.isEmpty || message.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func createChatId(currentUserId: String?, otherUserId: String?) -> String {
        guard let currentUserId = currentUserId, let otherUserId = otherUserId else { return "unknown" }
        return currentUserId < otherUserId ? "\(currentUserId)_\(otherUserId)" : "\(otherUserId)_\(currentUserId)"
    }
    
    private func handleRecipientName() {
        if let recipient = users.first(where: { $0.name == recipientName }) {
            newChatId = createChatId(currentUserId: authManager.currentUser?.id, otherUserId: recipient.id)
            newRecipientId = recipient.id ?? ""
            navigateToMessagingScreen(recipient: recipient)
        } else {
            showUserNotFoundAlert = true
        }
        showRecipientNameAlert = false
    }
    
    private func navigateToMessagingScreen(recipient: UserAccountModel) {
        // Implement navigation logic if needed
    }
}

#Preview {
    NewMessageView()
}
