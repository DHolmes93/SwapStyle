//
//  ItemCategoryView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/5/24.
//

import SwiftUI

struct ItemCategoryView: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading) {
            if let urlString = item.imageUrls.first, let url =
                URL(string: urlString) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 100)
            .cornerRadius(5)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 100)
                    .cornerRadius(5)
                    .foregroundColor(.gray)
            }
            
            Text(item.name)
                .font(.headline)
            Text("Price: $\(item.price, specifier: "%.2f")")
                .font(.subheadline)
            Text("Condition: \(item.condition)")
                .font(.subheadline)
            Text("Category: \(item.category)")
                .font(.subheadline)
        }
        .padding()
    }
}

#Preview {
    let mockItem = Item(
                name: "Sample Item",
                details: "Sample details",
                price: 120.0,
                imageUrls: ["https://via.placeholder.com/150"],
                condition: "Good",
                description: "This is a sample description of the item.",
                timestamp: Date(),
                uid: "45768403j",
                category: "Sports"
            )
    
    return ItemCategoryView(item: mockItem)
        .previewLayout(.fixed(width: 300, height: 200))
        .padding()
}
