//
//  NewMessageView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/11/24.
//
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
            .onAppear {
                loadMessages() // Fetch all messages when the view appears
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
                    currentUserId: authManager.currentUser?.id ?? "Unknown",
                    otherUserId: getOtherUserId(for: message),
                    chatId: getOrCreateChatId(currentUserId: authManager.currentUser?.id, otherUserId: getOtherUserId(for: message))
                )
                .onAppear {
                    markMessageAsRead(for: message)
                }
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
                    Task {
                        await handleRecipientName()
                    }
                }
                .padding()
            }
        }
        .padding()
    }

    private func messageRow(for message: Message) -> some View {
        HStack {
            if let profileImage = getProfileImage(for: message) {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading) {
                Text(getUserName(for: message))
                    .font(.headline)
                Text(message.content)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            if !(message.isRead ?? false) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
            }
        }
        .padding()
    }

    private var filteredMessages: [Message] {
        let currentUserId = authManager.currentUser?.id ?? ""
        return messageManager.messages.filter { message in
            (message.senderId == currentUserId || message.receiverId == currentUserId) &&
            (searchText.isEmpty || message.content.localizedCaseInsensitiveContains(searchText))
        }
    }
    private func loadMessages() {
        if let currentUserId = authManager.currentUser?.id {
            print("Fetching messages for user: \(currentUserId)") // Debug print
            
            Task {
                do {
                    // Fetch sent and received messages for the current user
                    try await messageManager.fetchMessagesForUser(currentUserId: currentUserId)
                    print("Messages fetched successfully: \(messageManager.messages)") // Log the fetched messages
                } catch {
                    print("Error fetching messages: \(error)")
                }
            }
        } else {
            print("Current user ID is not available.")
        }
    }

    private func createChatId(currentUserId: String?, otherUserId: String?) -> String {
        guard let currentUserId = currentUserId, let otherUserId = otherUserId else { return "unknown" }
        return currentUserId < otherUserId ? "\(currentUserId)_\(otherUserId)" : "\(otherUserId)_\(currentUserId)"
    }

    private func handleRecipientName() async {
        if let recipient = users.first(where: { $0.name == recipientName }) {
            newChatId = createChatId(currentUserId: authManager.currentUser?.id, otherUserId: recipient.id)
            newRecipientId = recipient.id ?? ""
            navigateToMessagingScreen(recipient: recipient)
        } else {
            showUserNotFoundAlert = true
        }
        showRecipientNameAlert = false
    }

    private func getOrCreateChatId(currentUserId: String?, otherUserId: String?) -> String {
        guard let currentUserId = currentUserId, let otherUserId = otherUserId else { return "unknown" }

        let chatId = createChatId(currentUserId: currentUserId, otherUserId: otherUserId)
        Task {
            do {
                try await messageManager.getOrCreateChatId(currentUserId: currentUserId, otherUserId: otherUserId)
            } catch {
                print("Error checking or creating chat: \(error)")
            }
        }
        return chatId
    }

    private func getProfileImage(for message: Message) -> UIImage? {
        if let user = users.first(where: { $0.id == getOtherUserId(for: message) }) {
            if let base64String = user.profileImageUrl {
                return base64String.toUIImage()
            } else {
                return user.profileImage
            }
        }
        return nil
    }

    private func getOtherUserId(for message: Message) -> String {
        return message.senderId == authManager.currentUser?.id ? message.receiverId : message.senderId
    }

    private func getUserName(for message: Message) -> String {
        if message.senderName.isEmpty {
            if let user = users.first(where: { $0.id == message.senderId }) {
                return user.name
            }
            return "Unknown"
        }
        return message.senderName
    }


    private func markMessageAsRead(for message: Message) {
        if let messageId = message.id {
            Task {
                do {
                    try await messageManager.markMessageAsRead(
                        chatId: getOrCreateChatId(
                            currentUserId: authManager.currentUser?.id,
                            otherUserId: getOtherUserId(for: message)
                        ),
                        messageId: messageId
                    )
                } catch {
                    print("Error marking message as read: \(error)")
                }
            }
        }
    }

    private func navigateToMessagingScreen(recipient: UserAccountModel) {
        // Implement navigation logic here
    }
}


//
//#Preview {
//    NewMessageView()
//}
