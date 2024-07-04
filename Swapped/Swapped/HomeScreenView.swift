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
                                if let url = URL(string: item.imageUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: 200, maxHeight: 200)
                                    } placeholder: {
                                        ProgressView()
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
            }
            .onAppear {
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
        .environmentObject(swapCart)
            
    }
}

#Preview {
    HomeScreenView()
}
