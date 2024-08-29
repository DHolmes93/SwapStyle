//
//  ItemModel.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import Foundation

import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage
import FirebaseAuth
import CoreLocation


// Manages items and related operations, such as uploading, deleting, fetching, swapping items and sorting them by location.
class ItemManager: ObservableObject {
    static let shared = ItemManager()
    @Published var items: [Item] = [] // List of all items for the current user
    @Published var itemsByDistance: [String: [Item]] = [
        "5km": [],
        "15km": [],
        "25km": [],
        "50km+": []
    ]
    private let authManager = AuthManager.shared
    
    // Private initializer to enforce singleton pattern
    private init() {}
    
    // Upload each image to Firebase Storage and Collect their URL's
    func uploadItem(userAccountModel: UserAccountModel, images: [UIImage], name: String, details: String, originalprice: Double, value: Double, condition: String, timestamp: Date, category: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Check if user is logged in
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "No user logged in", code: 401, userInfo: nil)))
            return
        }
        // Reference to Firebase Storage location for item images
        let itemImagesRef = Storage.storage().reference().child("item_images")
        // Emopty Array to store URLs of uploaded images
        var imageUrls: [String] = []
        
        
        let dispatchGroup = DispatchGroup()
        
        // Loop through each image and store in firebase while also collecting their URLs
        for image in images {
            dispatchGroup.enter()
            let imageName = UUID().uuidString
            let imageRef = itemImagesRef.child("\(imageName).jpg")
            guard let imageData = image.jpegData(compressionQuality: 0.8)
            else {
                completion(.failure(NSError(domain: "Image Conversion Error", code: 500, userInfo: nil)))
                return
            }
            imageRef.putData(imageData, metadata: nil) { (metdadata, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                imageRef.downloadURL { (url, error) in
                    defer { dispatchGroup.leave() }
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    guard let imageUrl = url?.absoluteString else {
                        completion(.failure(NSError(domain: "URL error", code: 500, userInfo: nil)))
                        return
                    }
                    // Add ImageURL to array
                    imageUrls.append(imageUrl)
                }
            }
        }
        // Once all images are uploaded, save the item data in Firestore
        dispatchGroup.notify(queue: .main) {
            LocationManager.shared.getCurrentLocation {
                result in
                switch result {
                case .success(_):
                    let itemData: [String: Any] = [
                        "uid": uid,
                        "name": name,
                        "details": details,
                        "originalprice": originalprice,
                        "value": value,
                        "condition": condition,
                        "timestamp": Timestamp(date: timestamp),
                        "category": category,
                        "imageUrls": imageUrls,
                        "userName": userAccountModel.name
                    ]
                    let db = Firestore.firestore()
                    db.collection("users").document(uid).collection("items").addDocument(data: itemData) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    // Deletes an item from Firestore an updates Items List of user
    func deleteItem(itemId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "No user logged in", code: 401, userInfo: nil)))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("items").document(itemId).delete { error in
            
            //Handle Firestore error
            if let error = error {
                completion(.failure(error))
            } else {
                self.fetchItems { _ in }
                completion(.success(()))
            }
        }
    }
    
    // Fetches all items for the current user from Firestore
    func fetchItems(completion: @escaping (Result<[Item], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "No user logged in", code: 401, userInfo: nil)))
            return
        }
        let db = Firestore.firestore()
        // Reference to the users items collection
        let userItemsRef = db.collection("users").document(uid).collection("items")
        userItemsRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            let items = documents.compactMap { document -> Item? in
                var item = try? document.data(as: Item.self)
                item?.id = document.documentID
                
                return item
            }
            DispatchQueue.main.async {
                self.items = items
                completion(.success(items))
            }
        }
    }
    
    // Sends a swap request between items of the current user and another user
    func requestSwap(fromItemId: String, toUserId: String, toItemId: String, completion: @escaping(Result<Void, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "No user logged in", code: 401, userInfo: nil)))
            return
        }
        let db = Firestore.firestore()
        let swapRequest = [
            "fromUserId": currentUserId,
            "fromItemId": toItemId,
            "toUserId": toUserId,
            "toItemId": toItemId,
            "status": "pending"]
        as [String : Any]
        
        db.collection("swapRequests").addDocument(data: swapRequest) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // Accepts a swap request and updates the staus to be accepted
    func acceptSwapRequest(swapRequestId: String, completion: @escaping(Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let swapRequestRef = db.collection("users").document(swapRequestId)
        swapRequestRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = document?.data(),
                  let fromUserId = data["fromUserId"] as? String,
                  let fromItemId = data["fromItemId"] as? String,
                  let toUserId = data["toUserId"] as? String,
                  let toItemId = data["toItemId"] as? String else {
                completion(.failure(NSError(domain: "Invalid Data", code: 500, userInfo: nil)))
                return
            }
            self.swapItems(fromUserId: fromUserId, fromItemId: fromItemId, toUserId: toUserId, toItemId: toItemId) { result in
                switch result {
                case .success:
                    swapRequestRef.updateData(["status": "accepted"]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    func swapItems(fromUserId: String, fromItemId: String, toUserId: String, toItemId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let batch = db.batch()
        
        let fromItemRef = db.collection("users").document(fromUserId).collection("items").document(fromItemId)
        let toItemRef = db.collection("users").document(toUserId).collection("items").document(toItemId)
        
        batch.updateData(["uid": toUserId], forDocument: fromItemRef)
        batch.updateData(["uid": fromUserId], forDocument: toItemRef)
        batch.commit() { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    private func fetchDisplayName(for uid: String, completion: @escaping (String?) -> Void) {
        Firestore.firestore().collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                let displayName = document.data()?["displayName"] as? String
                completion(displayName)
            } else {
                completion(nil)
            }
        }
    }
    func updateItem(_ item: Item, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "No user logged in", code: 401, userInfo: nil)))
            return
            
        }
        let db = Firestore.firestore()
        let userItemsRef = db.collection("users").document(uid).collection("items")
        userItemsRef.document(item.id!).setData(item.toDictionary()) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.fetchItems { _ in }
                completion(.success(()))
            }
        }
    }
    func fetchAllItems(completion: @escaping (Result<[Item], Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let userDocuments = snapshot?.documents else {
                completion(.success([]))
                return
            }
            let dispatchGroup = DispatchGroup()
            var allItems: [Item] = []
            
            for userDocument in userDocuments {
                let userItemsRef = db.collection("users").document(userDocument.documentID).collection("items")
                dispatchGroup.enter()
                userItemsRef.getDocuments { itemsSnapshot, error in
                    if let itemsSnapshot = itemsSnapshot {
                        let items = itemsSnapshot.documents.compactMap { document -> Item? in
                            var item = try? document.data(as: Item.self)
                            item?.id = document.documentID
                            return item
                        }
                        allItems.append(contentsOf: items)
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                DispatchQueue.main.async {
                    self.items = allItems
                    completion(.success(allItems))
                }
            }
        }
    }
    func fetchAndSortItemsByLocation(completion: @escaping (Result<[Item], Error>) -> Void) {
        LocationManager.shared.getCurrentLocation { result in
            switch result {
            case .success(let userLocation):
                self.fetchAllItems { result in
                    switch result {
                    case .success(let items):
                        let sortedItems = items.sorted {
                            guard let lat1 = $0.latitude, let lon1 = $0.longitude, let lat2 = $1.latitude, let lon2 = $1.longitude else {
                                return false
                            }
                            let loc1 = CLLocation(latitude: lat1, longitude: lon1)
                            let loc2 = CLLocation(latitude: lat2, longitude: lon2)
                            return loc1.distance(from: userLocation) < loc2.distance(from: userLocation)
                        }
                        completion(.success(sortedItems))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    func fetchItemsByDistance(_ location: CLLocation, completion: @escaping (Result<[String: [Item]], Error>) -> Void) {
        fetchAllItems { result in
            switch result {
            case .success(let allItems):
                var itemsByDistance: [String: [Item]] = [
                    "5km": [],
                    "15km": [],
                    "25km": [],
                    "50km": []
                ]
                for item in allItems {
                    guard let itemLocation = item.location else { continue }
                    let distance = itemLocation.distance(from: location) / 1000 //Distance in Kilometers
                    
                    if distance <= 5 {
                        itemsByDistance["5km"]?.append(item)
                    } else if distance <= 15 {
                        itemsByDistance["15km"]?.append(item)
                    } else if distance <= 25 {
                        itemsByDistance["25km"]?.append(item)
                    } else {
                        itemsByDistance["50km+"]?.append(item)
                    }
                }
                DispatchQueue.main.async {
                    self.itemsByDistance = itemsByDistance
                    completion(.success(itemsByDistance))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    func getUsername(for itemId: String) -> String? {
            return items.first(where: { $0.id == itemId })?.userName
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
            var category: String
            var userName: String?
            var latitude: Double?
            var longitude: Double?
        
            var location: CLLocation? {
            guard let latitude = latitude, let longitude = longitude else { return nil }
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        
            
        
        init(name: String, details: String, originalprice: Double, value: Double, imageUrls: [String], condition: String, timestamp: Date, uid: String, category: String, userName: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
                self.uid = uid
                self.name = name
                self.details = details
                self.originalprice = originalprice
                self.value = value
                self.imageUrls = imageUrls
                self.condition = condition
                self.timestamp = timestamp
                self.category = category
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
               category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
               userName = try container.decodeIfPresent(String.self, forKey: .userName) ?? ""
               latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
               longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
              
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
                    "category": category,
                    "userName": userName as Any,
                    "latitude": latitude as Any,
                    "longitude": longitude as Any
                ]
            }
            
        }
        
