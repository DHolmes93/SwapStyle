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
    @State private var showPossibleSwap = false
    @EnvironmentObject private var swapCart: SwapCart
    @EnvironmentObject private var itemManager: ItemManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                ScrollView(.horizontal) {
                    HStack(alignment: .center, spacing: 12) {
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
                .padding(.horizontal)
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
                        
                        if isPossibleSwapMatch(for: item, swapCart: SwapCart.shared) {
                            Text("Swap Possible")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                                .scaleEffect(animateSwap ? 1.5 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true))
                                .onAppear {
                                    self.animateSwap = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                        self.showPossibleSwap = false
                                    }
                                }
                                .offset(x: min(geometry.size.width, 20), y: geometry.size.height - 20)
                        }
                        
                    }
                    
                }
                .frame(height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                HStack(spacing: 90) {
                    Button(action: {
                        addToCart(swapCart: SwapCart.shared)
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
            .navigationBarItems(trailing: cartButton(swapCart: SwapCart.shared))
        }
        .onAppear {
            determinePossibleSwap()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
        }
    }
    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundStyle(Color("mainColor"))
                .imageScale(.large)
        }
    }
    private func cartButton(swapCart: SwapCart) -> some View {
        NavigationLink(destination: SwapCartView()) {
            ZStack {
                Image(systemName: "cart")
                    .resizable()
                    .frame(width: 24, height: 24)
                    if swapCart.items.count > 0 {
                        Text("\(swapCart.items.count)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 12, y: -12)
                    }
                }
            }
            
        }
    private func addToCart(swapCart: SwapCart) {
        swapCart.addItem(item)
        addedToCart = true
    }
    
    func isPossibleSwapMatch(for item: Item, swapCart: SwapCart) -> Bool {
        for cartItem in swapCart.items {
            let priceDifference = abs(item.price - cartItem.price)
            if item.condition == cartItem.condition && priceDifference <= 20.0 {
                return true
            }
        }
        return false
    }
    private func determinePossibleSwap() {
        if itemManager.items.contains(where: { $0.id == item.id}) {
            showPossibleSwap = false
        } else {
            showPossibleSwap = true
        }
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
    let itemManager = ItemManager.shared
    return NavigationStack {
        ItemView(item: mockItem)
            .environmentObject(cart)
            .environmentObject(itemManager)
    }
}
