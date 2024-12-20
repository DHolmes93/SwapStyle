//
//  itemRowView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/8/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct itemRowView: View {
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
    @EnvironmentObject private var itemManager: ItemManager
    @EnvironmentObject private var themeManager: ThemeManager
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
                Text(String(format: "%.2f", item.originalprice))
            }
            Spacer()
            NavigationLink(destination: EditItemView(item: item)) {
                Text("Edit")
                    .foregroundStyle(Color(themeManager.theme.mainColor))
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}
                           

//#Preview {
//    itemRowView(item: Item(name: "Sports Fishing Rod",
//                           details: "40ft Fishing Rod",
//                           originalprice: 30,
//                           value: 15,
//                           imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
//                           condition: "New",
//                           timestamp: Date(),
//                           uid: "testUID",
//                           category: "Sports", subcategory: "Ball",
//                           userName: "Joe",
//                           latitude: 0.0,
//                           longitude: 0.0))
//        .previewLayout(.sizeThatFits)
//                           
//                         
//}
