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
    var subcategories: [Category] = []
}

class CategoryManager: ObservableObject {
    static let shared = CategoryManager()
    
    @Published var categories: [Category] = [
        Category(name: "All"),
        Category(name: "Electronics", subcategories: [
            Category(name: "Phones"),
            Category(name: "Laptops"),
            Category(name: "Cameras"),
            Category(name: "Game Systems")
        ]),
        Category(name: "Furniture", subcategories: [
            Category(name: "Living Room"),
            Category(name: "Bedroom"),
            Category(name: "Office"),
            Category(name: "Outdoor")
        ]),
        Category(name: "Clothing", subcategories: [
            Category(name: "Men"),
            Category(name: "Women"),
            Category(name: "Kids"),
            Category(name: "Accessories"),
            Category(name: "Shoes")
        ]),
        Category(name: "Books", subcategories: [
            Category(name: "Fiction"),
            Category(name: "Non-Fiction"),
            Category(name: "Comics"),
            Category(name: "Educational")
        ]),
        Category(name: "Toys", subcategories: [
            Category(name: "Action Figures"),
            Category(name: "Puzzles"),
            Category(name: "Educational Toys"),
            Category(name: "Dolls")
        ]),
        Category(name: "Sports", subcategories: [
            Category(name: "Outdoor Sports"),
            Category(name: "Indoor Sports"),
            Category(name: "Fitness Equipment"),
            Category(name: "Sportswear")
        ]),
        Category(name: "Home & Garden", subcategories: [
            Category(name: "Decor"),
            Category(name: "Tools"),
            Category(name: "Plants"),
            Category(name: "Furniture")
        ]),
        Category(name: "Vintage & Antique", subcategories: [
            Category(name: "Furniture"),
            Category(name: "Jewelry"),
            Category(name: "Decor"),
            Category(name: "Collectibles")
        ]),
        Category(name: "Automotive", subcategories: [
            Category(name: "Cars"),
            Category(name: "Motorcycles"),
            Category(name: "Parts & Accessories"),
            Category(name: "Tools & Equipment")
        ]),
        Category(name: "Equipment", subcategories: [
            Category(name: "Construction"),
            Category(name: "Agricultural"),
            Category(name: "Manufacturing"),
            Category(name: "Medical")
        ]),
        Category(name: "Medical Equipment", subcategories: [
            Category(name: "Surgical"),
            Category(name: "Diagnostic"),
            Category(name: "Therapeutic"),
            Category(name: "Mobility Aids")
        ]),
        Category(name: "Arts & Craft", subcategories: [
            Category(name: "Painting"),
            Category(name: "Sculpting"),
            Category(name: "Knitting"),
            Category(name: "Woodworking")
        ]),
        Category(name: "Event", subcategories: [
            Category(name: "Concerts"),
            Category(name: "Weddings"),
            Category(name: "Conferences"),
            Category(name: "Festivals")
        ]),
        Category(name: "Other")
    ]
    
    private init() {}
}
extension CategoryManager {
    func addCategory(name: String) {
        let newCategory = Category(name: name)
        categories.append(newCategory)
    }

    func addSubcategory(to parentName: String, subcategoryName: String) {
        if let index = categories.firstIndex(where: { $0.name == parentName }) {
            let newSubcategory = Category(name: subcategoryName)
            categories[index].subcategories.append(newSubcategory)
        }
    }

    func removeCategory(at index: Int) {
        categories.remove(at: index)
    }

    func removeSubcategory(from parentName: String, at index: Int) {
        if let parentIndex = categories.firstIndex(where: { $0.name == parentName }) {
            categories[parentIndex].subcategories.remove(at: index)
        }
    }
}
