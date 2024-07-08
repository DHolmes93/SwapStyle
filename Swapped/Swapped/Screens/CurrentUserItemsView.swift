//
//  CurrentUserItems.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/4/24.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift


struct CurrentUserItemsView: View {
    @StateObject private var itemManager = ItemManager.shared
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if itemManager.items.isEmpty {
                        Text("No items found")
                            .font(.headline)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack {
                                ForEach(itemManager.items) { item in
                                    itemRowView(item: item)
                                        .padding(.horizontal)
                                        .padding(.top, 5)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("My Items")
                .onAppear {
                    itemManager.fetchItems { result in
                        switch result {
                        case .success(let items):
                            itemManager.items = items
                        case .failure(let error):
                            print("Error fetch items: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}


#Preview {
    let itemManager = ItemManager.shared
          itemManager.items = [
              Item(name: "Sample Item 1",
                   details: "Details 1",
                   price: 19.99,
                   imageUrls: ["https://via.placeholder.com/150"],
                   condition: "New",
                   description: "Description 1",
                   timestamp: Date(),
                   uid: "uid1",
                   category: "Category 1",
                   userName: "User 1"),
              Item(name: "Sample Item 2",
                   details: "Details 2",
                   price: 29.99,
                   imageUrls: ["https://via.placeholder.com/150"],
                   condition: "Used",
                   description: "Description 2",
                   timestamp: Date(),
                   uid: "uid2",
                   category: "Category 2",
                   userName: "User 2")
          ]
          
          return CurrentUserItemsView()
              .environmentObject(itemManager)
    ()
}
