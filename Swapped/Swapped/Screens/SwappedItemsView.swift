//
//  SwappedView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//
//

//import SwiftUI
//import FirebaseAuth
import SwiftUI
import FirebaseAuth

struct SwappedItemsView: View {
    @State private var swapRequests: [SwapRequest] = []
    @State private var isLoading = true
    @EnvironmentObject var itemManager: ItemManager
    @EnvironmentObject var messageManager: MessageManager
    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())
    @State private var messageRecipientId: String?
    @State private var chatId: String?
    @State private var currentUserId: String = Auth.auth().currentUser?.uid ?? ""
    @State private var otherUserId: String = "" // You'll assign this later
    @State private var messages: [Message] = [] // Store fetched messages here

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Swap Requests...")
                        .padding()
                } else if swapRequests.isEmpty {
                    Text("No swap requests found.")
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(swapRequests) { request in
                                HStack(alignment: .top, spacing: 16) {
                                    // Left Item Image
                                    itemImageView(for: request.fromItemId, label: "From User")
                                    
                                    // Swap Symbol
                                    swapSymbol
                                    
                                    // Right Item Image
                                    itemImageView(for: request.toItemId, label: "To User")
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        
                                        // Status and Date
                                        statusAndDateView(for: request)
                                            
                                        
                                        // Conditional logic for buttons
                                        if request.toUserId == Auth.auth().currentUser?.uid && request.status == .pending {
                                            HStack {
                                                // Approve Button
                                                Button(action: {
                                                    Task {
                                                        await approveSwapRequest(swapRequestId: request.id)
                                                    }
                                                }) {
                                                    Text("Approve")
                                                        .font(.subheadline)
                                                        .foregroundColor(.white)
                                                        .padding(4)
                                                        .background(Color.green)
                                                        .cornerRadius(6)
                                                }
                                                
                                                // Reject Button
                                                Button(action: {
                                                    Task {
                                                        try? await itemManager.rejectSwapRequest(swapRequestId: request.id)
                                                        
                                                        // Optionally update UI after rejecting the request
                                                        if let index = swapRequests.firstIndex(where: { $0.id == request.id }) {
                                                            swapRequests[index].status = .rejected
                                                        }
                                                    }
                                                }) {
                                                    Text("Reject")
                                                        .font(.subheadline)
                                                        .foregroundColor(.white)
                                                        .padding(4)
                                                        .background(Color.red)
                                                        .cornerRadius(6)
                                                }
                                            }
                                        } else if request.fromUserId == Auth.auth().currentUser?.uid && request.status == .pending {
                                            Text("Waiting for user")
                                                .font(.subheadline)
                                                .foregroundColor(.orange)
                                                .padding(6)
                                                .background(Color.orange.opacity(0.2))
                                                .cornerRadius(8)
                                        } else if request.status == .accepted {
                                            NavigationLink(
                                                destination: MessagingScreenView(
                                                    currentUserId: currentUserId,
                                                    otherUserId: request.toUserId == Auth.auth().currentUser?.uid ? request.fromUserId : request.toUserId,
                                                    chatId: generateChatId(fromUserId: currentUserId, toUserId: request.toUserId == Auth.auth().currentUser?.uid ? request.fromUserId : request.toUserId)
                                                )
                                            ) {
                                                Text("Message")
                                                    .font(.subheadline)
                                                    .foregroundColor(.blue)
                                                    .padding(6)
                                                    .background(Color.blue.opacity(0.2))
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding(.leading, 8)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .navigationTitle("Swaps")
            .onAppear(perform: fetchSwapRequests)
        }
    }

    // MARK: - Helper Views and Methods
    
    private func itemImageView(for itemId: String, label: String) -> some View {
        VStack {
            if let itemImageURL = itemManager.getItemImageURL(for: itemId) {
                AsyncImage(url: itemImageURL) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    ProgressView()
                        .frame(width: 60, height: 60)
                }
            } else {
                placeholderImage
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var swapSymbol: some View {
        Image(systemName: "arrow.left.arrow.right")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 30, height: 30)
            .foregroundColor(.blue)
    }

    private func statusAndDateView(for request: SwapRequest) -> some View {
        VStack(alignment: .leading) {
            Text("Status: \(request.status.rawValue)")
                .font(.subheadline)
                .foregroundColor(statusColor(for: request.status))
            Text(request.timestamp, formatter: itemDateFormatter)
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }

    private func fetchSwapRequests() {
        guard let currentUser = Auth.auth().currentUser else {
            print("User not authenticated.")
            return
        }
        
        Task {
            do {
                let requests = try await itemManager.fetchSwapRequests(fromUserId: currentUser.uid)
                DispatchQueue.main.async {
                    self.swapRequests = requests
                    self.isLoading = false
                }
            } catch {
                print("Error fetching swap requests: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }

    private func approveSwapRequest(swapRequestId: String) async {
        guard Auth.auth().currentUser != nil else { return }
        
        do {
            try await itemManager.acceptSwapRequest(swapRequestId: swapRequestId)
            
            // Update UI after successful swap approval
            if let index = swapRequests.firstIndex(where: { $0.id == swapRequestId }) {
                swapRequests[index].status = .accepted
            }
        } catch {
            print("Error accepting swap request: \(error.localizedDescription)")
        }
    }

    private func statusColor(for status: SwapRequestStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .rejected: return .red
        }
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 60, height: 60)
            .cornerRadius(8)
    }

    private func generateChatId(fromUserId: String, toUserId: String) -> String {
        // Generate a unique chat ID by combining the two user IDs (or any other unique logic you prefer)
        let userIds = [fromUserId, toUserId].sorted()
        return "\(userIds[0])-\(userIds[1])"
    }

    private let itemDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}


//
//#Preview {
//    let mockItem1 = Item(
//            name: "Flower Pot",
//            details: "Round",
//            originalprice: 120.0,
//            value: 80,
//            imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
//            condition: "Good",
//            timestamp: Date(),
//            uid: "45768403j",
//            category: "Sports", subcategory: "Basketball",
//            userName: "Flower Pot",
//            latitude: 0.0,
//            longitude: 0.0
//        )
//
//        let mockItem2 = Item(
//            name: "Sample Item 2",
//            details: "Sample details",
//            originalprice: 80.0,
//            value: 45,
//            imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
//            condition: "Good",
//            timestamp: Date(),
//            uid: "45768403j",
//            category: "Electronics", subcategory: "Laptop",
//            userName: "Flower Pot",
//            latitude: 0.0,
//            longitude: 0.0
//        )
//
//        let cart = SwapCart.shared
//        cart.addItem(mockItem1)
//        cart.addItem(mockItem2)
//
//        return SwappedItemsView().environmentObject(cart)
//}
