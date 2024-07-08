//
//  SwapCart.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/4/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift


class SwapCart: ObservableObject {
    @Published var items: [Item] = []
    
    static let shared = SwapCart()
    
    private init() {}
    
    func addItem(_ item: Item) {
        if !items.contains(where: { $0.id == item.id }) {
            items.append(item)
            saveItemToFirestore(item)
        }
    }
    
    func removeItem(_ item: Item) {
        items.removeAll() { $0.id == item.id }
        removeItemFromFirestore(item)
    }
    
    func clearCart() {
        items.removeAll()
        clearCartInFirestore()
    }
    private func saveItemToFirestore(_ item: Item) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
            
        }
        let db = Firestore.firestore()
        let cartItemData: [String: Any] = [
            "uid": uid,
            "name": item.name,
            "details": item.details,
            "price": item.price,
            "condition": item.condition,
            "description": item.description,
            "timestamp": Timestamp(date: item.timestamp),
            "category": item.category,
            "imageUrls": item.imageUrls,
            "userName": item.userName ?? "Unknown User"
        ]
        db.collection("users").document(uid).collection("cartItems").document(item.id ?? UUID().uuidString).setData(cartItemData) {
            error in
            if let error = error {
                print("Error saving cart item to Firestore: \(error)")
            } else {
                print("Cart item successfully saved to Firestore")
            }
        }
    }
    private func removeItemFromFirestore(_ item: Item) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("cartItems").document(item.id ?? UUID().uuidString).delete() {
            error in
            if let error = error {
                print("Error removing cart item from Firestone: \(error)")
            } else {
                print("Cart item successfully removed from Firestone")
            }
        }
    }
    private func clearCartInFirestore() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }
        let db = Firestore.firestore()
        let cartItemsRef = db.collection("users").document(uid).collection("cartItems")
        cartItemsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching cart items: \(error)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No cart items found")
                return
            }
            for document in documents {
                document.reference.delete { error in
                    if let error = error {
                        print("Error removing cart items: \(error)")
                    } else {
                        print("Cart items successfully removed")
                    }
                }
            }
        }
    }
    func fetchCartItems() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }
        let db = Firestore.firestore()
        let cartItemsRef = db.collection("users").document(uid).collection("cartItems")
        cartItemsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching cart items: \(error)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No cart items found")
                return
            }
            self.items = documents.compactMap { document in
                try? document.data(as: Item.self)
            }
        }
    }
}
