//
//  MessagingScreenView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/4/24.
//
import SwiftUI
import FirebaseAuth

struct MessagingScreenView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var userAccountModel: UserAccountModel
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var messageManager = MessageManager()
    @State private var newMessage = ""
    
    let currentUserId: String
    let otherUserId: String
    let chatId: String
    
    @State private var otherUserName: String = ""
    @State private var otherUserProfileImageUrl: String? = nil
    @State private var otherUserProfileImage: UIImage? = nil
    
    var body: some View {
        VStack {
            HStack {
                // Display profile image or placeholder for otherUserId
                if let profileImageUrl = otherUserProfileImageUrl, !profileImageUrl.isEmpty {
                           AsyncImage(url: URL(string: profileImageUrl)) { image in
                               image
                                   .resizable()
                                   .scaledToFit()
                                   .frame(width: 40, height: 40)
                                   .clipShape(Circle())
                                   .padding(.leading)
                           } placeholder: {
                               // Placeholder while loading the image
                               Circle()
                                   .fill(Color.gray.opacity(0.5))
                                   .frame(width: 40, height: 40)
                                   .padding(.leading)
                           }
                       } else {
                           // Fallback to default gray circle if no image URL is available
                           Circle()
                               .fill(Color.gray.opacity(0.5))
                               .frame(width: 40, height: 40)
                               .padding(.leading)
                       }

                Text(otherUserName.isEmpty ? "Unknown" : "To: \(otherUserName)")
                    .font(.headline)
                    .padding()

                Spacer()
            }
            ScrollView {
                ForEach(messageManager.messages) { message in
                    HStack {
                        if message.senderId == currentUserId {
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(message.content)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                Text(message.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            VStack(alignment: .leading) {
                                Text(message.content)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                                    .foregroundColor(.black)
                                Text(message.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
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
            messageManager.startListeningForMessages(chatId: chatId)
        }
        .onDisappear {
            messageManager.stopListening()
        }
    }
    
    private func setupMessagingScreen() {
        Task {
            do {
                // Fetch both the name and profile image URL
                let (otherName, otherProfileImageUrl) = await userAccountModel.fetchNameAndProfileImage(userId: otherUserId)
                
                // Update the UI on the main thread
                DispatchQueue.main.async {
                    self.otherUserName = otherName
                    self.otherUserProfileImageUrl = otherProfileImageUrl  // Store the URL string here
                }
                
                // Fetch messages scoped to this chat
                try await messageManager.fetchMessages(chatId: chatId, userId: currentUserId)
            } catch {
                print("Error setting up messaging screen: \(error.localizedDescription)")
            }
        }
    }

    func fetchProfileImage(from urlString: String?, placeholder: UIImage?) async -> UIImage? {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return placeholder
        }
        do {
            let data = try await URLSession.shared.data(from: url).0
            return UIImage(data: data) ?? placeholder
        } catch {
            print("Failed to fetch profile image from URL: \(urlString). Error: \(error.localizedDescription)")
            return placeholder
        }
    }
    private func sendMessage() {
        // Ensure the message input is not empty before proceeding
        guard !newMessage.isEmpty else {
            print("Message cannot be empty.")
            return
        }

        Task {
            do {
                // Validate required data
                guard !chatId.isEmpty, !currentUserId.isEmpty, !otherUserId.isEmpty else {
                    print("Chat ID, sender ID, or receiver ID is missing.")
                    return
                }

                guard !userAccountModel.name.isEmpty else {
                    print("Sender name is missing.")
                    return
                }

                // Fetch the current user's profile image URL if not already set
                if userAccountModel.profileImageUrl == nil {
                    await userAccountModel.fetchProfileImageUrl()  // Fetch the profile image URL if it's nil
                }

                // Use the current user's profile image URL
                let senderProfileImageUrl = userAccountModel.profileImageUrl ?? "https://example.com/default_profile_image.png"
                print("Sender Profile Image URL: \(senderProfileImageUrl)") // Debug print

                // Ensure receiver's details are fetched if not already
                if otherUserName.isEmpty || otherUserProfileImageUrl == nil {
                    let (fetchedName, fetchedImageUrl) = await userAccountModel.fetchNameAndProfileImage(userId: otherUserId)

                    DispatchQueue.main.async {
                        self.otherUserName = fetchedName
                        self.otherUserProfileImageUrl = fetchedImageUrl
                    }
                }

                // Send the message using MessageManager
                try await messageManager.sendMessage(
                    chatId: chatId,
                    senderId: currentUserId,
                    receiverId: otherUserId,
                    senderName: userAccountModel.name,
                    receiverName: otherUserName,
                    content: newMessage,
                    timestamp: Date(),
                    senderProfileImage: senderProfileImageUrl,  // Sender's profile image URL
                    receiverProfileImage: otherUserProfileImageUrl // Receiver's profile image URL
                )

                // Clear the message input
                newMessage = ""

            } catch {
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
}

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

//import SwiftUI
//import FirebaseAuth
//
//struct MessagingScreenView: View {
//    @Environment(\.colorScheme) var colorScheme
//    @EnvironmentObject private var userAccountModel: UserAccountModel
//    @EnvironmentObject private var authManager: AuthManager
//    @StateObject private var messageManager = MessageManager()
//    @State private var newMessage = ""
//    
//    let currentUserId: String
//    let otherUserId: String
//    let chatId: String
//    let userAccount = UserAccountModel(authManager: authManager)
//
//    
//    @State private var otherUserName: String = ""
//    @State private var otherUserProfileImageUrl: String? = nil
//    @State private var otherUserProfileImage: UIImage? = nil
//    
//    var body: some View {
//        VStack {
//            HStack {
//                // Display profile image or placeholder for otherUserId
//                if let profileImage = otherUserProfileImage {
//                    Image(uiImage: profileImage)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 40, height: 40)
//                        .clipShape(Circle())
//                        .padding(.leading)
//                } else {
//                    Circle()
//                        .fill(Color.gray.opacity(0.5))
//                        .frame(width: 40, height: 40)
//                        .padding(.leading)
//                }
//
//                Text(otherUserName.isEmpty ? "Unknown" : "To: \(otherUserName)")
//                    .font(.headline)
//                    .padding()
//
//                Spacer()
//            }
//            ScrollView {
//                ForEach(messageManager.messages) { message in
//                    HStack {
//                        if message.senderId == currentUserId {
//                            Spacer()
//                            VStack(alignment: .trailing) {
//                                Text(message.content)
//                                    .padding()
//                                    .background(Color.blue)
//                                    .cornerRadius(10)
//                                    .foregroundColor(.white)
//                                Text(message.timestamp, style: .time)
//                                    .font(.caption)
//                                    .foregroundColor(.gray)
//                            }
//                        } else {
//                            VStack(alignment: .leading) {
//                                Text(message.content)
//                                    .padding()
//                                    .background(Color.green)
//                                    .cornerRadius(10)
//                                    .foregroundColor(.black)
//                                Text(message.timestamp, style: .time)
//                                    .font(.caption)
//                                    .foregroundColor(.gray)
//                            }
//                            Spacer()
//                        }
//                    }
//                    .padding()
//                }
//            }
//
//            HStack {
//                TextField("Message", text: $newMessage)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .frame(minHeight: CGFloat(30))
//
//                Button(action: sendMessage) {
//                    Text("Send")
//                }
//            }
//            .padding()
//        }
//        .onAppear {
//                 setupMessagingScreen()
//                 messageManager.startListeningForMessages(chatId: chatId)
//             }
//             .onDisappear {
//                 messageManager.stopListening()
//             }
//    }
//    private func setupMessagingScreen() {
//           Task {
//               do {
//                   // Fetch other user's details (name and profile image)
//                   let (otherName, otherProfileImage) = await userAccountModel.fetchNameAndProfileImage(userId: otherUserId)
//                   DispatchQueue.main.async {
//                       self.otherUserName = otherName
//                       self.otherUserProfileImage = otherProfileImage
//                   }
//       
//                   // Fetch messages scoped to this chat
//                   try await messageManager.fetchMessages(chatId: chatId, userId: currentUserId)
//               } catch {
//                   print("Error setting up messaging screen: \(error.localizedDescription)")
//               }
//           }
//       }
////        private func setupMessagingScreen() {
////            Task {
////                do {
////                    // Fetch other user's details
////                    let (otherName, otherProfileImage) = await userAccountModel.fetchNameAndProfileImage(userId: otherUserId)
////                    DispatchQueue.main.async {
////                        self.otherUserName = otherName
////                        self.otherUserProfileImage = otherProfileImage
////                    }
////    
////                    // Fetch messages scoped to this chat
////                    try await messageManager.fetchMessages(chatId: chatId, userId: currentUserId)
////                } catch {
////                    print("Error setting up messaging screen: \(error.localizedDescription)")
////                }
////            }
////        }
//
//    private func sendMessage() {
//        guard !newMessage.isEmpty else { return }
//        Task {
//            do {
//                try await messageManager.sendMessage(
//                    chatId: chatId,
//                    senderId: currentUserId,
//                    receiverId: otherUserId,
//                    timestamp: Date(),
//                    senderName: userAccountModel.name,
//                    receiverName: otherUserName,
//                    content: newMessage,
//                    senderProfileImage: userAccountModel.profileImageUrl,  // Send URL
//                    receiverProfileImage: otherUserProfileImageUrl  // Send URL
//                   
//                )
//                newMessage = "" // Reset input field after sending
//            } catch {
//                print("Error sending message: \(error.localizedDescription)")
//            }
//        }
//    }
//}
//
//struct MessagingScreenView_Previews: PreviewProvider {
//    static var previews: some View {
//        let mockUserAccountModel = UserAccountModel(authManager: AuthManager())
//        mockUserAccountModel.name = "Test User"
//        mockUserAccountModel.email = "test@example.com"
//        mockUserAccountModel.city = "Test City"
//        mockUserAccountModel.state = "Test State"
//        mockUserAccountModel.zipcode = "12345"
//        
//        return MessagingScreenView(currentUserId: "currentUserId", otherUserId: "otherUserId", chatId: "testChatId")
//            .environmentObject(mockUserAccountModel)
//            .previewDevice("iPhone 14")
//    }
//}
//    private func setupMessagingScreen() {
//        Task {
//            do {
//                // Fetch other user's details
//                let (otherName, profileImageUrl) = await userAccountModel.fetchNameAndProfileImage(userId: otherUserId)
//                DispatchQueue.main.async {
//                    self.otherUserName = otherName
//                    self.otherUserProfileImageUrl = profileImageUrl  // Assign the URL (String) here
//                }
//
//                // Fetch the profile image for the other user (UIImage)
//                if let imageUrl = otherUserProfileImageUrl, let url = URL(string: imageUrl) {
//                    do {
//                        let imageData = try Data(contentsOf: url)
//                        DispatchQueue.main.async {
//                            self.otherUserProfileImage = UIImage(data: imageData)  // Assign UIImage here
//                        }
//                    } catch {
//                        print("Error fetching image from URL: \(error.localizedDescription)")
//                    }
//                }
//
//                // Fetch messages scoped to this chat
//                try await messageManager.fetchMessages(chatId: chatId)
//            } catch {
//                print("Error setting up messaging screen: \(error.localizedDescription)")
//            }
//        }
//    }

//    private func setupMessagingScreen() {
//        Task {
//            do {
//                // Fetch other user's details
//                let (otherName, profileImageUrl) = await userAccountModel.fetchNameAndProfileImage(userId: otherUserId)
//                DispatchQueue.main.async {
//                    self.otherUserName = otherName
//                    self.otherUserProfileImageUrl = profileImageUrl  // Assign the URL to the profileImageUrl
//                }
//
//                // Fetch the profile image for the other user (UIImage)
//                if let imageUrl = otherUserProfileImageUrl, let url = URL(string: imageUrl) {
//                    do {
//                        let imageData = try Data(contentsOf: url)
//                        DispatchQueue.main.async {
//                            self.otherUserProfileImage = UIImage(data: imageData) // Assign the image to otherUserProfileImage
//                        }
//                    } catch {
//                        print("Error fetching image from URL: \(error.localizedDescription)")
//                    }
//                }
//
//                // Fetch messages scoped to this chat
//                try await messageManager.fetchMessages(chatId: chatId)
//            } catch {
//                print("Error setting up messaging screen: \(error.localizedDescription)")
//            }
//        }
//    }

//    private func setupMessagingScreen() {
//        Task {
//            do {
//                // Fetch other user's details
//                let (otherName, profileImageUrl) = await userAccountModel.fetchNameAndProfileImage(userId: otherUserId)
//                DispatchQueue.main.async {
//                    self.otherUserName = otherName
//                    self.otherUserProfileImageUrl = profileImageUrl
//                }
//
//                // Fetch the profile image for the other user
//                if let imageUrl = otherUserProfileImageUrl {
//                    if let imageData = try? Data(contentsOf: URL(string: imageUrl)!) {
//                        DispatchQueue.main.async {
//                            self.otherUserProfileImage = UIImage(data: imageData)
//                        }
//                    }
//                }
//
//                // Fetch messages scoped to this chat
//                try await messageManager.fetchMessages(chatId: chatId)
//            } catch {
//                print("Error setting up messaging screen: \(error.localizedDescription)")
//            }
//        }
//    }
//import SwiftUI
//
//struct MessagingScreenView: View {
//    @Environment(\.colorScheme) var colorScheme
//    @EnvironmentObject private var userAccountModel: UserAccountModel
//    @StateObject private var messageManager = MessageManager()
//    @State private var newMessage = ""
//    
//    let currentUserId: String // The ID of the currently logged-in user
//    let otherUserId: String   // The ID of the user being messaged
//    let chatId: String        // Unique chat identifier between these users
//    
//    @State private var otherUserName: String = ""
//    @State private var otherUserProfileImage: UIImage? = nil
//
//    var body: some View {
//        VStack {
//            // Header with other user's profile image and name
//            HStack {
//                if let profileImage = otherUserProfileImage {
//                    Image(uiImage: profileImage)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 40, height: 40)
//                        .clipShape(Circle())
//                        .padding(.leading)
//                } else {
//                    Circle()
//                        .fill(Color.gray.opacity(0.5))
//                        .frame(width: 40, height: 40)
//                        .padding(.leading)
//                }
//
//                Text(otherUserName.isEmpty ? "Unknown" : "To: \(otherUserName)")
//                    .font(.headline)
//                    .padding()
//
//                Spacer()
//            }
//            .background(colorScheme == .dark ? Color.black : Color.white)
//            .padding(.top)
//
//            // Message list (ScrollView)
//            ScrollView {
//                VStack(spacing: 12) {
//                    ForEach(messageManager.messages) { message in
//                        HStack {
//                            if message.senderId == currentUserId { // Message from the logged-in user
//                                Spacer()
//                                VStack(alignment: .trailing) {
//                                    Text(message.content)
//                                        .padding()
//                                        .background(Color.blue)
//                                        .cornerRadius(15)
//                                        .foregroundColor(.white)
//                                    Text(message.timestamp, style: .time)
//                                        .font(.caption)
//                                        .foregroundColor(.gray)
//                                }
//                            } else { // Message from the other user
//                                VStack(alignment: .leading) {
//                                    Text(message.content)
//                                        .padding()
//                                        .background(Color.green)
//                                        .cornerRadius(15)
//                                        .foregroundColor(.white)
//                                    Text(message.timestamp, style: .time)
//                                        .font(.caption)
//                                        .foregroundColor(.gray)
//                                }
//                                Spacer()
//                            }
//                        }
//                        .padding(.horizontal)
//                    }
//                }
//            }
//            .padding(.top)
//
//            // Text input and send button
//            HStack {
//                TextField("Message", text: $newMessage)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .padding(.horizontal)
//                    .frame(minHeight: 30)
//
//                Button(action: sendMessage) {
//                    Text("Send")
//                        .fontWeight(.bold)
//                        .foregroundColor(.white)
//                        .padding(.horizontal)
//                        .background(Color.blue)
//                        .cornerRadius(8)
//                }
//            }
//            .padding()
//            .background(Color.white)
//        }
//        .onAppear {
//            setupMessagingScreen()
//        }
//        .onDisappear {
//            messageManager.stopListening()
//        }
//        .navigationTitle("Chat")
//        .navigationBarTitleDisplayMode(.inline)
//        .background(colorScheme == .dark ? Color.black : Color.white)
//    }
//

//    private func sendMessage() {
//        guard !newMessage.isEmpty else { return }
//        
//        // Assuming `userAccountModel` has the current user's details and `otherUserName`, `otherUserProfileImage` are fetched correctly
//        guard let senderName = userAccountModel.name,
//              let receiverName = otherUserName,
//              let senderProfileImage = userAccountModel.profileImage,
//              let receiverProfileImage = otherUserProfileImage else {
//            print("User details are missing.")
//            return
//        }
//        
//        Task {
//            do {
//                try await messageManager.sendMessage(
//                    chatId: chatId,
//                    senderId: currentUserId,
//                    receiverId: otherUserId,
//                    senderName: senderName,
//                    receiverName: receiverName,
//                    content: newMessage,
//                    senderProfileImage: senderProfileImage,
//                    receiverProfileImage: receiverProfileImage)
////                    content: newMessage)
//                newMessage = "" // Reset input field after sending
//            } catch {
//                print("Error sending message: \(error.localizedDescription)")
//            }
//        }
//    }
//}
//
//struct MessagingScreenView_Previews: PreviewProvider {
//    static var previews: some View {
//        let mockUserAccountModel = UserAccountModel(authManager: AuthManager())
//        mockUserAccountModel.name = "Test User"
//        mockUserAccountModel.email = "test@example.com"
//        mockUserAccountModel.city = "Test City"
//        mockUserAccountModel.state = "Test State"
//        mockUserAccountModel.zipcode = "12345"
//        
//        return MessagingScreenView(currentUserId: "currentUserId", otherUserId: "otherUserId", chatId: "testChatId")
//            .environmentObject(mockUserAccountModel)
//            .previewDevice("iPhone 14")
//    }
//}

//    private func sendMessage() {
//        guard !newMessage.isEmpty else { return }
//        Task {
//            do {
//                try await messageManager.sendMessage(
//                    currentUserId: currentUserId,
//                    otherUserId: otherUserId,
//                    content: newMessage
//                )
//                newMessage = "" // Reset input field after sending
//            } catch {
//                print("Error sending message: \(error.localizedDescription)")
//            }
//        }
//    }
//import SwiftUI
//
//
//struct MessagingScreenView: View {
//    @Environment(\.colorScheme) var colorScheme
//
//    @EnvironmentObject private var userAccountModel: UserAccountModel
//    @StateObject private var messageManager = MessageManager()
//    @State private var newMessage = ""
//    
//    let currentUserId: String // The ID of the currently logged-in user
//    let otherUserId: String   // The ID of the user being messaged
//    let chatId: String        // Unique chat identifier between these users
//    
//    @State private var otherUserName: String = ""
//    @State private var otherUserProfileImage: UIImage? = nil
//
//
//    
//    var body: some View {
//        VStack {
//            HStack {
//                // Display profile image or placeholder for `otherUserId`
//                if let profileImage = otherUserProfileImage {
//                    Image(uiImage: profileImage)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 40, height: 40)
//                        .clipShape(Circle())
//                        .padding(.leading)
//                } else {
//                    Circle()
//                        .fill(Color.gray.opacity(0.5))
//                        .frame(width: 40, height: 40)
//                        .padding(.leading)
//                }
//
//                Text(otherUserName.isEmpty ? "Unknown" : "To: \(otherUserName)")
//                    .font(.headline)
//                    .padding()
//
//                Spacer()
//            }
//            ScrollView {
//                ForEach(messageManager.messages) { message in
//                    HStack {
//                        if message.senderId == currentUserId {
//                            Spacer()
//                            VStack(alignment: .trailing) {
//                                Text(message.content)
//                                    .padding()
//                                    .background(Color.blue)
//                                    .cornerRadius(10)
//                                    .foregroundColor(.white)
//                                Text(message.timestamp, style: .time)
//                                    .font(.caption)
//                                    .foregroundColor(.gray)
//                            }
//                        } else {
//                            VStack(alignment: .leading) {
//                                Text(message.content)
//                                    .padding()
//                                    .background(Color.green)
//                                    .cornerRadius(10)
//                                    .foregroundColor(.black)
//                                Text(message.timestamp, style: .time)
//                                    .font(.caption)
//                                    .foregroundColor(.gray)
//                            }
//                            Spacer()
//                        }
//                    }
//                    .padding()
//                }
//            }
//
//            
////            ScrollView {
////                ForEach(messageManager.messages) { message in
////                    HStack {
////                        if message.senderId == currentUserId { // Message from the logged-in user
////                            Spacer()
////                            VStack(alignment: .trailing) {
////                                Text(message.content)
////                                    .padding()
////                                    .background(Color.blue)
////                                    .cornerRadius(10)
////                                    .foregroundColor(.white)
////                                Text(message.timestamp, style: .time)
////                                    .font(.caption)
////                                    .foregroundColor(.gray)
////                            }
////                        } else { // Message from the other user
////                            VStack(alignment: .leading) {
////                                Text(message.content)
////                                    .padding()
////                                    .background(Color.green)
////                                    .cornerRadius(10)
////                                    .foregroundColor(.black)
////                                Text(message.timestamp, style: .time)
////                                    .font(.caption)
////                                    .foregroundColor(.gray)
////                            }
////                            Spacer()
////                        }
////                    }
////                    .padding()
////                }
////            }
//
//            HStack {
//                TextField("Message", text: $newMessage)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .frame(minHeight: CGFloat(30))
//
//                Button(action: sendMessage) {
//                    Text("Send")
//                }
//            }
//            .padding()
//        }
//        .onAppear {
//            setupMessagingScreen()
//        }
//        .onDisappear {
//            messageManager.stopListening()
//        }
//    }
//    
////    private func setupMessagingScreen() {
////        Task {
////            do {
////                // Fetch other user's details
////                let (otherName, otherProfileImage) = await userAccountModel.fetchNameAndProfileImage(userId: otherUserId)
////                DispatchQueue.main.async {
////                    self.otherUserName = otherName
////                    self.otherUserProfileImage = otherProfileImage
////                }
////
////                // Fetch messages scoped to this chat
////                try await messageManager.fetchMessages(chatId: chatId)
////            } catch {
////                print("Error setting up messaging screen: \(error.localizedDescription)")
////            }
////        }
////    }
//    private func setupMessagingScreen() {
//        Task {
//            do {
//                // Fetch other user's details
//                let (otherName, otherProfileImage) = await userAccountModel.fetchNameAndProfileImage(userId: otherUserId)
//                DispatchQueue.main.async {
//                    self.otherUserName = otherName
//                    self.otherUserProfileImage = otherProfileImage
//                }
//
//                // Fetch messages scoped to this chat
//                try await messageManager.fetchMessages(chatId: chatId)
//            } catch {
//                print("Error setting up messaging screen: \(error.localizedDescription)")
//            }
//        }
//    }
//
//
//    private func sendMessage() {
//        guard !newMessage.isEmpty else { return }
//        Task {
//            do {
//                try await messageManager.sendMessage(
//                    currentUserId: currentUserId,
//                    otherUserId: otherUserId,
//                    content: newMessage
//                )
//                newMessage = ""
//            } catch {
//                print("Error sending message: \(error.localizedDescription)")
//            }
//        }
//    }
//}
//
////#Preview {
////    MessagingScreenView(currentUserId: "user2", otherUserId: "user1", chatId: "chat1")
////        .environmentObject(UserAccountModel(from: <#any Decoder#>))
////}
//struct MessagingScreenView_Previews: PreviewProvider {
//    static var previews: some View {
//        let mockUserAccountModel = UserAccountModel(authManager: AuthManager())
//        mockUserAccountModel.name = "Test User"
//        mockUserAccountModel.email = "test@example.com"
//        mockUserAccountModel.city = "Test City"
//        mockUserAccountModel.state = "Test State"
//        mockUserAccountModel.zipcode = "12345"
//        
//        return MessagingScreenView(currentUserId: "currentUserId", otherUserId: "otherUserId", chatId: "testChatId")
//            .environmentObject(mockUserAccountModel)
//            .previewDevice("iPhone 14")
//    }
//}
//
//    init?(currentUserId: String, otherUserId: String, chatId: String) {
//        guard currentUserId != otherUserId else {
//            print("Error: currentUserId and otherUserId should be distinct.")
//            return nil
//        }
//        self.currentUserId = currentUserId
//        self.otherUserId = otherUserId
//        self.chatId = chatId
//    }
