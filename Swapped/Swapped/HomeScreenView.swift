//
//  HomeScreenView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//

import SwiftUI

struct HomeScreenView: View {
    @StateObject private var itemManager = ItemManager.shared
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
                    ForEach(itemManager.items) { item in Text(item.name)
                            .padding(.horizontal)
                    }
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
    }
}

#Preview {
    HomeScreenView()
}
