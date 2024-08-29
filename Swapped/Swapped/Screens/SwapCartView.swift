//
//  SwapCartView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/4/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestoreSwift

struct SwapCartView: View {
    @EnvironmentObject private var swapCart: SwapCart
    @State private var errorMessage: String?
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
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
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(5)
                                    }
                                }
                            }
                       
                            
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                Text("Original Price: $\(item.originalprice, specifier: "%.2f")")
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
            .onAppear {
                swapCart.fetchCart()
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
            originalprice: 120.0,
            value: 80.0,
            imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
            condition: "Good",
            timestamp: Date(),
            uid: "45768403j",
            category: "Sports"
        )

        let mockItem2 = Item(
            name: "Sample Item 2",
            details: "Sample details",
            originalprice: 80.0,
            value: 66.0,
            imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
            condition: "Good",
            timestamp: Date(),
            uid: "45768403j",
            category: "Electronics"
        )

        let cart = SwapCart.shared
        cart.addItem(mockItem1)
        cart.addItem(mockItem2)

        return SwapCartView().environmentObject(cart)
    }
    

