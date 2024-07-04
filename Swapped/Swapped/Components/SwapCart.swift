//
//  SwapCart.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/4/24.
//

import Foundation


class SwapCart: ObservableObject {
    @Published var items: [Item] = []
    
    static let shared = SwapCart()
    
    private init() {}
    
    func addItem(_ item: Item) {
        if !items.contains(where: { $0.id == item.id }) {
            items.append(item)
        }
    }
    
    func removeItem(_ item: Item) {
        items.removeAll() { $0.id == item.id }
    }
    
    func clearCart() {
        items.removeAll()
    }
}
