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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                        Color.red
                            .padding()
                    }
                    ForEach(itemManager.items) { item in
                        NavigationLink(destination: ItemView(item: item)) {
                            VStack(alignment: .leading) {
                                ScrollView(.horizontal) {
                                    HStack {
                                        ForEach(item.imageUrls, id: \.self) { imageUrl in
                                            if let url = URL(string: imageUrl) {
                                                AsyncImage(url: url) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(maxWidth: 200, maxHeight: 200)
                                                } placeholder: {
                                                    ProgressView()
                                                }
                                            }
                                        }
                                    }
                                }
                                Text(item.name)
                                    .padding(.horizontal)
                                    .font(.headline)
                                Text(item.details)
                                    .padding(.horizontal)
                                    .font(.headline)
                                Text("$\(item.price, specifier: "%.2f")")
                                    .padding(.top, 2)
                                Text(item.condition)
                                    .padding()
                                Text(item.category)
                                    .padding()
                                Text(item.description)
                                    .padding()
                            }
                            
                        }
                    }
                        .padding()
                }
                .padding(.top, 20)
                .navigationBarTitle("Items")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        messageButton
                    }
                }
            }
            .onAppear {
                if !isPreview {
                    itemManager.fetchItems { result in
                        switch result {
                        case .success(let items):
                            print("Fetched items: \(items)")
                        case .failure(let error):
                            errorMessage = "Failed to load items: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
        .environmentObject(swapCart)
            
    }
    private var messageButton: some View {
        NavigationLink(destination: MessagingScreenView(currentUserId: "currentUserId", otherUserId: "otherUserId", chatId: "chatId")) {
            ZStack {
                Image(systemName: "message")
                    .resizable()
                    .frame(width: 24, height: 24)
                if messageCount > 0 {
                    Text("\(messageCount)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                    clipShape(Circle())
                        .offset(x: 12, y: 12)
                }
            }
        }
    }
    private var isPreview: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
    }
                       private func fetchMessageCount() {
            messageCount = 3
        }
}

#Preview {
    HomeScreenView()
}
