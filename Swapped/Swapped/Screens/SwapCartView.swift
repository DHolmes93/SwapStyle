//
//  SwapCartView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/4/24.
//

import SwiftUI

struct SwapCartView: View {
    @EnvironmentObject var swapCart: SwapCart
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                List {
                    ForEach(swapCart.items) { item in
                        VStack(alignment: .leading) {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(item.imageUrls, id: \.self) { imageUrl in
                                        AsyncImage(url: URL(string: imageUrl)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(5)
                                    }
                                }
                            }
                        }
                            
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                Text("Price: $\(item.price, specifier: "%.2f")")
                            }
                            Spacer()
                            Button(action: {
                                swapCart.removeItem(item)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            
                        }
                    }
                }
                Button(action: {
                    swapCart.clearCart()
                }) {
                    Text("Empty Cart")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(5)
                }
                .padding()
            }
                
            .navigationTitle("Cart")
        }
    }
}

#Preview {
    let mockItem1 = Item(
            name: "Sample Item",
            details: "Sample details",
            price: 120.0,
            imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
            condition: "Good",
            description: "This is a sample description of the item.",
            timestamp: Date(),
            uid: "45768403j",
            category: "Sports"
        )

        let mockItem2 = Item(
            name: "Sample Item 2",
            details: "Sample details",
            price: 80.0,
            imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
            condition: "Good",
            description: "This is another sample description of the item.",
            timestamp: Date(),
            uid: "45768403j",
            category: "Electronics"
        )

        let cart = SwapCart.shared
        cart.addItem(mockItem1)
        cart.addItem(mockItem2)

        return SwapCartView().environmentObject(cart)
    }
    

