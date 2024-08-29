//
//  HomeScreenView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//

import SwiftUI

struct HomeScreenView: View {
    @StateObject private var itemManager = ItemManager.shared
    @StateObject private var swapCart = SwapCart.shared
    @State private var errorMessage: String?
    @State private var messageCount: Int = 0
    @State private var isLoading: Bool = false
    
    init(items: [Item] = []) {
           let itemManager = ItemManager.shared
           if !items.isEmpty {
               itemManager.items = items
           }
           _itemManager = StateObject(wrappedValue: itemManager)
       }
    
    var body: some View {
        NavigationStack {
            content
                .onAppear {
                    if !isPreview {
                        fetchItems()
                    }
                }
                .environmentObject(swapCart)
        }
    }
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                    errorMessageView
                    itemsListView
                
            }
            .padding(.horizontal)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Home")
                        .font(.headline)
                        .foregroundStyle(Color("secondColor"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    messageButton
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    accountButton
                }
            }
        }
    }
    private var errorMessageView: some View {
        Group {
            if let errorMessage = errorMessage {
                 Text(errorMessage)
                    .foregroundStyle(Color.red)
                    .padding()
            } else {
                EmptyView()
            }
        }
    }
    private var itemsListView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
        ForEach(itemManager.items) { item in
                NavigationLink(destination: ItemView(item: item)) {
                    VStack {
                        //                        ScrollView(.horizontal, showsIndicators: false) {
                        imagesGridView(for: item)
                            .frame(width: 200, height: 200)
                            .padding(.leading, 0)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("$\(item.originalprice, specifier: "%.2f")")
                                .padding(.top, 2)
                                .font(.headline)
                            Text(item.name)
                                .font(.subheadline)
                            Text(item.details)
                                .font(.subheadline)
                            Text(item.condition)
                                .padding(.vertical, 4)
                                .font(.subheadline)
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 8) // Add some leading padding to the VStack
                    }
                    .padding()
                }
                Divider()
                    .background(Color("secondColor"))
            }
        }
    }
        
        
                                    
    private func imagesGridView(for item: Item) -> some View {
//        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))]) {
        VStack {
            ForEach(item.imageUrls.prefix(1), id: \.self) { imageUrl in
                    if let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 200)
                                .clipped()
                        } placeholder: {
                            ProgressView()
                        }
                        
                    }
                   
                }
            }
        }
                                                  private var messageButton: some View {
                                     NavigationLink(destination: NewMessageView(currentUserId: "currentUserId")) {
                                                 ZStack {
                                                     Image(systemName: "message")
                                                         .resizable()
                                                         .frame(width: 24, height: 24)
                                                         .foregroundStyle(Color("mainColor"))
                                                     if messageCount > 0 {
                                                         Text("\(messageCount)")
                                                             .font(.caption2)
                                                             .foregroundColor(.white)
                                                             .padding(4)
                                                             .background(Color.red)
                                                             .clipShape(Circle())
                                                             .offset(x: 12, y: 12)
                                                     }
                                                 }
                                             }
                                         }
                                                      private var accountButton: some View {
                                                          NavigationLink(destination: AccountView()) {
                                                          Image(systemName: "person.circle")
                                                              .resizable()
                                                              .frame(width: 24, height: 24)
                                                              .foregroundStyle(Color("mainColor"))
                                                      }
                                                  }
                                                      private var isPreview: Bool {
                                                          #if DEBUG
                                                          return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
                                                          #else
                                                          return false
                                                          #endif
                                                      }
                                                  private func fetchItems() {
                                                         itemManager.fetchAllItems { result in
                                                             switch result {
                                                             case .success(let items):
                                                                 print("Fetched items: \(items)")
                                                             case .failure(let error):
                                                                 errorMessage = "Failed to load items: \(error.localizedDescription)"
                                                             }
                                                         }
                                                     }
                                                 }
                                     

#Preview {
    let mockItems = [
               Item(
                   name: "Sample Item 1",
                   details: "This is a sample item used for previews.",
                   originalprice: 19.99,
                   value: 15.99,
                   imageUrls: ["https://via.placeholder.com/200", "https://via.placeholder.com/200"],
                   condition: "New",
                   timestamp: Date(),
                   uid: "sampleUserId1",
                   category: "Electronics",
                   userName: "John Doe",
                   latitude: 37.7749,
                   longitude: -122.4194
               ),
               Item(
                   name: "Sample Item 2",
                   details: "This is another sample item used for previews.",
                   originalprice: 29.99,
                   value: 25.99,
                   imageUrls: ["https://via.placeholder.com/200", "https://via.placeholder.com/100"],
                   condition: "Used",
                   timestamp: Date(),
                   uid: "sampleUserId2",
                   category: "Books",
                   userName: "Jane Smith",
                   latitude: 34.0522,
                   longitude: -118.2437
               ),
               Item(
                   name: "Sample Item 3",
                   details: "This is yet another sample item used for previews.",
                   originalprice: 9.99,
                   value: 7.99,
                   imageUrls: ["https://via.placeholder.com/200", "https://via.placeholder.com/200"],
                   condition: "Good",
                   timestamp: Date(),
                   uid: "sampleUserId3",
                   category: "Clothing",
                   userName: "Alice Johnson",
                   latitude: 40.7128,
                   longitude: -74.0060
               )
           ]
    
    return HomeScreenView(items: mockItems)
        .environmentObject(SwapCart.shared)

    
}
