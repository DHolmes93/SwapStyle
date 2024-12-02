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
    @Environment(\.colorScheme) var colorScheme
    @State private var items: [Item] = []
    @State private var searchText = ""
    @State private var selectedCategory: Category = CategoryManager.shared.categories.first!
    @State private var selectedSubcategory: Category? = nil // Start with nil, representing "All"
    @State private var selectedRadius: Double = 5.0
    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())
    @EnvironmentObject private var itemManager: ItemManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject private var swapCart: SwapCart

    let locationManager = CLLocationManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                searchField
                
                Text("Category: \(selectedCategory.name)") // Show the selected category
                    .font(.subheadline)
                    .padding(.horizontal)

                if !selectedCategory.subcategories.isEmpty {
                    subcategoryPicker
                }

                radiusPicker
                
                itemList
            }
            .navigationTitle("Search Items")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    categoryMenuPicker // Place menu bar in top-left navigation bar
                }
            }
            .onAppear {
                fetchAllItems() // Initially fetch items by category
            }
        }
    }

    // MARK: - Category Menu Picker
    private var categoryMenuPicker: some View {
        Menu {
            ForEach(CategoryManager.shared.categories) { category in
                Button(category.name) {
                    selectedCategory = category
                    selectedSubcategory = nil // Reset subcategory to "All"
                    performSearch() // Fetch items when category is selected
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title3)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Search Field with Suggestions
    private var searchField: some View {
        VStack {
            TextField("Search...", text: $searchText)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                .padding(.horizontal)
                .keyboardType(.default)
                .submitLabel(.search)
                .onSubmit {
                    performSearch() // Fetch items when user submits search
                }

            if !searchText.isEmpty {
                suggestionList
            }
        }
    }

    // MARK: - Suggestion List based on Search Text
    private var suggestionList: some View {
        VStack {
            ForEach(filteredSuggestions, id: \.self) { suggestion in
                Button(action: {
                    searchText = suggestion
                    performSearch() // Perform search when suggestion is selected
                }) {
                    Text(suggestion)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 4)
    }

    // MARK: - Filtered Suggestions based on Search Text
    private var filteredSuggestions: [String] {
        let allSuggestions = items.map { $0.name } // Can be extended to other fields
        return allSuggestions.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Subcategory Picker
    private var subcategoryPicker: some View {
        Picker("Subcategory", selection: $selectedSubcategory) {
            Text("All").tag(nil as Category?) // Add "All" option
            ForEach(selectedCategory.subcategories, id: \.self) { subcategory in
                Text(subcategory.name).tag(subcategory as Category?)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding(.horizontal)
        .onChange(of: selectedSubcategory) { _ in
            performSearch() // Fetch items when subcategory is selected
        }
    }

    // MARK: - Radius Picker
    private var radiusPicker: some View {
        Picker("Radius", selection: $selectedRadius) {
            ForEach([5.0, 15.0, 25.0, 50.0], id: \.self) { radius in
                Text("\(Int(radius)) km").tag(radius)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .onChange(of: selectedRadius) { _ in
            fetchAllItems() // Fetch items based on radius change
        }
    }

    // MARK: - Item List
    private var itemList: some View {
        ScrollView {
            if items.isEmpty {
                Text("No items found")
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(items) { item in
                        NavigationLink(destination: ItemView(item: item, userAccountModel: viewModel)) {
                            ItemCardView(item: item)
                                .frame(width: 100, height: 130)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Fetch Functions
    private func performSearch() {
        Task {
            do {
                // Fetch items by category and optionally by subcategory
                let fetchedItems = try await itemManager.fetchItemsByCategoryAndSubCategory(
                    category: selectedCategory.name,
                    subcategory: selectedSubcategory?.name // If subcategory is "All", this will be nil
                )
                
                // Filter by search text
                self.items = searchText.isEmpty
                    ? fetchedItems
                    : fetchedItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

                print("Fetched \(self.items.count) items for category \(selectedCategory.name) and subcategory \(selectedSubcategory?.name ?? "None")")
            } catch {
                print("Error fetching items: \(error.localizedDescription)")
            }
        }
    }

    private func fetchAllItems() {
        Task {
            do {
                // Fetch all items within the selected radius
                let fetchedItems = try await itemManager.fetchItemsByCategoryAndSubcategoryAndDistance(category: selectedCategory.name, subcategory: selectedSubcategory?.name, radius: selectedRadius)
                
                // Filter the items by search text
                self.items = searchText.isEmpty
                    ? fetchedItems
                    : fetchedItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                print("Fetched \(self.items.count) items within radius \(selectedRadius) km")
            } catch {
                print("Error fetching items: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Item Card View
struct ItemCardView: View {
    let item: Item

    var body: some View {
        VStack {
            ItemCategoryView(item: item)
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipped()
        }
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

//
//struct SearchScreenView: View {
//    @Environment(\.colorScheme) var colorScheme
//    @State private var items: [Item] = []
//    @State private var searchText = ""
//    @State private var selectedCategory: Category = CategoryManager.shared.categories.first!
//    @State private var selectedSubcategory: Category?
//    @State private var selectedRadius: Double = 5.0
//    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())
//    @EnvironmentObject private var itemManager: ItemManager
//    @EnvironmentObject var themeManager: ThemeManager
//    @EnvironmentObject private var swapCart: SwapCart
//
//    let locationManager = CLLocationManager()
//
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 16) {
//                searchField
//                
//                if !selectedCategory.subcategories.isEmpty {
//                    subcategoryPicker
//                }
//
//                radiusPicker
//                
//                itemList
//            }
//            .navigationTitle("Search Items")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    categoryMenuPicker // Place menu bar in top-left navigation bar
//                }
//            }
//            .onAppear {
//                fetchAllItems() // Initially fetch items by category
//            }
//        }
//    }
//
//    // MARK: - Category Menu Picker
//    private var categoryMenuPicker: some View {
//        Menu {
//            ForEach(CategoryManager.shared.categories) { category in
//                Button(category.name) {
//                    selectedCategory = category
//                    selectedSubcategory = nil // Reset subcategory
//                    performSearch() // Fetch items when category is selected
//                }
//            }
//        } label: {
//            Image(systemName: "line.3.horizontal")
//                .font(.title3)
//                .foregroundColor(.primary)
//        }
//    }
//
//    // MARK: - Search Field
//    private var searchField: some View {
//        TextField("Search...", text: $searchText)
//            .padding()
//            .background(Color.white)
//            .cornerRadius(8)
//            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
//            .padding(.horizontal)
//            .keyboardType(.default)
//            .submitLabel(.search)
//            .onSubmit {
//                performSearch() // Fetch items when user submits search
//            }
//    }
//
//    // MARK: - Subcategory Picker
//    private var subcategoryPicker: some View {
//        Picker("Subcategory", selection: $selectedSubcategory) {
//            ForEach(selectedCategory.subcategories, id: \.self) { subcategory in
//                Text(subcategory.name).tag(subcategory as Category?)
//            }
//        }
//        .pickerStyle(MenuPickerStyle())
//        .padding(.horizontal)
//        .onChange(of: selectedSubcategory) { _ in
//            performSearch() // Fetch items when subcategory is selected
//        }
//    }
//
//    // MARK: - Radius Picker
//    private var radiusPicker: some View {
//        Picker("Radius", selection: $selectedRadius) {
//            ForEach([5.0, 15.0, 25.0, 50.0], id: \.self) { radius in
//                Text("\(Int(radius)) km").tag(radius)
//            }
//        }
//        .pickerStyle(SegmentedPickerStyle())
//        .padding(.horizontal)
//        .onChange(of: selectedRadius) { _ in
//            fetchAllItems() // Fetch items based on radius change
//        }
//    }
//
//    // MARK: - Item List
//    private var itemList: some View {
//        ScrollView {
//            if items.isEmpty {
//                Text("No items found")
//                    .padding()
//            } else {
//                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
//                    ForEach(items) { item in
//                        NavigationLink(destination: ItemView(item: item, userAccountModel: viewModel)) {
//                            ItemCardView(item: item)
//                                .frame(width: 100, height: 130)
//                        }
//                    }
//                }
//                .padding(.horizontal)
//            }
//        }
//    }
//
//    // MARK: - Fetch Functions
//    private func performSearch() {
//        Task {
//            do {
//                // Fetch items by category and optionally by subcategory
//                let fetchedItems = try await itemManager.fetchItemsByCategoryAndSubCategory(
//                    category: selectedCategory.name,
//                    subcategory: selectedSubcategory?.name
//                )
//                
//                // Filter by search text
//                self.items = searchText.isEmpty
//                    ? fetchedItems
//                    : fetchedItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
//
//                print("Fetched \(self.items.count) items for category \(selectedCategory.name) and subcategory \(selectedSubcategory?.name ?? "None")")
//            } catch {
//                print("Error fetching items: \(error.localizedDescription)")
//            }
//        }
//    }
//
//
//    
//    private func fetchAllItems() {
//        Task {
//            do {
//                // Fetch all items within the selected radius
//                let fetchedItems = try await itemManager.fetchItemsByKm(within: selectedRadius)
//                
//                // Filter the items by search text
//                self.items = searchText.isEmpty
//                    ? fetchedItems
//                    : fetchedItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
//                print("Fetched \(self.items.count) items within radius \(selectedRadius) km")
//            } catch {
//                print("Error fetching items: \(error.localizedDescription)")
//            }
//        }
//    }
//}
//
//// MARK: - Item Card View
//struct ItemCardView: View {
//    let item: Item
//
//    var body: some View {
//        VStack {
//            ItemCategoryView(item: item)
//                .scaledToFit()
//                .frame(width: 100, height: 100)
//                .clipped()
//        }
//        .cornerRadius(8)
//        .shadow(radius: 4)
//    }
//}
//
//struct SearchCriteria {
//    var category: String?
//    var minPrice: Double?
//    var condition: String?
//    var sellerId: String?
//}

