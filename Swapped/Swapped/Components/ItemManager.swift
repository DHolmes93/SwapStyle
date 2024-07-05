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



class ItemManager: ObservableObject {
    static let shared = ItemManager()
    @Published var items: [Item] = []
    private let authManager = AuthManager.shared
    
    
    private init() {}
    
    
    
    
    func uploadItem(images: [UIImage], name: String, details: String, price: Double, condition: String, description: String, timestamp: Date, category: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "No user logged in", code: 401, userInfo: nil)))
            return
        }
        
        let itemImagesRef = Storage.storage().reference().child("item_images")
        var imageUrls: [String] = []
        
        
        let dispatchGroup = DispatchGroup()
        
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
                    imageUrls.append(imageUrl)
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            let itemData: [String: Any] = [
                "uid": uid,
                "name": name,
                "details": details,
                "price": price,
                "condition": condition,
                "description": description,
                "timestamp": Timestamp(date: timestamp),
                "category": category,
                "imageUrls": imageUrls
            ]
            let db = Firestore.firestore()
            db.collection("users").document(uid).collection("items").addDocument(data: itemData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

//                    uploadCount += 1
//                    
//                    if uploadCount == images.count {
//                        
                        
                 
        
    
    
    

    func deleteItem(itemId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard (Auth.auth().currentUser?.uid) != nil else {
            completion(.failure(NSError(domain: "No user logged in", code: 401, userInfo: nil)))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("items").document(itemId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.fetchItems { _ in }
                completion(.success(()))
            }
        }
    }
    
    
    func fetchItems(completion: @escaping (Result<[Item], Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "No user logged in", code: 401, userInfo: nil)))
            return
        }
            let db = Firestore.firestore()
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
}
    
            
            
    struct Item: Identifiable, Codable {
        @DocumentID var id: String?
        var uid: String
            var name: String
            var details: String
            var price: Double
            var imageUrls: [String] // Handle Multiple Images
            var condition: String
            var description: String
            var timestamp: Date
            var category: String
        var userName: String?
            
        
        init(name: String, details: String, price: Double, imageUrls: [String], condition: String, description: String, timestamp: Date, uid: String, category: String, userName: String? = nil) {
            self.uid = uid
               self.name = name
               self.details = details
               self.price = price
               self.imageUrls = imageUrls
               self.condition = condition
               self.description = description
               self.timestamp = timestamp
                self.category = category
            self.userName
            
             
           }
           
           init(from decoder: Decoder) throws {
               let container = try decoder.container(keyedBy: CodingKeys.self)
               id = try? container.decode(String.self, forKey: .id)
               uid = try container.decodeIfPresent(String.self, forKey: .uid) ?? ""
               name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
               details = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
               price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0
               imageUrls = try container.decodeIfPresent([String].self, forKey: .imageUrls) ?? []
               condition = try container.decodeIfPresent(String.self, forKey: .condition) ?? ""
               description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
               timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
               category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
               userName = try container.decodeIfPresent(String.self, forKey: .userName) ?? ""
              
           }
            
        }
        
            
            
            
            //            func fetchItems(completion: @escaping(Result<[Item], Error>) -> Void) {
            //                let db = Firestore.firestore()
            //                db.collection("items").getDocuments {
            //                    (snapshot, error) in
            //                    if let error = error {
            //                        completion(.failure(error))
            //                    } else if let snapshot = snapshot
            //                    {
            //                        _ = snapshot.documents.compactMap { document -> Item? in
            //                            let data = document.data()
            //                            guard let userId = data["userId"] as? String,
            //                                  let name = data["name"] as? String,
            //                                  let details = data["details"] as? String,
            //                                  let price = data["price"] as? Double,
            //                                  let condition = data["condition"] as? String,
            //                                  let description = data["description"] as? String,
            //                                  let photoURL = data["photoURL"] as? String,
            //                                  let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
            //                                return nil
            //                            }
            //                            return Item(id: document.documentID, userId: userId, name: name, details: details, price: price, photoURL: photoURL, condition: condition, description: description, timestamp: timestamp)
            //                        }
            //                    }
            //                }
            //            }
            
//            func saveItems()
//            let db = Firestore.firestore()
//            let userId = Auth.auth().currentUser?.uid ??
//            "unknown_user"
//            let item = Item(userId: userId, name: name, details: details, price: price, photoURL: photoURL,  condition: condition, description: description, timestamp: Date(), uid: uid)
//            do {
//                let _ = try
//                db.collection("users").document(userId).collection("items").addDocument(from: item)
//                completion(.success(()))
//            } catch {
//                completion(.failure(error))
//            }
//        }


//    func saveItem(name: String, details: String, price: Double, photoURL: String, condition: String, description: String, timestamp: Date, completion:
//                  @escaping (Result<Void, Error>) -> Void) {
//        guard let uid = Auth.auth().currentUser?.uid else {
//            completion(.failure(NSError(domain: "No user logged in", code: 401, userInfo: nil)))
//            return
//        }
//        let db = Firestore.firestore()
//        let item = Item(name: name, details: details, price: price, photoURL: imageUrl.absoluteString, condition: condition, description: description, timestamp: timestamp, uid: uid, category: category)
//        do {
//            let _ = try db.collection("items").addDocument(from: item)
//            fetchItems { _ in }
//            completion(.success(()))
//        } catch {
//            completion(.failure(error))
//        }
//    }
//
