//
//  StandardItemView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/17/24.
//

import SwiftUI

struct StandardItemView: View {

@EnvironmentObject private var itemManager: ItemManager
@State private var fullScreenImage: IdentifiableURL?
let item: Item

var body: some View {
NavigationStack {
VStack(alignment: .leading, spacing: 10) {
ScrollView(.horizontal) {
HStack(alignment: .center, spacing: 12) {
    ForEach(item.imageUrls, id: \.self) { imageUrl in
        AsyncImage(url: URL(string: imageUrl)) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 1000, maxHeight: 1000)
                    .cornerRadius(10)
                    .onTapGesture {
                        if let url = URL(string: imageUrl) {
                            fullScreenImage = IdentifiableURL(url: url)
                        }
                    }
            case .failure:
                Text("Failed to load")
                    .foregroundStyle(Color.red)
            @unknown default:
                EmptyView()
                }
            }
        }
    }
}
.frame(height: 100)

Text("Product Owner: \(item.userName)")
    
Text(item.name)
    .font(.headline)
    
Text("Condition: \(item.condition)")
    .font(.subheadline)
    
Text("Value: $\(item.value, specifier: "%.2f")")
    .font(.subheadline)
}
.padding()
            
            .fullScreenCover(item: $fullScreenImage) { identifiableURL in
                AsyncImage(url: identifiableURL.url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                    case .failure:
                        Text("Failed to load")
                            .foregroundStyle(Color.red)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                .onTapGesture {
                    fullScreenImage = nil
                }
            }
        }
    }
}

//#Preview {
//    let itemManager = ItemManager.shared
//    let mockItem1 = Item(
//                name: "Sample Item",
//                details: "Sample details",
//                originalprice: 120.0,
//                value:80,
//                imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
//                condition: "Good",
//                timestamp: Date(),
//                uid: "45768403j",
//                category: "Sports", subcategory: "Ball",
//                userName: "Flower Pot",
//                latitude: 0.0,
//                longitude: 0.0
//            )
//    return StandardItemView(item: mockItem1)
//        .environmentObject(itemManager)
//}

