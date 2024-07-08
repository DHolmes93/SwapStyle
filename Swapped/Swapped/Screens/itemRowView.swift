//
//  itemRowView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/8/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct itemRowView: View {
    let item: Item
    var body: some View {
        HStack {
            if let firstImageUrl = item.imageUrls.first,let url = URL(string: firstImageUrl) {
                WebImage(url: url)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
            }
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                Text(item.details)
                    .font(.headline)
                Text(String(format: "%.2f", item.price))
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    itemRowView(item: Item(name: "Sports Fishing Rod",
                           details: "40ft Fishing Rod",
                           price: 30,
                           imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
                           condition: "New",
                           description: "",
                           timestamp: Date(),
                           uid: "testUID",
                           category: "Sports",
                           userName: "Joe"))
        .previewLayout(.sizeThatFits)
                           
                         
}
