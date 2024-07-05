//
//  CategoryManager.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/5/24.
//

import Foundation


struct Category: Identifiable, Hashable, Equatable {
    var id: String { name }
    let name: String
}


class CategoryManager: ObservableObject {
    static let shared = CategoryManager()
    @Published var categories: [Category] =
    [
        Category(name: "All"),
        Category(name: "Electronics"),
        Category(name: "Furniture"),
        Category(name: "Clothing"),
        Category(name: "Books"),
        Category(name: "Toys"),
        Category(name: "Sports"),
        Category(name: "Home & Garden"),
        Category(name: "Vintage & Antique"),
        Category(name: "Automotive"),
        Category(name: "Equipment"),
        Category(name: "Medical Equipment"),
        Category(name: "Arts & Craft"),
        Category(name: "Event"),
        Category(name: "Other")
    ]
    private init() {}
}
