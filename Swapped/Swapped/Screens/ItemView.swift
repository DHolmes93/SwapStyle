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
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AsyncImage(url: URL(string: item.photoURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(maxHeight: 400)
            .cornerRadius(10)
            Text(item.name)
                .font(.headline)
            Text("Condition: \(item.condition)")
                .font(.subheadline)
            Text("Price: $\(item.price, specifier: "%.2f")")
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
        }
        .padding()
    }
    func isPossibleSwapMatch(for item: Item) -> Bool {
        let userItemPrice: Double = 100.0
        let userItemCondition: String = "Good"
        let priceDifference = abs(item.price - userItemPrice)
        return item.condition == userItemCondition && priceDifference <= 20.0
        }
    }


#Preview {
    let mockItem = Item(
                id: "1",
                userId: "user123",
                name: "Sample Item",
                details: "Sample details",
                price: 120.0,
                photoURL: "https://via.placeholder.com/150",
                condition: "Good",
                description: "This is a sample description of the item.",
                timestamp: Date()
            )
    return ItemView(item: mockItem)
}
