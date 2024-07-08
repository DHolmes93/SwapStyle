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
                            .foregroundStyle(Color.red)
                            .padding()
                    }
                    ForEach(itemManager.items) { item in
                        NavigationLink(destination: ItemView(item: item)) {
                            VStack(alignment: .leading, spacing: 8) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(alignment: .center, spacing: 12) {
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
                                    .padding(.horizontal)
                                    .padding()
                                Text(item.category)
                                    .padding(.top, 2)
                                Text(item.description)
                                    .padding(.horizontal)
                                    .padding(.top, 2)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        .padding(.horizontal)
                    }
                    
                }
                .padding(.top, 20)
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
    private func fetchMessageCount() {
            messageCount = 3
    }
}
#Preview {
    HomeScreenView()
}

