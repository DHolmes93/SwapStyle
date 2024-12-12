//
//  CategoryItemView.swift
//  Just Swap
//
//  Created by Donovan Holmes on 11/23/24.
//

import SwiftUI
//
struct CategoryItemsView: View {
    let category: Category
    @EnvironmentObject var userAccountModel: UserAccountModel
    @EnvironmentObject var itemManager: ItemManager
    @EnvironmentObject var categoryManager: CategoryManager
    
    @State private var items: [Item] = []
    @State private var isLoading = true
    @State private var selectedSubcategory: Category? = nil
    @State private var searchRadius: Double = 50.0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            categoryTitle
            filtersView
            contentView
        }
        .onAppear {
            Task {
                await fetchItems()
            }
        }
        .onChange(of: selectedSubcategory) { _ in
            Task {
                await fetchItems()
            }
        }
        .onChange(of: searchRadius) { _ in
            Task {
                await fetchItems()
            }
        }
    }

    // MARK: - Subviews

    private var categoryTitle: some View {
        Text(category.name)
            .font(.largeTitle)
            .bold()
            .padding(.horizontal, 10)
    }

    private var filtersView: some View {
        FiltersView(
            selectedSubcategory: $selectedSubcategory,
            searchRadius: $searchRadius,
            subcategories: categoryManager.categories.first(where: { $0.name == category.name })?.subcategories ?? []
        )
    }

    private var contentView: some View {
        Group {
            if isLoading {
                ProgressView("Loading items...")
                    .padding(.horizontal, 10)
                    .frame(maxHeight: .infinity, alignment: .top)
            } else if items.isEmpty {
                Text("No items in this category at the moment.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .frame(maxHeight: .infinity, alignment: .top)
            } else {
                itemsGridView
            }
        }
    }

    private var itemsGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                ForEach(items) { item in
                    NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
                        GridItemCard(item: item)
                    }
                }
            }
            .padding(.horizontal, 10)
        }
    }

    // MARK: - Data Fetching

    private func fetchItems() async {
        do {
            isLoading = true
            let subcategoryName = selectedSubcategory?.name
            let fetchedItems = try await itemManager.fetchItemsByCategoryAndSubcategoryAndDistance(
                category: category.name,
                subcategory: subcategoryName,
                radius: searchRadius
            )
            await MainActor.run {
                items = fetchedItems
                isLoading = false
            }
        } catch {
            print("Error fetching items: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
struct GridItemCard: View {
    let item: Item

    var body: some View {
        VStack {
            itemImage
            itemOverlay
        }
        .frame(width: 120, height: 120)
        .cornerRadius(10)
        .shadow(radius: 4)
    }

    private var itemImage: some View {
        AsyncImage(url: URL(string: item.imageUrls.first ?? "")) { image in
            image.resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.gray
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemOverlay: some View {
        if !item.name.isEmpty {
            return AnyView(
                Text(item.name)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding(4)
            )
        } else {
            return AnyView(EmptyView())
        }
    }
}

struct FiltersView: View {
    @Binding var selectedSubcategory: Category?
    @Binding var searchRadius: Double
    let subcategories: [Category]

    var body: some View {
        VStack {
            if !subcategories.isEmpty {
                Picker("Subcategory", selection: $selectedSubcategory) {
                    Text("All").tag(Category?.none)
                    ForEach(subcategories, id: \.self) { subcategory in
                        Text(subcategory.name).tag(Category?.some(subcategory))
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 10)
            }

            HStack {
                Text("Search Radius: \(Int(searchRadius)) miles")
                    .font(.subheadline)
                Slider(value: $searchRadius, in: 1...100, step: 1)
                    .accentColor(.blue)
            }
            .padding(.horizontal, 10)
        }
        .padding(.vertical, 10)
    }
}
