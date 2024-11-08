//
//  MessagingScreenView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/4/24.
//
import SwiftUI

struct MessagingScreenView: View {
    @EnvironmentObject private var userAccountModel: UserAccountModel
    @StateObject private var messageManager = MessageManager() // Use StateObject for proper observation
    @State private var newMessage = ""
    
    let currentUserId: String
    let otherUserId: String
    let chatId: String
    @State private var otherUserName: String = ""
    @State private var otherUserProfileImage: UIImage? = nil // Add profile image state
    
    var body: some View {
        VStack {
            HStack {
                // Display profile image if available
                if let profileImage = otherUserProfileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(.leading)
                }
                
                Text("To: \(otherUserName)")
                    .font(.headline)
                    .padding()
                
                Spacer() // Spacer to align text and image
            }
            
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

                Button(action: sendMessage) {
                    Text("Send")
                }
            }
            .padding()
        }
        .onAppear {
            setupMessagingScreen()
        }
        .onDisappear {
            messageManager.stopListening()
        }
    }
    
    private func setupMessagingScreen() {
        // Fetch other user's name and profile image
        userAccountModel.fetchNameAndProfileImage(userId: otherUserId) { name, image in
            otherUserName = name
            otherUserProfileImage = image
        }
        
        // Fetch full message thread between current user and other user
        messageManager.fetchUserMessages(currentUserId: currentUserId, otherUserId: otherUserId)
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        messageManager.sendMessage(
            currentUserId: currentUserId,
            otherUserId: otherUserId,
            content: newMessage
        )
        newMessage = ""
    }
}

//#Preview {
//    MessagingScreenView(currentUserId: "user2", otherUserId: "user1", chatId: "chat1")
//        .environmentObject(UserAccountModel(from: <#any Decoder#>))
//}
struct MessagingScreenView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUserAccountModel = UserAccountModel(authManager: AuthManager())
        mockUserAccountModel.name = "Test User"
        mockUserAccountModel.email = "test@example.com"
        mockUserAccountModel.city = "Test City"
        mockUserAccountModel.state = "Test State"
        mockUserAccountModel.zipcode = "12345"
        
        return MessagingScreenView(currentUserId: "currentUserId", otherUserId: "otherUserId", chatId: "testChatId")
            .environmentObject(mockUserAccountModel)
            .previewDevice("iPhone 14")
    }
}
