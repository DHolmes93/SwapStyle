//
//  CurrentUserItems.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/4/24.
//
//import SwiftUI
//import Firebase
//import FirebaseAuth
//import FirebaseFirestore
//import FirebaseFirestoreSwift
//import SDWebImage
//
//struct CurrentUserItemsView: View {
//    var itemToSwap: Item?
//    @State private var initiateSwap = false
//    @EnvironmentObject private var itemManager: ItemManager
//    @EnvironmentObject private var swapCart: SwapCart
//    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack {
//                    if itemManager.items.isEmpty {
//                        Text("No items found")
//                            .font(.headline)
//                            .padding()
//                    } else {
//                        ScrollView {
//                            LazyVStack {
//                                ForEach(itemManager.items.filter { $0.userName == viewModel.name ?? "unknown" }
//                                            ) { item in
//                                    itemRowView(item: item)
//                                        .padding(.horizontal)
//                                        .padding(.top, 5)
//                                }
//                            }
//                        }
//                }
//                .navigationTitle("My Items")
//                .onAppear {
//                    Task {
//                        do {
//                            let items = try await itemManager.fetchItems()
//                            itemManager.items = items
//                        } catch {
//                            print("Error fetching items: \(error.localizedDescription)")
//                        }
//                    }
//                }
//            }
//        }
//    }
//    @ViewBuilder
//    func itemRowsView(item: Item) -> some View {
//        HStack {
//                Text(item.name)
//                    .font(.headline)
//            Spacer()
//            NavigationLink(destination: EditItemView(item: item)) {
//                Text("Edit")
//                    .foregroundStyle(Color.blue)
//                    .padding(.horizontal)
//                    .padding(.vertical, 6)
//                    .cornerRadius(8)
//            }
//        }
//        .padding()
//    }
//    private func initiateSwapButton(for item: Item) -> some View {
//        Button(action:{
//            initiateSwapAction(for: item)
//        }) {
//            Text("Initiate Swap")
//                .foregroundStyle(Color.blue)
//                .padding(.horizontal)
//                .padding(.vertical, 6)
//                .cornerRadius(8)
//                
//        }
//        .padding(.trailing)
//    }
//    private func initiateSwapAction(for item: Item) {
//        guard let itemToSwap = itemToSwap else { return }
//
//        let fromItemId = item.id ?? ""
//        let toItemId = itemToSwap.id ?? ""
//
//        Task {
//            do {
//                try await itemManager.requestSwap(fromItemId: fromItemId, toUserId: itemToSwap.uid, toItemId: toItemId)
//                print("Swap request sent successfully")
//            } catch {
//                print("Failed to send swap request: \(error.localizedDescription)")
//            }
//        }
//    }
//}
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import SDWebImage

struct CurrentUserItemsView: View {
    var itemToSwap: Item?
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
    @State private var initiateSwap = false
    @EnvironmentObject private var itemManager: ItemManager
    @EnvironmentObject private var swapCart: SwapCart
    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if itemManager.items.isEmpty {
                        Text("No items found")
                            .font(.headline)
                            .padding()
                    } else {
                        LazyVStack {
                            ForEach(itemManager.items.filter { $0.userName == viewModel.name }) { item in
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
                Task {
                    do {
                        let items = try await itemManager.fetchItems()
                        itemManager.items = items
                    } catch {
                        print("Error fetching items: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func itemRowView(item: Item) -> some View {
        HStack {
            // Display item image (if available)
            if let imageUrlString = item.imageUrls.first, let url = URL(string: imageUrlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    ProgressView()
                        .frame(width: 40, height: 40)
                }
            } else {
                // Placeholder image if no URL is available
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .foregroundColor(.gray)
            }
            
            // Item name
            Text(item.name)
                .font(.headline)
                .lineLimit(1)
                .padding(.leading, 8)
            
            Spacer()
            
            // Navigation link to edit the item
            NavigationLink(destination: EditItemView(item: item)) {
                Text("Edit")
                    .foregroundColor(.blue)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Initiate swap button
            initiateSwapButton(for: item)
        }
        .padding()
    }
    
    func initiateSwapButton(for item: Item) -> some View {
        Button(action: {
            initiateSwapAction(for: item)
        }) {
            Text("Initiate Swap")
                .foregroundColor(.blue)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(.trailing)
    }
    
    private func initiateSwapAction(for item: Item) {
        guard let itemToSwap = itemToSwap else { return }
        
        let fromItemId = item.id ?? ""
        let toItemId = itemToSwap.id ?? ""
        
        Task {
            do {
                try await itemManager.requestSwap(fromItemId: fromItemId, toUserId: itemToSwap.uid, toItemId: toItemId)
                print("Swap request sent successfully")
            } catch {
                print("Failed to send swap request: \(error.localizedDescription)")
            }
        }
    }
}

//
//#Preview {
//    let itemManager = ItemManager.shared
//    let swapCart = SwapCart.shared
//          itemManager.items = [
//              Item(name: "Sample Item 1",
//                   details: "Details 1",
//                   originalprice: 19.99,
//                   value: 10,
//                   imageUrls: ["https://via.placeholder.com/150"],
//                   condition: "New",
//                   timestamp: Date(),
//                   uid: "uid1",
//                   category: "Category 1", subcategory: "Sd",
//                   userName: "User 1",
//                   latitude: 0.0,
//                   longitude: 0.0),
//              
//              Item(name: "Sample Item 2",
//                   details: "Details 2",
//                   originalprice: 29.99,
//                   value: 34,
//                   imageUrls: ["https://via.placeholder.com/150"],
//                   condition: "Used",
//                   timestamp: Date(),
//                   uid: "uid2",
//                   category: "Category 2", subcategory: "DDE",
//                   userName: "User 2",
//                   latitude: 0.0,
//                   longitude: 0.0)
//          ]
//          
//          return CurrentUserItemsView()
//              .environmentObject(itemManager)
//              .environmentObject(swapCart)
//}
