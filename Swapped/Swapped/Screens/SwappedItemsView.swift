//
//  SwappedView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//
//
//import SwiftUI
//import FirebaseAuth
//import FirebaseFirestore
//import FirebaseFirestoreSwift
//
//struct SwappedItemsView: View {
//    @EnvironmentObject var swapCart: SwapCart
//    @StateObject private var itemManager = ItemManager.shared
//    @State private var swappedItems: [Item] = []
//    @State private var selectedView = "Swapped Items"
//    var body: some View {
//        List(swappedItems) { item in
//            VStack(alignment: .leading) {
//                Text(item.name)
//                    .font(.headline)
//                Text(item.details)
//                    .font(.subheadline)
//                Text("Category: \(item.category)")
//                    .font(.subheadline)
//                Text("Condition: \(item.condition)")
//                    .font(.subheadline)
//                Text("Swapped with: \(item.userName)")
//                    .font(.subheadline)
//                Text("Date: \(item.timestamp, formatter: itemDateFormatter)")
//                    .font(.subheadline)
//            }
//            
//        }
//        .onAppear {
//            fetchSwappedItems()
//        }
//    }
//    private func fetchSwappedItems() {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        
//        let db = Firestore.firestore()
//        db.collection("swapRequests")
//            .whereField("status", isEqualTo: "accepted")
//            .whereField("fromUserId", isEqualTo: uid)
//            .getDocuments { snapshot, error in
//                if let error = error {
//                    print("Error fetching swapped items: \(error)")
//                    return
//                }
//                let swapRequests = snapshot?.documents.compactMap { document in
//                    try? document.data(as: SwapRequest.self)
//                } ?? []
//                let itemIds = swapRequests.map { $0.toItemId }
//                
//                guard !itemIds.isEmpty else {
//                    print("No item IDs found.")
//                    self.swappedItems = []
//                    return
//                }
//                self.fetchItemsByIds(itemIds: itemIds) { result in
//                    switch result {
//                    case .success(let items):
//                        swappedItems = items
//                    case .failure(let error):
//                        print("Error fetching items by ids: \(error)")
//                    }
//                }
//            }
//    }
//    
//    private func fetchItemsByIds(itemIds: [String], completion: @escaping (Result<[Item], Error>) -> Void) {
//        let db = Firestore.firestore()
//        let itemsRef = db.collection("items").whereField(FieldPath.documentID(), in: itemIds)
//        itemsRef.getDocuments { snapshot, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            let items = snapshot?.documents.compactMap { document in
//                try? document.data(as: Item.self)
//            } ?? []
//            completion(.success(items))
//        }
//    }
//}
//
//private let itemDateFormatter: DateFormatter = {
//    let formatter = DateFormatter()
//    formatter.dateStyle = .short
//    formatter.timeStyle = .short
//    return formatter
//}()
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

struct SwappedItemsView: View {
    @EnvironmentObject var swapCart: SwapCart
    @StateObject private var itemManager = ItemManager.shared
    @State private var swappedItems: [Item] = []
    @State private var selectedView = "Swapped Items"

    var body: some View {
        List(swappedItems) { item in
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                Text(item.details)
                    .font(.subheadline)
                Text("Category: \(item.selectedCategory)") // Updated to reflect property name change
                    .font(.subheadline)
                Text("Condition: \(item.condition)")
                    .font(.subheadline)
                Text("Swapped with: \(item.userName)")
                    .font(.subheadline)
                Text("Date: \(item.timestamp, formatter: itemDateFormatter)")
                    .font(.subheadline)
            }
        }
        .onAppear {
            fetchSwappedItems()
        }
    }

    private func fetchSwappedItems() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("swapRequests")
            .whereField("status", isEqualTo: "accepted")
            .whereField("fromUserId", isEqualTo: uid)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching swapped items: \(error)")
                    return
                }
                let swapRequests = snapshot?.documents.compactMap { document in
                    try? document.data(as: SwapRequest.self)
                } ?? []
                let itemIds = swapRequests.map { $0.toItemId }
                
                guard !itemIds.isEmpty else {
                    print("No item IDs found.")
                    self.swappedItems = []
                    return
                }
                self.fetchItemsByIds(itemIds: itemIds) { result in
                    switch result {
                    case .success(let items):
                        swappedItems = items
                    case .failure(let error):
                        print("Error fetching items by ids: \(error)")
                    }
                }
            }
    }
    
    private func fetchItemsByIds(itemIds: [String], completion: @escaping (Result<[Item], Error>) -> Void) {
        let db = Firestore.firestore()
        let itemsRef = db.collection("items").whereField(FieldPath.documentID(), in: itemIds)
        itemsRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let items = snapshot?.documents.compactMap { document in
                try? document.data(as: Item.self)
            } ?? []
            completion(.success(items))
        }
    }
}

private let itemDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()


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
