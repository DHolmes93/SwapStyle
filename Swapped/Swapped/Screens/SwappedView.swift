//
//  SwappedView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//

import SwiftUI

struct SwappedView: View {
    @EnvironmentObject var swapCart: SwapCart
    @State private var selectedView = "Swapped Items"
    var body: some View {
            VStack {
                Picker("Select View", selection: $selectedView) {
                    Text("Swapped Items").tag("Swapped Items")
                    Text("Cart").tag("Cart")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedView == "Cart" {
                    SwapCartView()
                } else {
                    SwappedItemsView()
                }
                   
                    
                }
            .navigationTitle("Swapped View")
            }
        }
    


#Preview {
    let mockItem1 = Item(
            name: "Flower Pot",
            details: "Round",
            price: 120.0,
            imageUrl: "https://via.placeholder.com/150",
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
            imageUrl: "https://via.placeholder.com/150",
            condition: "Good",
            description: "This is another sample description of the item.",
            timestamp: Date(),
            uid: "45768403j",
            category: "Electronics"
        )

        let cart = SwapCart.shared
        cart.addItem(mockItem1)
        cart.addItem(mockItem2)

        return SwappedView().environmentObject(cart)
}
