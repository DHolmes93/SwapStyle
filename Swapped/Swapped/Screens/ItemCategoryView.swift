//
//  ItemCategoryView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/5/24.
//

import SwiftUI

struct ItemCategoryView: View {
    let item: Item
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
    
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
            .frame(width: 150, height: 150)
            .cornerRadius(5)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .cornerRadius(5)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}

//#Preview {
//    let mockItem = Item(
//                name: "Sample Item",
//                details: "Sample details",
//                originalprice: 120.0,
//                value: 84,
//                imageUrls: ["https://via.placeholder.com/150"],
//                condition: "Good",
//                timestamp: Date(),
//                uid: "45768403j",
//                category: "Sports", subcategory: "Ball",
//                userName: "Flower Pot",
//                latitude: 0.0,
//                longitude: 0.0
//            )
//    
//    return ItemCategoryView(item: mockItem)
//        .previewLayout(.fixed(width: 300, height: 200))
//        .padding()
//}
