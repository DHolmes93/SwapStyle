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



class ItemManager: ObservableObject {
    static let shared = ItemManager()
    @Published var items: [Item] = []
    
    
    private init() {}
    
    
    
    
    func uploadItem(image: UIImage, name: String, details: String, price: Double, condition: String, description: String, timestamp: Date, category: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "No user logged in", code: 401, userInfo: nil)))
            return
        }
        let imageName = UUID().uuidString
        let storageRef = Storage.storage().reference().child("item_images").child(imageName)
        guard let imageData = image.jpegData(compressionQuality: 0.8)
        else {
            completion(.failure(NSError(domain: "Image Conversion Error", code: 500, userInfo: nil)))
            return
        }
        storageRef.putData(imageData, metadata: nil) { (metdadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let imageUrl = url else {
                    completion(.failure(NSError(domain: "URL error", code: 500, userInfo: nil)))
                    return
                }
                let itemData: [String: Any] = [
                    "uid": uid,
                    "name": name,
                    "details": details,
                    "price": price,
                    "condition": condition,
                    "description": description,
                    "timestamp": Timestamp(date: timestamp),
                    "category": category,
                    "imageUrl": imageUrl.absoluteString
                ]
                Firestore.firestore().collection("items").addDocument(data: itemData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    
    

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
        Firestore.firestore().collection("items").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            let items = documents.compactMap { document -> Item? in
                try? document.data(as: Item.self)
            }
            DispatchQueue.main.async {
                self.items = items
                completion(.success(items))
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
            var imageUrl: String
            var condition: String
            var description: String
            var timestamp: Date
            var category: String
            
        
        init(name: String, details: String, price: Double, imageUrl: String, condition: String, description: String, timestamp: Date, uid: String, category: String) {
            self.uid = uid
               self.name = name
               self.details = details
               self.price = price
               self.imageUrl = imageUrl
               self.condition = condition
               self.description = description
               self.timestamp = timestamp
                self.category = category
            
             
           }
           
           init(from decoder: Decoder) throws {
               let container = try decoder.container(keyedBy: CodingKeys.self)
               id = try? container.decode(String.self, forKey: .id)
               uid = try container.decodeIfPresent(String.self, forKey: .uid) ?? ""
               name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
               details = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
               price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0
               imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl) ?? ""
               condition = try container.decodeIfPresent(String.self, forKey: .condition) ?? ""
               description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
               timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
               category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
              
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
