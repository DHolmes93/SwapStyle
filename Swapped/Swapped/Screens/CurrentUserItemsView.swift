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
import SDWebImage


struct CurrentUserItemsView: View {
    var itemToSwap: Item?
    @State private var initiateSwap = false
    @EnvironmentObject private var itemManager: ItemManager
    @EnvironmentObject private var swapCart: SwapCart
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
//                    if itemManager.items.isEmpty {
//                        Text("No items found")
//                            .font(.headline)
//                            .padding()
//                    } else {
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
    @ViewBuilder
    func itemRowsView(item: Item) -> some View {
        HStack {
                Text(item.name)
                    .font(.headline)
            Spacer()
            NavigationLink(destination: EditItemView(item: item)) {
                Text("Edit")
                    .foregroundStyle(Color.blue)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    private func initiateSwapButton(for item: Item) -> some View {
        Button(action:{
            initiateSwapAction(for: item)
        }) {
            Text("Initiate Swap")
                .foregroundStyle(Color.blue)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .cornerRadius(8)
                
        }
        .padding(.trailing)
    }
    private func initiateSwapAction(for item: Item) {
        guard let itemToSwap = itemToSwap else { return }
        
        let fromItemId = item.id ?? ""
        let toItemId = itemToSwap.id ?? ""
        
        itemManager.requestSwap(fromItemId: fromItemId, toUserId: itemToSwap.uid, toItemId: toItemId) {
            result in switch result {
            case . success:
                print("Swap request sent successfully")
            case .failure(let error):
                print("Failed to send swap request \(error.localizedDescription)")
            }
        }
    }
}


#Preview {
    let itemManager = ItemManager.shared
    let swapCart = SwapCart.shared
          itemManager.items = [
              Item(name: "Sample Item 1",
                   details: "Details 1",
                   originalprice: 19.99,
                   value: 10,
                   imageUrls: ["https://via.placeholder.com/150"],
                   condition: "New",
                   timestamp: Date(),
                   uid: "uid1",
                   category: "Category 1",
                   userName: "User 1"),
              Item(name: "Sample Item 2",
                   details: "Details 2",
                   originalprice: 29.99,
                   value: 34,
                   imageUrls: ["https://via.placeholder.com/150"],
                   condition: "Used",
                   timestamp: Date(),
                   uid: "uid2",
                   category: "Category 2",
                   userName: "User 2")
          ]
          
          return CurrentUserItemsView()
              .environmentObject(itemManager)
              .environmentObject(swapCart)
}
