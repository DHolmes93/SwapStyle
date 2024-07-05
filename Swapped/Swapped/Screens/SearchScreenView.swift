//
//  SearchScreenView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SearchScreenView: View {
    @State private var items: [Item] = []
    @State private var searchCriteria = SearchCriteria()
    @State private var searchText = ""
    @State private var selectedCategory: Category = CategoryManager.shared.categories.first!
    @ObservedObject private var categoryManager = CategoryManager.shared
    @EnvironmentObject private var swapCart: SwapCart
    @State private var selectedItem: Item? = nil
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search....", text: Binding(
                    get: { searchText },
                    set: { newValue in
                        searchText = newValue
                        performSearch()
                        
                        
                    }
                ), prompt: Text("Search....").foregroundColor(.black))
                .padding()
                
                //Category Picker
                Picker("Category", selection: Binding(
                    get: { selectedCategory },
                    set: { newValue in
                        selectedCategory = newValue
                        performSearch() }
                )) {
                    ForEach(categoryManager.categories)
                    { category in
                        Text(category.name)
                            .tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
                
                List(items) { item in
                    NavigationLink(destination: ItemView(item: item)) {
                        ItemCategoryView(item: item)
                            .onTapGesture {
                                selectedItem = item
                            }
                    }
                }
                //            .sheet(item: $selectedItem) { item in
                //                ItemView(item: item)
                //                    .environmentObject(swapCart)
                //            }
            }
            
            .onAppear {
                performSearch()
            }
        }
    }
    private func performSearch() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }
        let db = Firestore.firestore()
        var query: Query = db.collection("users").document(userId).collection("items")
        
        // Filters based on search criteria
        
        if selectedCategory.name != "All" {
            query = query.whereField("category", isEqualTo: selectedCategory.name)
        }
        if !searchText.isEmpty {
            query = query.whereField("name", isEqualTo: searchText)
        }
        query.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching items: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else {
                print("No documents found")
                return
            }
            let items = documents.compactMap { document -> Item? in
                let result = Result {
                    try document.data(as: Item.self)
                }
                switch result {
                case.success(let item):
                    return item
                case.failure(let error):
                    print("Error decoding item: \(error)")
                    return nil
                }
            }
            DispatchQueue.main.async {
                self.items = items
            }
        }
    }
}

#Preview {
    let cart = SwapCart.shared
    return SearchScreenView()
        .environmentObject(cart)
}

struct SearchCriteria {
    var category: String?
    var minPrice: Double?
    var conditon: String?
    var sellerId: String?
}
