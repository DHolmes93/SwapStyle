//
//  SearchScreenView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

struct SearchScreenView: View {
    @State private var items: [Item] = []
    @State private var searchCriteria = SearchCriteria()
    @State private var searchText = ""
    @State private var selectedCategory: Category = CategoryManager.shared.categories.first!
    @State private var selectedRadius: Double = 5.0
    @ObservedObject private var categoryManager = CategoryManager.shared
    @EnvironmentObject private var swapCart: SwapCart
    @State private var selectedItem: Item? = nil
    
    let locationManager = CLLocationManager()
    
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
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 10))
                
                //CategoryPicker
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
                Picker("Radius", selection: $selectedRadius) {
                    Text("5 km").tag(5.0)
                    Text("15 km").tag(15.0)
                    Text("25km").tag(25.0)
                    Text("50 km").tag(50.0)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                            ScrollView {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                                    ForEach(items) { item in
                                        NavigationLink(destination: ItemView(item: item)) {
                                            VStack {
                                                ItemCategoryView(item: item)
                                                VStack(alignment: .leading) {
                                                    Text(item.name)
                                                        .font(.headline)
                                                        .foregroundStyle(Color("mainColor"))
                                                        .shadow(radius: 1)
                                                    Text("$\(item.originalprice, specifier: "%.2f")")
                                                        .font(.subheadline)
                                                        .foregroundStyle(Color.black)
                                                        .shadow(radius: 1)
                                                    Text("$\(item.value, specifier: "%.2f")")
                                                        .font(.subheadline)
                                                }
    
                                                        .padding(.top, 5)
                                                        .padding(.horizontal, 5)
                                                }
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(8)
                                            .shadow(radius: 2)
                                }
                            }
                        }
                        .padding(.horizontal)
                }
                
                .onAppear {
                    performSearch()
                }
            }
            .navigationTitle("Search")
        }
    }
    private func performSearch() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user logged in")
            return
        }
        guard let userLocation = locationManager.location else {
            print("User location not available")
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
            let allItems = documents.compactMap { document -> Item? in
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
            let filteredItems = allItems.filter { item in
                guard let itemLocation = item.location else { return false }
                let distance = itemLocation.distance(from: userLocation) / 1000
                return distance <= selectedRadius
            }
            DispatchQueue.main.async {
                self.items = filteredItems
            }
        }
    }
    private var groupedItemsByCategory: [String: [Item]] {
        Dictionary(grouping: items, by: { $0.category})
    }
}

#Preview {
        let mockItems: [Item] = [
            Item(name: "Item 2", details: "Details of Item 3", originalprice: 30.0, value: 25.0, imageUrls: ["https://via.placeholder.com/150"], condition: "Like New", timestamp: Date(), uid: "034566", category: "Clothing", userName: "Joe", latitude: 37.7749, longitude: -122.4194),
            Item(name: "Item 1", details: "Details of Item 3", originalprice: 30.0, value: 25.0, imageUrls: ["https://via.placeholder.com/150"], condition: "Like New", timestamp: Date(), uid: "034566", category: "Clothing", userName: "Joe", latitude: 37.7749, longitude: -122.4194),
            Item(name: "Item 3", details: "Details of Item 3", originalprice: 30.0, value: 25.0, imageUrls: ["https://via.placeholder.com/150"], condition: "Like New", timestamp: Date(), uid: "034566", category: "Clothing", userName: "Joe", latitude: 37.7749, longitude: -122.4194),
        ]
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
