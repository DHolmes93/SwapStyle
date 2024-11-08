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
    @State private var searchText = ""
    @State private var selectedCategory: Category = CategoryManager.shared.categories.first!
    @State private var selectedSubcategory: Category? // Changed type to Category for subcategories
    @State private var selectedRadius: Double = 5.0
    @StateObject private var viewModel = UserAccountModel(authManager: AuthManager())
    @EnvironmentObject private var itemManager: ItemManager
    @EnvironmentObject private var swapCart: SwapCart

    let locationManager = CLLocationManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                searchField
                categoryPicker
                if !selectedCategory.subcategories.isEmpty {
                    subcategoryPicker
                }
                radiusPicker
                itemList
            }
            .navigationTitle("Search Items")
            .onAppear {
                fetchAllItems() // Fetch all items initially
            }
        }
    }

    // MARK: - Search Field
    private var searchField: some View {
        TextField("Search...", text: $searchText)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
            .padding(.horizontal)
            .keyboardType(.default)
            .submitLabel(.search)
            .onSubmit {
                performSearch()
            }
    }

    // MARK: - Category Picker
    private var categoryPicker: some View {
        Picker("Category", selection: $selectedCategory) {
            ForEach(CategoryManager.shared.categories) { category in
                Text(category.name).tag(category)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding(.horizontal)
        .onChange(of: selectedCategory) { _ in
            selectedSubcategory = nil // Reset subcategory when category changes
            performSearch()
        }
    }

    // MARK: - Subcategory Picker
    private var subcategoryPicker: some View {
        Picker("Subcategory", selection: $selectedSubcategory) {
            ForEach(selectedCategory.subcategories, id: \.self) { subcategory in
                Text(subcategory.name).tag(subcategory as Category?) // Ensure we are using the right type
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding(.horizontal)
        .onChange(of: selectedSubcategory) { _ in
            performSearch()
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
            fetchAllItems() // Fetch items again based on the new radius
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
                let (location, city, state, zipcode, country) = try await LocationManager.shared.getCurrentLocation()
                // Now you have all the location details
                // You can process them as needed
                print("User location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                print("City: \(city), State: \(state), Zip: \(zipcode), Country: \(country)")
            } catch {
                print("User location not available: \(error.localizedDescription)")
            }
        }
    }
    private func fetchAllItems() {
        Task {
            do {
                let fetchedItems = try await itemManager.fetchItemsByKm(within: selectedRadius)
                DispatchQueue.main.async {
                    self.items = searchText.isEmpty
                        ? fetchedItems
                        : fetchedItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                    print("Fetched \(self.items.count) items within radius \(selectedRadius) km")
                }
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

struct SearchCriteria {
    var category: String?
    var minPrice: Double?
    var condition: String?
    var sellerId: String?
}

