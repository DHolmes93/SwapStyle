//
//  CategoryItemView.swift
//  Just Swap
//
//  Created by Donovan Holmes on 11/23/24.
//
//import SwiftUI
//
//
//struct CategoryItemsView: View {
//    let category: Category
//    let items: [Item]
//    @EnvironmentObject var userAccountModel: UserAccountModel
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            Text(category.name)
//                .font(.largeTitle)
//                .bold()
//                .padding(.horizontal, 10)
//            
//            if items.isEmpty {
//                Text("No items in this category at the moment.")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .padding(.horizontal, 10)
//            } else {
//                ScrollView {
//                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
//                        ForEach(items) { item in
//                            NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
//                                GridItemCard(item: item)
//                            }
//                        }
//                    }
//                    .padding(.horizontal, 10)
//                }
//            }
//        }
//        .navigationTitle(category.name)
//    }
//}
import SwiftUI

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
            // Title
            Text(category.name)
                .font(.largeTitle)
                .bold()
                .padding(.horizontal, 10)
            
            // Filters under the title
            VStack {
                // Subcategory Picker
                if let subcategories = categoryManager.categories.first(where: { $0.name == category.name })?.subcategories, !subcategories.isEmpty {
                    Picker("Subcategory", selection: $selectedSubcategory) {
                        Text("All").tag(Category?.none)
                        ForEach(subcategories, id: \.self) { subcategory in
                            Text(subcategory.name).tag(Category?.some(subcategory))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 10)
                }
                
                // Distance Slider
                HStack {
                    Text("Search Radius: \(Int(searchRadius)) miles")
                        .font(.subheadline)
                    Slider(value: $searchRadius, in: 1...100, step: 1)
                        .accentColor(.blue)
                }
                .padding(.horizontal, 10)
            }
            .padding(.vertical, 10)
            
            // Content or Loading or No Items message
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
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(items) { item in
                            NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
                                gridItemCard(for: item)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
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

    private func gridItemCard(for item: Item) -> some View {
        imagesGridView(for: item, overlayName: item.name)
            .frame(width: 120, height: 120)
            .cornerRadius(10)
            .shadow(radius: 4)
    }

    private func imagesGridView(for item: Item, overlayName: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: item.imageUrls.first ?? "")) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if !overlayName.isEmpty {
                Text(overlayName)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding(4)
            }
        }
    }
}

//import SwiftUI
//
//struct CategoryItemsView: View {
//    let category: Category
//    let items: [Item]
//    @EnvironmentObject var userAccountModel: UserAccountModel
//    @EnvironmentObject var itemManager: ItemManager
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            Text(category.name)
//                .font(.largeTitle)
//                .bold()
//                .padding(.horizontal, 10)
//            
//            if items.isEmpty {
//                Text("No items in this category at the moment.")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .padding(.horizontal, 10)
//            } else {
//                ScrollView {
//                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
//                        ForEach(items) { item in
//                            NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
//                                gridItemCard(for: item)
//                            }
//                        }
//                    }
//                    .padding(.horizontal, 10)
//                }
//            }
//        }
//        .navigationTitle(category.name)
//    }
//    
//    private func gridItemCard(for item: Item) -> some View {
//        imagesGridView(for: item, overlayName: item.name)
//            .frame(width: 120, height: 120)
//            .cornerRadius(10)
//            .shadow(radius: 4)
//    }
//
//    private func imagesGridView(for item: Item, overlayName: String) -> some View {
//        ZStack(alignment: .bottomLeading) {
//            AsyncImage(url: URL(string: item.imageUrls.first ?? "")) { image in
//                image.resizable()
//                    .aspectRatio(contentMode: .fill)
//            } placeholder: {
//                Color.gray
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            
//            if !overlayName.isEmpty {
//                Text(overlayName)
//                    .font(.caption)
//                    .foregroundColor(.white)
//                    .padding(6)
//                    .background(Color.black.opacity(0.7))
//                    .cornerRadius(8)
//                    .padding(4)
//            }
//        }
//    }
//}

