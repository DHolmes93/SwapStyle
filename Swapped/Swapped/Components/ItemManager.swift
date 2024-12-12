//
//  ItemModel.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseAuth
import CoreLocation
import SwiftUICore

class ItemManager: ObservableObject {
    static let shared = ItemManager()
    @Published var items: [Item] = []
    @Published var itemsByDistance: [String: [Item]] = [
        "5km": [],
        "15km": [],
        "25km": [],
        "50km+": []
    ]
    private let authManager = AuthManager.shared
    private let userAccountModel = UserAccountModel.shared
    @EnvironmentObject private var locationManager: LocationManager
    private let categoryManager = CategoryManager.shared
    private let db = Firestore.firestore()
    private var viewTimers: [String: Timer] = [:]
    private var viewDurations: [String: Int] = [:]
    @Published var selectedCategory: Category? // assuming Category is Equatable
    @Published var selectedSubcategory: Category?

    init() {}

    func uploadItem(
        userAccountModel: UserAccountModel,
        images: [UIImage],
        name: String,
        details: String,
        originalprice: Double,
        value: Double,
        condition: String,
        timestamp: Date,
        selectedCategory: String,
        selectedSubCategory: String
        
    ) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "No user logged in", code: 401, userInfo: nil)
        }

        let itemImagesRef = Storage.storage().reference().child("item_images")
        var imageUrls: [String] = []

        for image in images {
            let imageName = UUID().uuidString
            let imageRef = itemImagesRef.child("\(imageName).jpg")
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "Image Conversion Error", code: 500, userInfo: nil)
            }

            try await imageRef.putDataAsync(imageData, metadata: nil)
            let url = try await imageRef.downloadURL()
            imageUrls.append(url.absoluteString)
        }
        guard !selectedCategory.isEmpty, !selectedSubCategory.isEmpty else {
               throw NSError(domain: "Category and subcategory must not be empty", code: 400, userInfo: nil)
           }
        let userName = userAccountModel.name
        let (location, _, _, _, _) = try await LocationManager.shared.getCurrentLocation()
        let itemData: [String: Any] = [
            "uid": uid,
            "name": name,
            "details": details,
            "originalprice": originalprice,
            "value": value,
            "condition": condition,
            "timestamp": Timestamp(date: timestamp),
            "selectedCategory": selectedCategory,
            "selectedSubCategory": selectedSubCategory,
            "imageUrls": imageUrls,
            "userName": userName,
            "latitude": location?.latitude ?? 0.0, // Default latitude
            "longitude": location?.longitude ?? 0.0 // Default longitude
        ]


        try await db.collection("users").document(uid).collection("items").addDocument(data: itemData)
    }

    func deleteItem(itemId: String) async throws {
        let userUid = Auth.auth().currentUser?.uid ?? ""
        let itemRef = db.collection("users").document(userUid).collection("items").document(itemId)
        try await itemRef.delete()
        items.removeAll { $0.uid == itemId }
    }

    func updateItem(_ item: Item) async throws {
        guard let userUid = Auth.auth().currentUser?.uid else { return }
        let itemRef = db.collection("users").document(userUid).collection("items").document(item.uid)
        try await itemRef.setData(from: item)
    }
    
    func fetchItems() async throws -> [Item] {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "No user logged in", code: 401, userInfo: nil)
        }

        // Fetch items from Firestore
        let userItemsRef = db.collection("users").document(uid).collection("items")
        let snapshot = try await userItemsRef.getDocuments()
        let items = snapshot.documents.compactMap { document in
            var item = try? document.data(as: Item.self)
            item?.id = document.documentID
            return item
        }

        // Get the user's current location
        let userCoordinates = try await LocationManager.shared.getCurrentLocation().0

        guard let userCoordinates = userCoordinates else {
            throw NSError(domain: "User location not available", code: 0, userInfo: nil)
        }

        let userLocation = CLLocation(latitude: userCoordinates.latitude, longitude: userCoordinates.longitude)

        // Sort items by distance to user's location
        let sortedItems = items.sorted { item1, item2 in
            let distance1 = item1.distance(to: userLocation)
            let distance2 = item2.distance(to: userLocation)
            return distance1 < distance2
        }

        // Update internal state
        self.items = sortedItems
        return sortedItems
    }
    func fetchItemsforUser(for userUID: String) async throws -> [Item] {
        // Reference the Firestore collection for the specified user
        let userItemsRef = db.collection("users").document(userUID).collection("items")
        let snapshot = try await userItemsRef.getDocuments()

        // Parse the documents into Item objects
        let items = snapshot.documents.compactMap { document in
            var item = try? document.data(as: Item.self)
            item?.id = document.documentID
            return item
        }

        // Get the user's current location
        let userCoordinates = try await LocationManager.shared.getCurrentLocation().0

        guard let userCoordinates = userCoordinates else {
            throw NSError(domain: "User location not available", code: 0, userInfo: nil)
        }

        let userLocation = CLLocation(latitude: userCoordinates.latitude, longitude: userCoordinates.longitude)

        // Sort items by distance to the user's location
        let sortedItems = items.sorted { item1, item2 in
            let distance1 = item1.distance(to: userLocation)
            let distance2 = item2.distance(to: userLocation)
            return distance1 < distance2
        }

        // Update internal state if needed
        self.items = sortedItems
        return sortedItems
    }
    func fetchItemsForCurrentUser() async throws -> [Item] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "No user logged in", code: 401, userInfo: nil)
        }
        return try await fetchItems(for: currentUserId)
    }

    func fetchItemsForOtherUser(otherUserId: String) async throws -> [Item] {
        return try await fetchItems(for: otherUserId)
    }

    private func fetchItems(for userId: String) async throws -> [Item] {
        let userItemsRef = db.collection("users").document(userId).collection("items")
        let snapshot = try await userItemsRef.getDocuments()

        let items = snapshot.documents.compactMap { document in
            var item = try? document.data(as: Item.self)
            item?.id = document.documentID
            return item
        }

        if userId == Auth.auth().currentUser?.uid {
            self.items = items // Update current user's items only
        }
        return items
    }
    
//    // MARK: - Request Swap
    // MARK: - Request Swap
    // MARK: - Request Swap
    func requestSwap(
        fromItemId: String,
        toUserId: String,
        toItemId: String,
        fromUserName: String,
        toUserName: String,
        itemName: String,
        timestamp: Date
    ) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "No user logged in", code: 401, userInfo: nil)
        }
        
        let swapRequestId = UUID().uuidString

        do {
            // Create the swap request data
            let swapRequest: [String: Any] = [
                "id": swapRequestId,
                "fromUserId": currentUserId,
                "fromItemId": fromItemId,
                "toUserId": toUserId,
                "toItemId": toItemId,
                "fromUserName": fromUserName,
                "toUserName": toUserName,
                "itemName": itemName,
                "status": "pending",
                "timestamp": timestamp
            ]
            
            // Log the swapRequest data for debugging
            print("Swap request data: \(swapRequest)")
            
            // Start a batch write
            let batch = db.batch()
            
            // Set the swap request document in the 'swapRequests' collection (general collection)
            let swapRequestRef = db.collection("swapRequests").document(swapRequestId)
            batch.setData(swapRequest, forDocument: swapRequestRef)
            
            // Set the swap request in the recipient's 'swapRequests' subcollection
            let receiverSwapRequestsRef = db.collection("users").document(toUserId).collection("swapRequests").document(swapRequestId)
            batch.setData(swapRequest, forDocument: receiverSwapRequestsRef)
            
            // Set the swap request in the sender's 'swapRequests' subcollection
            let senderSwapRequestsRef = db.collection("users").document(currentUserId).collection("swapRequests").document(swapRequestId)
            batch.setData(swapRequest, forDocument: senderSwapRequestsRef)
            
            // Create notification data for the receiver
            let notificationId = UUID().uuidString
            let notificationData: [String: Any] = [
                "id": notificationId,
                "type": "swapRequest",
                "fromUserId": currentUserId,
                "toUserId": toUserId,
                "content": "\(fromUserName) has sent you a swap request for item \(itemName).",
                "timestamp": timestamp,
                "status": "unread"
            ]
            
            // Add the notification to the receiver's notifications collection
            let notificationRef = db.collection("users").document(toUserId).collection("notifications").document(notificationId)
            batch.setData(notificationData, forDocument: notificationRef)
            
            // Commit the batch write
            try await batch.commit()
            
            // Optionally, log or trigger local updates
            print("Swap request and notification successfully sent.")
            
        } catch {
            // Catch any errors and print the message
            print("Failed to send swap request: \(error.localizedDescription)")
            throw error
        }
    }
       // MARK: - Accept Swap Request
    func acceptSwapRequest(swapRequestId: String) async throws {
        let swapRequestRef = db.collection("swapRequests").document(swapRequestId)
        let document = try await swapRequestRef.getDocument()
        
        guard let data = document.data(),
              let fromUserId = data["fromUserId"] as? String,
              let fromItemId = data["fromItemId"] as? String,
              let toUserId = data["toUserId"] as? String,
              let toItemId = data["toItemId"] as? String else {
            throw NSError(domain: "Invalid Data", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing or invalid fields in swap request data"])
        }
        
        // Fetch user names dynamically
        let fromUserName = try await fetchUserName(for: fromUserId)
        let toUserName = try await fetchUserName(for: toUserId)
        
        // Proceed with swapping items
        try await swapItems(fromUserId: fromUserId, fromItemId: fromItemId, toUserId: toUserId, toItemId: toItemId, fromUserName: fromUserName, toUserName: toUserName)
        
        // Update swap request status
        try await swapRequestRef.updateData(["status": "accepted"])
        
        // Update status in user's swapRequests collection
        let userSwapRequestRef = db.collection("users").document(toUserId).collection("swapRequests").document(swapRequestId)
        try await userSwapRequestRef.updateData(["status": "accepted"])
    }

    // Helper function to fetch user names
    private func fetchUserName(for userId: String) async throws -> String {
        let userRef = db.collection("users").document(userId)
        let document = try await userRef.getDocument()
        guard let data = document.data(), let userName = data["name"] as? String else {
            throw NSError(domain: "Invalid Data", code: 500, userInfo: [NSLocalizedDescriptionKey: "User name not found for userId: \(userId)"])
        }
        return userName
    }
    
    func rejectSwapRequest(swapRequestId: String) async throws {
        let swapRequestRef = db.collection("swapRequests").document(swapRequestId)
        let document = try await swapRequestRef.getDocument()
        
        guard let data = document.data(),
              let fromUserId = data["fromUserId"] as? String,
              let fromItemId = data["fromItemId"] as? String,
              let toUserId = data["toUserId"] as? String,
              let toItemId = data["toItemId"] as? String else {
            throw NSError(domain: "Invalid Data", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing or invalid fields in swap request data"])
        }
        
        // Fetch user names dynamically
        let fromUserName = try await fetchUserName(for: fromUserId)
        let toUserName = try await fetchUserName(for: toUserId)
        
        try await rejectItems(fromUserId: fromUserId, fromItemId: fromItemId, toUserId: toUserId, toItemId: toItemId, fromUserName: fromUserName, toUserName: toUserName)
        
        
        // Update swap request status
        try await swapRequestRef.updateData(["status": "rejected"])
        
        // Update status in user's swapRequests collection
        let userSwapRequestRef = db.collection("users").document(toUserId).collection("swapRequests").document(swapRequestId)
        try await userSwapRequestRef.updateData(["status": "rejected"])
    }

    func rejectItems(
        fromUserId: String,
        fromItemId: String,
        toUserId: String,
        toItemId: String,
        fromUserName: String,
        toUserName: String
    ) async throws {
        // Get the current user's ID from FirebaseAuth
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let batch = db.batch()
        
        // References to the items
        _ = db.collection("users").document(fromUserId).collection("items").document(fromItemId)
        _ = db.collection("users").document(toUserId).collection("items").document(toItemId)
        
        // References to swappedItems collections
        let fromSwappedItemRef = db.collection("users").document(currentUserId).collection("rejectedItems").document(toItemId)
        let toSwappedItemRef = db.collection("users").document(toUserId).collection("rejectedItems").document(fromItemId)
        
        // Add data to the swappedItems collections
        batch.setData([
            "itemId": toItemId,
            "rejectedUserId": toUserId,
            "userName": toUserName, // Track the user they swapped with
            "swapTimestamp": FieldValue.serverTimestamp()
        ], forDocument: fromSwappedItemRef)
        
        batch.setData([
            "itemId": fromItemId,
            "rejectedUserId": currentUserId,
            "userName": fromUserName, // Track the user they swapped with
            "swapTimestamp": FieldValue.serverTimestamp()
        ], forDocument: toSwappedItemRef)
        
        // Update the `swappedUserId` field in the original item documents
//        batch.updateData(["rejectedUserId": toUserId], forDocument: fromItemRef)
//        batch.updateData(["rejectedUserId": fromUserId], forDocument: toItemRef)
        
        // Commit the batch operation
        try await batch.commit()
    }
       
       // MARK: - Swap Items
    func swapItems(
        fromUserId: String,
        fromItemId: String,
        toUserId: String,
        toItemId: String,
        fromUserName: String,
        toUserName: String
    ) async throws {
        // Get the current user's ID from FirebaseAuth
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let batch = db.batch()
        
        // References to the items
        let fromItemRef = db.collection("users").document(fromUserId).collection("items").document(fromItemId)
        let toItemRef = db.collection("users").document(toUserId).collection("items").document(toItemId)
        
        // References to swappedItems collections
        let fromSwappedItemRef = db.collection("users").document(currentUserId).collection("swappedItems").document(toItemId)
        let toSwappedItemRef = db.collection("users").document(toUserId).collection("swappedItems").document(fromItemId)
        
        // Add data to the swappedItems collections
        batch.setData([
            "itemId": toItemId,
            "swappedWithUserId": toUserId,
            "userName": toUserName, // Track the user they swapped with
            "swapTimestamp": FieldValue.serverTimestamp()
        ], forDocument: fromSwappedItemRef)
        
        batch.setData([
            "itemId": fromItemId,
            "swappedWithUserId": currentUserId,
            "userName": fromUserName, // Track the user they swapped with
            "swapTimestamp": FieldValue.serverTimestamp()
        ], forDocument: toSwappedItemRef)
        
        // Update the `swappedUserId` field in the original item documents
        batch.updateData(["swappedUserId": toUserId], forDocument: fromItemRef)
        batch.updateData(["swappedUserId": fromUserId], forDocument: toItemRef)
        
        // Commit the batch operation
        try await batch.commit()
    }

    func getItemImageURL(for itemId: String) -> URL? {
        // Example logic: Look up item by ID and return its image URL
        if let item = items.first(where: { $0.id == itemId }),
           let imageUrlString = item.imageUrls.first {
            return URL(string: imageUrlString)
        }
        return nil
    }

    // MARK: - Fetch Swap Requests
       func fetchSwapRequests(fromUserId userId: String) async throws -> [SwapRequest] {
           let querySnapshot = try await db.collection("users")
               .document(userId)
               .collection("swapRequests")
               .getDocuments()
           
           return querySnapshot.documents.compactMap { document in
               guard let fromUserId = document.data()["fromUserId"] as? String,
                     let fromItemId = document.data()["fromItemId"] as? String,
                     let toUserId = document.data()["toUserId"] as? String,
                     let toItemId = document.data()["toItemId"] as? String,
                     let statusString = document.data()["status"] as? String, // Raw string for status
                     let status = SwapRequestStatus(rawValue: statusString),
                     let timestamp = document.data()["timestamp"] as? Timestamp else {
                   return nil
               }
               
               return SwapRequest(
                   id: document.documentID,
                   fromUserId: fromUserId,
                   fromItemId: fromItemId,
                   toUserId: toUserId,
                   toItemId: toItemId,
                   status: status,
                   timestamp: timestamp.dateValue()
               )
           }
       }

    func fetchAllItems() async throws -> [Item] {
        let snapshot = try await db.collectionGroup("items").getDocuments()
        let items = snapshot.documents.compactMap { document in
            var item = try? document.data(as: Item.self)
            item?.id = document.documentID
            return item
        }
        
        self.items = items
        return items
    }

    func fetchItemsByDistance() async throws -> [Item] {
        do {
            // Fetch user's current location as CLLocationCoordinate2D
            guard let userCoordinates = try await LocationManager.shared.getCurrentLocation().0 else {
                throw NSError(domain: "LocationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User location is not available"])
            }

            // Convert CLLocationCoordinate2D to CLLocation
            let userLocation = CLLocation(latitude: userCoordinates.latitude, longitude: userCoordinates.longitude)

            // Fetch all items
            let items = try await fetchAllItems()

            // Sort items by distance to user's location
            let sortedItems = items.sorted {
                $0.distance(to: userLocation) < $1.distance(to: userLocation)
            }

            // Update internal state
            self.items = sortedItems
            return sortedItems
        } catch {
            print("Failed to fetch user location or items: \(error.localizedDescription)")

            // Fallback to unsorted items
            let items = try await fetchAllItems()
            return items
        }
    }


    // In LocationManager or ItemManager, depending on where fetchItemsByDistance is implemented
    func fetchItemsByKm(within radius: Double) async throws -> [Item] {
        // Fetch the current user location
        let (userCoordinates, _, _, _, _) = try await LocationManager.shared.getCurrentLocation()
        
        guard let userCoordinates = userCoordinates else {
            throw NSError(domain: "User location is not available.", code: 0, userInfo: nil)
        }
        
        // Convert userCoordinates to CLLocation
        let userLocation = CLLocation(latitude: userCoordinates.latitude, longitude: userCoordinates.longitude)
        
        // Fetch all items
        let items = try await fetchAllItems()
        
        // If radius is 50 km or more, return all items without filtering
        if radius >= 50.0 {
            return items
        }

        // Filter items within the specified radius
        let filteredItems = items.filter { item in
            let itemLocation = CLLocation(latitude: item.latitude, longitude: item.longitude)
            let distanceInKm = itemLocation.distance(from: userLocation) / 1000 // Convert meters to kilometers
            return distanceInKm <= radius
        }
        
        return filteredItems
    }

    // Start tracking the view duration for an item
        func startViewTimer(for item: Item) {
            let itemId = item.uid
            stopViewTimer(for: item) // Ensure no duplicate timers

            viewDurations[itemId] = 0
            viewTimers[itemId] = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                self.viewDurations[itemId, default: 0] += 1

                if self.viewDurations[itemId]! >= 10 {
                    timer.invalidate()
                    self.viewTimers[itemId] = nil
                    self.incrementClickCount(for: item)
                }
            }
        }

        // Stop the view timer for an item
        func stopViewTimer(for item: Item) {
            let itemId = item.uid
            viewTimers[itemId]?.invalidate()
            viewTimers[itemId] = nil
            viewDurations[itemId] = nil
        }

        // Increment the click count for an item
        func incrementClickCount(for item: Item) {
            guard let index = items.firstIndex(where: { $0.uid == item.uid }) else { return }
            items[index].clickCount += 1

            // Update Firestore (example logic)
            let itemToUpdate = items[index]
            let itemRef = Firestore.firestore().collection("items").document(itemToUpdate.uid)
            itemRef.updateData(["clickCount": itemToUpdate.clickCount]) { error in
                if let error = error {
                    print("Failed to update click count in Firestore: \(error.localizedDescription)")
                }
            }
        }
    // Increment the add-to-cart count for an item
    func incrementAddToCartCount(for item: Item) {
        guard let index = items.firstIndex(where: { $0.uid == item.uid }) else { return }
        items[index].addToCartCount += 1

        // Update Firestore (example logic)
        let itemToUpdate = items[index]
        let itemRef = Firestore.firestore().collection("items").document(itemToUpdate.uid)
        itemRef.updateData(["addToCartCount": itemToUpdate.addToCartCount]) { error in
            if let error = error {
                print("Failed to update add-to-cart count in Firestore: \(error.localizedDescription)")
            }
        }
    }
    // Simulate adding an item to the cart
    func addToCart(item: Item) {
        // Perform necessary UI updates or logic for adding the item to the cart
        incrementAddToCartCount(for: item)
        print("Item added to cart: \(item.name)")
    }


    func fetchItemsByCategory(category: String) async throws -> [Item] {
        let snapshot = try await db.collection("items").whereField("category", isEqualTo: category).getDocuments()
        let items = snapshot.documents.compactMap { document in
            try? document.data(as: Item.self)
        }
        return items
    }

    func fetchItemsBySubcategory(category: String, subcategory: String) async throws -> [Item] {
        let snapshot = try await db.collection("items")
            .whereField("category", isEqualTo: category)
            .whereField("subcategory", isEqualTo: subcategory)
            .getDocuments()
        
        let items = snapshot.documents.compactMap { document in
            try? document.data(as: Item.self)
        }
        return items
    }
    
    func fetchItemsByCategoryAndSubCategory(category: String, subcategory: String?) async throws -> [Item] {
        var query = db.collection("items").whereField("category", isEqualTo: category)
        
        // If a subcategory is provided, add it to the query
        if let subcategory = subcategory {
            query = query.whereField("subcategory", isEqualTo: subcategory)
        }
        
        let snapshot = try await query.getDocuments()
        
        let items = snapshot.documents.compactMap { document in
            try? document.data(as: Item.self)
        }
        
        return items
    }
    
    func fetchItemsByCategoryAndSubcategoryAndDistance(category: String?, subcategory: String?, radius: Double?) async throws -> [Item] {
        // Fetch user's current location
        let (userCoordinates, _, _, _, _) = try await LocationManager.shared.getCurrentLocation()

        // Ensure user location is available
        guard let userCoordinates = userCoordinates else {
            throw NSError(domain: "LocationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User location is not available"])
        }
        let userLocation = CLLocation(latitude: userCoordinates.latitude, longitude: userCoordinates.longitude)

        // Fetch all items
        var items = try await fetchAllItems()

        // Apply filters
        if let category = category, !category.isEmpty {
            items = items.filter { $0.selectedCategory == category }
        }

        if let subcategory = subcategory, !subcategory.isEmpty {
            items = items.filter { $0.selectedSubCategory == subcategory }
        }

        if let radius = radius {
            items = items.filter { $0.distance(to: userLocation) <= radius }
        }

        // Sort items by proximity to user's location
        return items.sorted { $0.distance(to: userLocation) < $1.distance(to: userLocation) }
    }
    
    func getOwnerId(for itemId: String) async throws -> String {
        print("Attempting to fetch owner ID for itemId: \(itemId)")
        
        // Query users collection to find the owner of the item
        let usersQuery = db.collection("users")
        let querySnapshot = try await usersQuery.getDocuments()
        
        for document in querySnapshot.documents {
            let userId = document.documentID
            
            // Access the items subcollection for this user
            let itemsRef = db.collection("users").document(userId).collection("items").document(itemId)
            let itemDoc = try? await itemsRef.getDocument()
            
            if let itemData = itemDoc?.data(), let itemOwnerId = itemData["uid"] as? String {
                print("Item \(itemId) is owned by user: \(itemOwnerId)")
                return itemOwnerId
            }
        }
        
        throw NSError(domain: "Item Not Found", code: 404, userInfo: ["message": "No document found for itemId: \(itemId) in any user's items"])
    }
    
    func getUsername(for itemId: String) async throws -> String {
        print("Attempting to fetch username for itemId: \(itemId)")

        do {
            // Step 1: Search for the user who owns the item
            let userSnapshot = try await db.collection("users")
                .getDocuments()
            
            // Iterate over users to find the item
            for userDoc in userSnapshot.documents {
                let userId = userDoc.documentID
                print("Checking user: \(userId)")

                // Step 2: Check if the item exists under this user's items subcollection
                let itemDoc = try await db.collection("users")
                    .document(userId)
                    .collection("items")
                    .document(itemId)
                    .getDocument()

                if itemDoc.exists {
                    // Extract the username from the item's document
                    guard let username = itemDoc.data()?["userName"] as? String else {
                        print("Missing 'userName' field for item \(itemId) under user \(userId)")
                        throw NSError(domain: "Invalid Data", code: 500, userInfo: ["message": "Missing 'userName' for item \(itemId)"])
                    }

                    print("Item \(itemId) found under user \(userId). Username: \(username)")
                    return username
                }
            }

            // If no item is found in any user's items collection
            print("Item \(itemId) not found under any user.")
            throw NSError(domain: "Item Not Found", code: 404, userInfo: ["message": "Item not found for itemId: \(itemId)"])
        } catch {
            print("Error fetching document for itemId \(itemId): \(error.localizedDescription)")
            throw error
        }
    }
}
enum SwapRequestStatus: String, Codable {
    case pending
    case accepted
    case rejected
}
struct SwapRequest: Identifiable, Codable {
    var id: String
    var fromUserId: String
    var fromItemId: String
    var toUserId: String
    var toItemId: String
    var status: SwapRequestStatus
    var timestamp: Date
}
private func statusColor(for status: SwapRequestStatus) -> Color {
    switch status {
    case .pending: return .orange
    case .accepted: return .green
    case .rejected: return .red
    }
}



    struct Item: Identifiable, Codable {
        @DocumentID var id: String?
            var uid: String
            var name: String
            var details: String
            var originalprice: Double
            var value: Double
            var imageUrls: [String] // Handle Multiple Images
            var condition: String
            var timestamp: Date
            var selectedCategory: String // Changed
            var selectedSubCategory: String?
            var userName: String
            var latitude: Double
            var longitude: Double
            var clickCount: Int // New property to track clicks
            var distanceToUser: Double? // Optional, as it may not always be available
            var addToCartCount: Int = 0



            var location: CLLocation? {
            
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        
        func distance(to location: CLLocation) -> CLLocationDistance {
             let itemLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
             return itemLocation.distance(from: location)
         }
        func topThreeItems(from items: [Item]) -> [Item] {
            return items.sorted { $0.clickCount > $1.clickCount }.prefix(3).map { $0 }
        }
        func isOwnedByCurrentUser(currentUserId: String) -> Bool {
            return self.uid == currentUserId
        }

        init(name: String, details: String, originalprice: Double, value: Double, imageUrls: [String], condition: String, timestamp: Date, uid: String, selectedCategory: String, selectedSubCategory: String?, userName: String, latitude: Double, longitude: Double, clickCount: Int) {
                self.uid = uid
                self.name = name
                self.details = details
                self.originalprice = originalprice
                self.value = value
                self.imageUrls = imageUrls
                self.condition = condition
                self.timestamp = timestamp
                self.selectedCategory = selectedCategory // Changed
                self.selectedSubCategory = selectedSubCategory // Changed
                self.userName = userName
                self.latitude = latitude
                self.longitude = longitude
                self.clickCount = clickCount
           }

           init(from decoder: Decoder) throws {
               let container = try decoder.container(keyedBy: CodingKeys.self)
               id = try? container.decode(String.self, forKey: .id)
               uid = try container.decodeIfPresent(String.self, forKey: .uid) ?? ""
               name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
               details = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
               originalprice = try container.decodeIfPresent(Double.self, forKey: .originalprice) ?? 0.0
               value = try container.decodeIfPresent(Double.self, forKey: .value) ?? 0.0
               imageUrls = try container.decodeIfPresent([String].self, forKey: .imageUrls) ?? []
               condition = try container.decodeIfPresent(String.self, forKey: .condition) ?? ""
               timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
               selectedCategory = try container.decodeIfPresent(String.self, forKey: .selectedCategory) ?? "" // Changed
               selectedSubCategory = try container.decodeIfPresent(String.self, forKey: .selectedSubCategory)
               userName = try container.decodeIfPresent(String.self, forKey: .userName) ?? ""
               latitude = try container.decodeIfPresent(Double.self, forKey: .latitude) ?? 0.0
               longitude = try container.decodeIfPresent(Double.self, forKey: .longitude) ?? 0.0
               clickCount = try container.decodeIfPresent(Int.self, forKey: .clickCount) ?? 0

           }
        func toDictionary() -> [String: Any] {
                return [
                    "uid": uid,
                    "name": name,
                    "details": details,
                    "originalprice": originalprice,
                    "value": value,
                    "imageUrls": imageUrls,
                    "condition": condition,
                    "timestamp": timestamp,
                    "selectedCategory": selectedCategory as Any,
                    "selectedSubCategory": selectedSubCategory as Any,
                    "userName": userName,
                    "latitude": latitude,
                    "longitude": longitude
                    
                ]
            }

        }
extension Item {
    func isPopular(in topItems: [Item]) -> Bool {
        return topItems.contains(where: { $0.id == self.id })
    }
}
