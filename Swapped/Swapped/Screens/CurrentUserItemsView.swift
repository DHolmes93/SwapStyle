//
//  CurrentUserItems.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/4/24.
//
//import SwiftUI
//import Firebase
//import FirebaseAuth
//import FirebaseFirestore
//import FirebaseFirestoreSwift
//import SDWebImage
//
//struct CurrentUserItemsView: View {
//    var itemToSwap: Item?
//    var fromUserName: String?
//    var toUserName: String?
////    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
//    @State private var initiateSwap = false
//    @EnvironmentObject private var itemManager: ItemManager
//    @EnvironmentObject private var swapCart: SwapCart
//    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())
//    @State private var swapRequestSentMessage: String? // Holds success message
//    @State private var showConfirmation: Bool = false // Controls visibility of message
//    @Environment(\.presentationMode) var presentationMode
//    
//    // Make sure the user is authenticated before loading items
//    @State private var isUserAuthenticated = false
//    @State private var sentSwapRequests: [String] = [] // Track sent swap request item IDs
//
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                if isUserAuthenticated {
//                    LazyVStack {
//                        ForEach(itemManager.items.filter { $0.userName == viewModel.name }) { item in
//                            itemRowView(item: item)
//                                .padding(.horizontal)
//                                .padding(.top, 5)
//                        }
//                    }
//                } else {
//                    Text("You must be logged in to view your items.")
//                        .padding()
//                }
//            }
//            .navigationTitle("My Items")
//            .onAppear {
//                checkAuthenticationStatus()
//            }
//        }
//    }
//    
//    private func checkAuthenticationStatus() {
//        if let currentUser = Auth.auth().currentUser {
//            isUserAuthenticated = true
//            // Fetch user name
//            fetchCurrentUserName()
//        } else {
//            isUserAuthenticated = false
//            print("User is not authenticated.")
//        }
//    }
//    
//    private func fetchCurrentUserName() {
//        Task {
//            do {
//                // Fetch current user details
//                await viewModel.fetchName() // Assuming fetchName is a method in UserAccountModel that fetches the user's name
//                fetchItems() // Fetch items only after user name is fetched
//                fetchSentSwapRequests() // Fetch the sent swap requests after fetching items
//            } catch {
//                print("Error fetching user name: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    private func fetchItems() {
//        Task {
//            do {
//                let items = try await itemManager.fetchItems()
//                itemManager.items = items
//            } catch {
//                print("Error fetching items: \(error.localizedDescription)")
//            }
//        }
//    }
//
//    // Fetch the swap requests that have been sent
//    private func fetchSentSwapRequests() {
//        Task {
//            do {
//                let requests = try await itemManager.fetchSwapRequests(fromUserId: viewModel.id ?? "")
//                sentSwapRequests = requests.map { $0.toItemId }
//            } catch {
//                print("Error fetching swap requests: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    @ViewBuilder
//    func itemRowView(item: Item) -> some View {
//        HStack {
//            // Display item image (if available)
//            if let imageUrlString = item.imageUrls.first, let url = URL(string: imageUrlString) {
//                AsyncImage(url: url) { image in
//                    image
//                        .resizable()
//                        .aspectRatio(contentMode: .fill)
//                        .frame(width: 40, height: 40)
//                        .clipShape(RoundedRectangle(cornerRadius: 8))
//                } placeholder: {
//                    ProgressView()
//                        .frame(width: 40, height: 40)
//                }
//            } else {
//                // Placeholder image if no URL is available
//                Image(systemName: "photo")
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: 40, height: 40)
//                    .clipShape(RoundedRectangle(cornerRadius: 8))
//                    .foregroundColor(.gray)
//            }
//            
//            // Item name
//            Text(item.name)
//                .font(.headline)
//                .lineLimit(1)
//                .padding(.leading, 8)
//            
//            Spacer()
//            
//            // Navigation link to edit the item
//            NavigationLink(destination: EditItemView(item: item)) {
//                Text("Edit")
//                    .foregroundColor(.blue)
//                    .padding(.horizontal)
//                    .padding(.vertical, 6)
//                    .background(Color.gray.opacity(0.2))
//                    .cornerRadius(8)
//            }
//            
//            // Initiate swap button
//            initiateSwapButton(for: item)
//        }
//        .padding()
//    }
//
//    // Check if a swap request has been sent for the item
//    private func isSwapRequestSent(for item: Item) -> Bool {
//        return sentSwapRequests.contains(item.id ?? "")
//    }
//
//    func initiateSwapButton(for item: Item) -> some View {
//        let alreadyInitiated = isSwapRequestSent(for: item)
//        
//        return Button(action: {
//            if !alreadyInitiated {
//                print("Initiating swap for item: \(item.id ?? "nil")") // Debug the item ID
//                Task {
//                    await initiateSwapAction(for: item)
//                    sentSwapRequests.append(item.id ?? "") // Mark as sent swap request
//                    showConfirmation = true // Trigger the alert after the swap action
//                }
//            }
//        }) {
//            Text(alreadyInitiated ? "Swap Initiated" : "Initiate Swap")
//                .foregroundColor(alreadyInitiated ? .gray : .blue)
//                .padding(.horizontal)
//                .padding(.vertical, 6)
//                .background(alreadyInitiated ? Color.gray.opacity(0.4) : Color.gray.opacity(0.2))
//                .cornerRadius(8)
//        }
//        .padding(.trailing)
//        .disabled(alreadyInitiated) // Disable the button if swap request is already initiated
//        .alert(isPresented: $showConfirmation) {
//            Alert(
//                title: Text("Swap Request Sent"),
//                message: Text(swapRequestSentMessage ?? "Your swap request has been sent successfully."),
//                dismissButton: .default(Text("OK"), action: {
//                    // Dismiss the current view
//                    presentationMode.wrappedValue.dismiss()
//                })
//            )
//        }
//    }
//    
//    private func initiateSwapAction(for item: Item) {
//        guard let itemToSwap = itemToSwap else {
//            print("No item to swap with.")
//            return
//        }
//        
//        guard let fromItemId = item.id, !fromItemId.isEmpty else {
//            print("Invalid fromItemId: \(item.id ?? "nil")")
//            return
//        }
//        
//        guard let toItemId = itemToSwap.id, !toItemId.isEmpty else {
//            print("Invalid toItemId: \(itemToSwap.id ?? "nil")")
//            return
//        }
//        
//        let fromUserName = item.userName
//        let toUserName = itemToSwap.userName
//        
//        print("From Username: \(fromUserName), To Username: \(toUserName)")
//        
//        Task {
//            do {
//                // Proceed with the swap request
//                try await itemManager.requestSwap(
//                    fromItemId: fromItemId,
//                    toUserId: itemToSwap.uid,
//                    toItemId: toItemId,
//                    fromUserName: fromUserName,
//                    toUserName: toUserName,
//                    timestamp: Date()
//                )
//                
//                // Update the confirmation message
//                swapRequestSentMessage = "Swap request sent to \(toUserName)."
//                showConfirmation = true
//                
//                print("Swap request sent successfully")
//            } catch {
//                // Log and optionally handle the error
//                print("Failed to send swap request: \(error.localizedDescription)")
//            }
//        }
//    }
//}

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import SDWebImage

struct CurrentUserItemsView: View {
    var itemToSwap: Item?
    var fromUserName: String?
    var toUserName: String?
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
    @State private var initiateSwap = false
    @EnvironmentObject private var itemManager: ItemManager
    @EnvironmentObject private var swapCart: SwapCart
    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())
    @State private var swapRequestSentMessage: String? // Holds success message
    @State private var showConfirmation: Bool = false // Controls visibility of message
    @State private var isSwapInProgress = false // Track swap status
    @Environment(\.presentationMode) var presentationMode
    
    
    // Make sure the user is authenticated before loading items
    @State private var isUserAuthenticated = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isUserAuthenticated {
                    LazyVStack {
                        ForEach(itemManager.items.filter { $0.userName == viewModel.name }) { item in
                            itemRowView(item: item)
                                .padding(.horizontal)
                                .padding(.top, 5)
                        }
                    }
                } else {
                    Text("You must be logged in to view your items.")
                        .padding()
                }
            }
            .navigationTitle("My Items")
            .onAppear {
                checkAuthenticationStatus()
            }
//            .navigationDestination(isPresented: $isSwapInProgress) {
//                           // Navigate to the SwappedItemsView
//                           SwappedItemsView()
//                               .environmentObject(swapCart) // Pass the environment object
//            }
        }
    }
    
    private func checkAuthenticationStatus() {
        if Auth.auth().currentUser != nil {
            isUserAuthenticated = true
            // Fetch user name
            fetchCurrentUserName()
        } else {
            isUserAuthenticated = false
            print("User is not authenticated.")
        }
    }
    
    private func fetchCurrentUserName() {
        Task {
            do {
                // Fetch current user details
                await viewModel.fetchName() // Assuming fetchName is a method in UserAccountModel that fetches the user's name
                fetchItems() // Fetch items only after user name is fetched
            } catch {
                print("Error fetching user name: \(error.localizedDescription)")
            }
        }
    }
    private func fetchSentSwapRequests() {
          Task {
              do {
                  _ = try await itemManager.fetchSwapRequests(fromUserId: viewModel.id ?? "")
//                  sentSwapRequests = requests.map { $0.toItemId }
              } catch {
                  print("Error fetching swap requests: \(error.localizedDescription)")
              }
          }
      }
    
    private func fetchItems() {
        Task {
            do {
                let items = try await itemManager.fetchItems()
                itemManager.items = items
            } catch {
                print("Error fetching items: \(error.localizedDescription)")
            }
        }
    }
    
    @ViewBuilder
    func itemRowView(item: Item) -> some View {
        HStack {
            // Display item image (if available)
            if let imageUrlString = item.imageUrls.first, let url = URL(string: imageUrlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    ProgressView()
                        .frame(width: 40, height: 40)
                }
            } else {
                // Placeholder image if no URL is available
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .foregroundColor(.gray)
            }
            
            // Item name
            Text(item.name)
                .font(.headline)
                .lineLimit(1)
                .padding(.leading, 8)
            
            Spacer()
            
            // Navigation link to edit the item
            NavigationLink(destination: EditItemView(item: item)) {
                Text("Edit")
                    .foregroundColor(.blue)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Initiate swap button
            initiateSwapButton(for: item)
        }
        .padding()
    }
    
    func initiateSwapButton(for item: Item) -> some View {
        Button(action: {
            print("Initiating swap for item: \(item.id ?? "nil")") // Debug the item ID
            Task {
                await initiateSwapAction(for: item)
                showConfirmation = true // Trigger the alert after the swap action
            }
        }) {
            Text("Initiate Swap")
                .foregroundColor(.blue)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(.trailing)
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("Swap Request Sent"),
                message: Text(swapRequestSentMessage ?? "Your swap request has been sent successfully."),
                dismissButton: .default(Text("OK"), action: {
                    // Dismiss the current view
                    presentationMode.wrappedValue.dismiss()
                })
            )
        }
    }
    
    private func fetchItem(for item: Item) async throws -> Item? {
        // Log the start of the fetch operation
        print("Fetching item ID: \(item.id ?? "Unknown item ID") for user: \(item.uid)")
        
        // Create Firestore reference for the specific item
        let itemRef = Firestore.firestore()
            .collection("users")
            .document(item.uid)
            .collection("items")
            .document(item.id ?? "")
        
        do {
            // Attempt to fetch the item document snapshot
            let snapshot = try await itemRef.getDocument()
            guard snapshot.exists else {
                print("Item not found for ID: \(item.id ?? "Unknown item ID")")
                return nil
            }
            
            // Decode the document into the Item model
            return try snapshot.data(as: Item.self)
        } catch {
            // Log the error and rethrow it
            print("Error fetching item: \(error.localizedDescription)")
            throw error
        }
    }
    
    // In your swap initiation logic
    private func initiateSwapAction(for item: Item) {
        guard let itemToSwap = itemToSwap else {
            print("No item to swap with.")
            return
        }
        
        guard let fromItemId = item.id, !fromItemId.isEmpty else {
            print("Invalid fromItemId: \(item.id ?? "nil")")
            return
        }
        
        guard let toItemId = itemToSwap.id, !toItemId.isEmpty else {
            print("Invalid toItemId: \(itemToSwap.id ?? "nil")")
            return
        }
        
        let fromUserName = item.userName
        let toUserName = itemToSwap.userName
        
        print("From Username: \(fromUserName), To Username: \(toUserName)")
        
        Task {
            do {
                // Proceed with the swap request
                try await itemManager.requestSwap(
                    fromItemId: fromItemId,
                    toUserId: itemToSwap.uid,
                    toItemId: toItemId,
                    fromUserName: fromUserName,
                    toUserName: toUserName,
                    itemName: itemToSwap.name,
                    timestamp: Date()
                )
                
                // Update the confirmation message
                swapRequestSentMessage = "Swap request sent to \(toUserName)."
                showConfirmation = true
                
                print("Swap request sent successfully")
            } catch {
                // Log and optionally handle the error
                print("Failed to send swap request: \(error.localizedDescription)")
            }
        }
    }
}
//
//#Preview {
//    let itemManager = ItemManager.shared
//    let swapCart = SwapCart.shared
//          itemManager.items = [
//              Item(name: "Sample Item 1",
//                   details: "Details 1",
//                   originalprice: 19.99,
//                   value: 10,
//                   imageUrls: ["https://via.placeholder.com/150"],
//                   condition: "New",
//                   timestamp: Date(),
//                   uid: "uid1",
//                   category: "Category 1", subcategory: "Sd",
//                   userName: "User 1",
//                   latitude: 0.0,
//                   longitude: 0.0),
//              
//              Item(name: "Sample Item 2",
//                   details: "Details 2",
//                   originalprice: 29.99,
//                   value: 34,
//                   imageUrls: ["https://via.placeholder.com/150"],
//                   condition: "Used",
//                   timestamp: Date(),
//                   uid: "uid2",
//                   category: "Category 2", subcategory: "DDE",
//                   userName: "User 2",
//                   latitude: 0.0,
//                   longitude: 0.0)
//          ]
//          
//          return CurrentUserItemsView()
//              .environmentObject(itemManager)
//              .environmentObject(swapCart)
//}
