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
    
    
    
    
    func uploadItem(image: UIImage, name: String, details: String, price: Double, condition: String, description: String, timestamp: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8)
        else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image Conversion Failed"])))
            return
        }
        let storageRef = Storage.storage().reference().child("items/\(UUID().uuidString).jpg")
        let uploadTask = storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                }
                guard let downloadURL = url
                else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get URL"])))
                    return
                }
                self.saveItem(name: name, details: details, price: price, photoURL: downloadURL.absoluteString, condition: condition, description: description, timestamp: timestamp, completion: completion)
            }
        }
        uploadTask.resume()
        
    }
    private func saveItem(name: String, details: String, price: Double, photoURL: String, condition: String, description: String, timestamp: Date, completion:
                          @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let userId = Auth.auth().currentUser?.uid ??
        "unknown_user"
        let item = Item(userId: userId, name: name, details: details, price: price, photoURL: photoURL,  condition: condition, description: description, timestamp: Date())
        do {
            let _ = try
            db.collection("users").document(userId).collection("items").addDocument(from: item)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    func deleteItem(itemId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let userId = Auth.auth().currentUser?.uid ??
        "unknown_user"
        
        db.collection("users").document(userId).collection("items").document(itemId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
        
    }
    func fetchItems(completion: @escaping(Result<[Item], Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("items").getDocuments {
            (snapshot, error) in
            if let error = error {
                completion(.failure(error))
            } else if let snapshot = snapshot
            {
                _ = snapshot.documents.compactMap { document -> Item? in
                    let data = document.data()
                    guard let userId = data["userId"] as? String,
                          let name = data["name"] as? String,
                          let details = data["details"] as? String,
                          let price = data["price"] as? Double,
                          let condition = data["condition"] as? String,
                          let description = data["description"] as? String,
                          let photoURL = data["photoURL"] as? String,
                          let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                        return nil
                    }
                    return Item(id: document.documentID, userId: userId, name: name, details: details, price: price, photoURL: photoURL, condition: condition, description: description, timestamp: timestamp)
                }
            }
        }
    }
}

struct Item: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var name: String
    var details: String
    var price: Double
    var photoURL: String
    var condition: String
    var description: String
    var timestamp: Date
}




