//
//  ItemView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import SwiftUI

struct ItemView: View {
    let item: Item
    @State private var animateSwap = false
    @State private var addedToCart = false
    @EnvironmentObject private var swapCart: SwapCart
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                        .frame(maxHeight: 400)
                        .cornerRadius(10)
                    }
                }
            }
            Text("Product Owner: \(item.userName ?? "Unknown User")")
            Text(item.name)
                .font(.headline)
            Text("Condition: \(item.condition)")
                .font(.subheadline)
            Text("Price: $\(item.price, specifier: "%.2f")")
                .font(.subheadline)
            Text("Category: \(item.category)")
                .font(.subheadline)
            GeometryReader { geometry in
                VStack {
                    Text("Description: \(item.description)")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    if isPossibleSwapMatch(for: item) {
                        Text("Swap Possible")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                            .scaleEffect(animateSwap ? 1.5 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true))
                            .onAppear {
                                self.animateSwap = true
                            }
                            .offset(x: min(geometry.size.width, 20), y: geometry.size.height - 20)
                    }
                    
                }
                
            }
            .frame(height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
            HStack(spacing: 90) {
            Button(action: {
                swapCart.addItem(item)
                addedToCart = true
            }) {
                Text(addedToCart ? "Added" : "Add to Cart")
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(5)
            }
            NavigationLink(destination: MessagingScreenView(currentUserId: "currentUserId", otherUserId: item.uid, chatId: "\(item.uid)_chat")) {
                Text("Send Message")
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(5)
            }
        }
    }
        .padding()
    }
    func isPossibleSwapMatch(for item: Item) -> Bool {
        for cartItem in swapCart.items {
            let priceDifference = abs(item.price - cartItem.price)
            if item.condition == cartItem.condition && priceDifference <= 20.0 {
                return true
            }
        }
        return false
    }
}


#Preview {
    let mockItem = Item(
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
    let cart = SwapCart.shared
    return ItemView(item: mockItem)
        .environmentObject(cart)
}
