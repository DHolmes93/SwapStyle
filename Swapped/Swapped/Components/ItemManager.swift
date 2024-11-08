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
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude
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

        let userItemsRef = db.collection("users").document(uid).collection("items")
        let snapshot = try await userItemsRef.getDocuments()
        let items = snapshot.documents.compactMap { document in
            var item = try? document.data(as: Item.self)
            item?.id = document.documentID
            return item
        }

        self.items = items
        return items
    }

    func requestSwap(fromItemId: String, toUserId: String, toItemId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "No user logged in", code: 401, userInfo: nil)
        }

        let swapRequest: [String: Any] = [
            "fromUserId": currentUserId,
            "fromItemId": fromItemId,
            "toUserId": toUserId,
            "toItemId": toItemId,
            "status": "pending"
        ]

        try await db.collection("swapRequests").addDocument(data: swapRequest)
    }

    func acceptSwapRequest(swapRequestId: String) async throws {
        let swapRequestRef = db.collection("swapRequests").document(swapRequestId)
        let document = try await swapRequestRef.getDocument()

        guard let data = document.data(),
              let fromUserId = data["fromUserId"] as? String,
              let fromItemId = data["fromItemId"] as? String,
              let toUserId = data["toUserId"] as? String,
              let toItemId = data["toItemId"] as? String else {
            throw NSError(domain: "Invalid Data", code: 500, userInfo: nil)
        }

        try await swapItems(fromUserId: fromUserId, fromItemId: fromItemId, toUserId: toUserId, toItemId: toItemId)
        try await swapRequestRef.updateData(["status": "accepted"])
    }

    func swapItems(fromUserId: String, fromItemId: String, toUserId: String, toItemId: String) async throws {
        let batch = db.batch()

        let fromItemRef = db.collection("users").document(fromUserId).collection("items").document(fromItemId)
        let toItemRef = db.collection("users").document(toUserId).collection("items").document(toItemId)

        batch.updateData(["uid": toUserId], forDocument: fromItemRef)
        batch.updateData(["uid": fromUserId], forDocument: toItemRef)

        try await batch.commit()
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
        let userLocation = try await LocationManager.shared.getCurrentLocation().0  // Use only CLLocation

        let items = try await fetchAllItems()

        // Sort items by distance to the user's location
        let sortedItems = items.sorted {
            $0.distance(to: userLocation) < $1.distance(to: userLocation)
        }

        // Optionally update internal items state if needed
        self.items = sortedItems
        return sortedItems
    }
    // In LocationManager or ItemManager, depending on where fetchItemsByDistance is implemented

    func fetchItemsByKm(within radius: Double) async throws -> [Item] {
        let (userLocation, _, _, _, _) = try await LocationManager.shared.getCurrentLocation()
        let items = try await fetchAllItems()
        
        // If radius is 50 km, fetch all items without filtering by distance
        if radius >= 50.0 {
            return items
        }

        // Filter items within the specified radius without reverse geocoding
        let filteredItems = items.filter { item in
            let itemLocation = CLLocation(latitude: item.latitude, longitude: item.longitude)
            let distanceInKm = itemLocation.distance(from: userLocation) / 1000
            return distanceInKm <= radius
        }
        
        return filteredItems
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

    func fetchItemsByCategoryAndSubcategoryAndDistance(category: String?, subcategory: String?, radius: Double?) async throws -> [Item] {
        let (userLocation, city, state, zipcode, country) = try await LocationManager.shared.getCurrentLocation()
        var items = try await fetchAllItems()

        if let category = category {
            items = items.filter { $0.selectedCategory == category }
        }
        if let subcategory = subcategory {
            items = items.filter { $0.selectedSubCategory == subcategory }
        }
        if let radius = radius {
            items = items.filter { $0.distance(to: userLocation) <= radius }
        }

        let sortedItems = items.sorted { $0.distance(to: userLocation) < $1.distance(to: userLocation) }
        return sortedItems
    }
    
    func getUsername(for itemId: String) async throws -> String {
        let document = try await db.collection("items").document(itemId).getDocument()
        guard let data = document.data(), let userId = data["uid"] as? String else {
            throw NSError(domain: "Invalid Data", code: 500, userInfo: nil)
        }

        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data(), let username = userData["username"] as? String else {
            throw NSError(domain: "Invalid Data", code: 500, userInfo: nil)
        }
        
        return username
    }
}

struct SwapRequest: Codable {
    var fromUserId: String
    var fromItemId: String
    var toUserId: String
    var toItemId: String
    var status: String
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


            var location: CLLocation? {
            
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        func distance(to location: CLLocation) -> CLLocationDistance {
            return self.location!.distance(from: location)
        }
        


        init(name: String, details: String, originalprice: Double, value: Double, imageUrls: [String], condition: String, timestamp: Date, uid: String, selectedCategory: String, selectedSubCategory: String?, userName: String, latitude: Double, longitude: Double) {
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

//extension Item {
//    func distance(to location: CLLocation) -> Double {
//        guard let itemLocation = self.location else { return Double.greatestFiniteMagnitude }
//        return itemLocation.distance(from: location)
//    }
//}

// Fetch items by category and distance
//    func fetchItemsByCategoryAndDistance(category: String?, radius: Double, userLocation: CLLocation, completion: @escaping (Result<[Item], Error>) -> Void) {
//        LocationManager.shared.getCurrentLocation { result in
//            switch result {
//            case .success(let (location, _, _, _)):
//                self.fetchAllItems { fetchResult in
//                    switch fetchResult {
//                    case .success(let items):
//                        // If category is nil (i.e., "All" is selected), don't filter by category
//                        let filteredItems = category == nil ? items : items.filter { $0.category == category }
//
//                        // Sort by distance to the user's current location
//                        let sortedItems = filteredItems.sorted { $0.distance(to: location) < $1.distance(to: location) }
//
//                        // Return the sorted items
//                        completion(.success(sortedItems))
//                    case .failure(let error):
//                        completion(.failure(error))
//                    }
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
