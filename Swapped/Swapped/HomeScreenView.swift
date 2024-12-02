//
//  HomeScreenView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
import SwiftUI
import CoreLocation

struct HomeScreenView: View {
    @StateObject private var itemManager = ItemManager.shared
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var items: [Item] = []
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var currentPage: Int = 1
    @ObservedObject var userAccountModel: UserAccountModel
    @EnvironmentObject var themeManager: ThemeManager

    init(userAccountModel: UserAccountModel, items: [Item] = []) {
        self._userAccountModel = ObservedObject(wrappedValue: userAccountModel)
        let itemManager = ItemManager.shared
        if !items.isEmpty {
            itemManager.items = items
        }
        _itemManager = StateObject(wrappedValue: itemManager)
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if currentPage == 1 {
                        topItemsView
                    }
                    otherPopularItemsView(forPage: currentPage)
                }
                .padding(.horizontal)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Just Swap")
                            .font(.headline)
                            .foregroundStyle(Color("thirdColor"))
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        messageButton
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        menuPicker
                    }
                }
            }
            .overlay(pageCounterView, alignment: .bottom)
            .onAppear {
                if !isPreview {
                    fetchItems()
                    fetchUserLocation()
                }
            }
        }
    }
    // MARK: - Page Counter View
    private var pageCounterView: some View {
        let totalPages = calculateTotalPages()

        return HStack {
            Button(action: {
                if currentPage > 1 {
                    currentPage -= 1
                }
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(currentPage > 1 ? .blue : .gray)
            }
            .disabled(currentPage <= 1)
            
            Spacer()
            
            Text("Page \(currentPage) of \(totalPages)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            Button(action: {
                if currentPage < totalPages {
                    currentPage += 1
                }
            }) {
                Image(systemName: "arrow.right")
                    .foregroundColor(currentPage < totalPages ? .blue : .gray)
            }
            .disabled(currentPage >= totalPages)
        }
        .padding()
    }


    // MARK: - Top Items View
    private var topItemsView: some View {
        let hottestItems = Array(
            itemManager.items.sorted {
                ($0.clickCount + $0.addToCartCount) > ($1.clickCount + $1.addToCartCount)
            }.prefix(3)
        )

        if !hottestItems.isEmpty {
            return AnyView(
                VStack(alignment: .leading, spacing: 16) {
                    Text("🔥 Hottest Items")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(hottestItems) { item in
                                NavigationLink(destination: ItemView(item: item, userAccountModel: UserAccountModel.shared)) {
                                    VStack {
                                        Image(item.imageUrls.first ?? "placeholder") // Use your item image logic
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 150, height: 200)
                                            .cornerRadius(12)
                                            .overlay(
                                                Text("Popular")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .padding(5)
                                                    .background(Color.red.opacity(0.8))
                                                    .cornerRadius(8)
                                                    .padding([.top, .trailing], 8),
                                                alignment: .topTrailing
                                            )

                                        Text(item.name)
                                            .font(.headline)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    // MARK: - Other Popular Items View
    private func otherPopularItemsView(forPage page: Int) -> some View {
        let itemsPerPage = 6
        let otherItems = Array(
            itemManager.items
                .sorted { $0.clickCount + $0.addToCartCount > $1.clickCount + $1.addToCartCount }
                .dropFirst(3) // Remove the top 3 items already displayed
        )

        // Ensure there are items to paginate
        guard !otherItems.isEmpty else {
            return AnyView(Text("No popular items available yet.").foregroundColor(.gray))
        }

        // Calculate indices
        let startIndex = max(0, (page - 1) * itemsPerPage)
        let endIndex = min(startIndex + itemsPerPage, otherItems.count)

        // Explicitly validate range
        guard startIndex < endIndex else {
            return AnyView(EmptyView()) // No valid range for slicing
        }

        // Safe slicing
        let paginatedItems = Array(otherItems[startIndex..<endIndex])

        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
                Text("Other Popular Items")
                    .font(.title3)
                    .bold()
                    .padding(.horizontal)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(paginatedItems) { item in
                        NavigationLink(destination: ItemView(item: item, userAccountModel: UserAccountModel.shared)) {
                            VStack {
                                Image(item.imageUrls.first ?? "placeholder") // Use your item image logic
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 150)
                                    .cornerRadius(8)

                                Text(item.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        )
    }
    // MARK: - Menu Picker
    private var menuPicker: some View {
        Menu {
            // Account Section
            Section {
                NavigationLink(destination: AccountView()) {
                    Label("Account", systemImage: "person.fill")
                }
            }

            Divider() // Divider between Account and categories

            // Categories Section
            ForEach(CategoryManager.shared.categories) { category in
                NavigationLink(destination: CategoryItemsView(category: category)) {
                    Text(category.name)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .foregroundColor(Color("thirdColor"))
        }
    }
    // MARK: - Message Button
    private var messageButton: some View {
        NavigationLink(destination: NewMessageView()) {
            HStack {
                Image(systemName: "message.fill")
                    .foregroundColor(Color("mainColor"))
                if NotificationManager.shared.unreadMessageCount > 0 {
                    Text("\(NotificationManager.shared.unreadMessageCount)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(5)
                        .background(Circle().fill(Color.white).shadow(radius: 5))
                        .offset(x: 10, y: -10) // Adjust positioning of the number
                }
            }
        }
    }

    // MARK: - Helper Functions
    private func calculateTotalPages() -> Int {
        let itemsPerPage = 6
        let otherItemsCount = itemManager.items.count - 3
        return max(1, Int(ceil(Double(otherItemsCount) / Double(itemsPerPage))) + 1)
    }
    private func fetchItems() {
        Task {
            do {
                let fetchedItems = try await itemManager.fetchItemsByDistance()
                self.items = fetchedItems
            } catch {
                errorMessage = "Failed to load items: \(error.localizedDescription)"
            }
        }
    }
    private func fetchUserLocation() {
        Task {
            do {
                userLocation = try await LocationManager.shared.getCurrentLocation().0
            } catch {
                errorMessage = "Failed to get user location: \(error.localizedDescription)"
            }
        }
    }
}
private var isPreview: Bool {
    #if DEBUG
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    #else
    return false
    #endif
}
// MARK: - Helper Views
struct HomeSectionView: View {
    let title: String
    let category: String
    let subcategory: String?
    let radius: Double?
    @StateObject var itemManager: ItemManager
    @State private var filteredItems: [Item] = []

    
    @State private var items: [Item] = [] // Holds the fetched items
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.leading, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(items) { item in
                        NavigationLink(destination: ItemView(item: item, userAccountModel: UserAccountModel.shared)) {
                            AsyncImage(url: URL(string: item.imageUrls.first ?? "")) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 120, height: 120)
                            .cornerRadius(10)
                            .shadow(radius: 4)
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
        }
        .onAppear {
            Task {
                do {
                    try await fetchItems(for: category, subcategory: subcategory, radius: radius)
                } catch {
                    print("Error fetching items: \(error.localizedDescription)")
                }
            }
        }

    }

    /// Fetch items based on the category and subcategory
    /// Fetch items based on the category, subcategory, and distance
    private func fetchItems(for category: String?, subcategory: String?, radius: Double?) async {
        do {
            let items = try await itemManager.fetchItemsByCategoryAndSubcategoryAndDistance(category: category, subcategory: subcategory, radius: radius)
            
            // Handle the fetched items (e.g., update a state or pass to UI)
            DispatchQueue.main.async {
                self.filteredItems = items // Assuming `filteredItems` is a @State or @Published property
            }
        } catch {
            print("Error fetching items: \(error.localizedDescription)")
        }
    }


}

//struct HomeSectionView: View {
//    let title: String
//    let items: [Item]
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text(title)
//                .font(.headline)
//                .padding(.leading, 10)
//
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 20) {
//                    ForEach(items) { item in
//                        NavigationLink(destination: ItemView(item: item, userAccountModel: UserAccountModel.shared)) {
//                            AsyncImage(url: URL(string: item.imageUrls.first ?? "")) { image in
//                                image.resizable()
//                                    .aspectRatio(contentMode: .fill)
//                            } placeholder: {
//                                Color.gray
//                            }
//                            .frame(width: 120, height: 120)
//                            .cornerRadius(10)
//                            .shadow(radius: 4)
//                        }
//                    }
//                }
//                .padding(.horizontal, 10)
//            }
//        }
//    }
//}


//import SwiftUI
//import CoreLocation
//
//struct HomeScreenView: View {
//    @StateObject private var itemManager = ItemManager.shared
//    @State private var errorMessage: String?
//    @State private var isLoading: Bool = false
//    @State private var items: [Item] = []
//    @State private var userLocation: CLLocationCoordinate2D? = nil
//    @ObservedObject var userAccountModel: UserAccountModel
//    @EnvironmentObject var themeManager: ThemeManager
//
//    init(userAccountModel: UserAccountModel, items: [Item] = []) {
//        self._userAccountModel = ObservedObject(wrappedValue: userAccountModel)
//        let itemManager = ItemManager.shared
//        if !items.isEmpty {
//            itemManager.items = items
//        }
//        _itemManager = StateObject(wrappedValue: itemManager)
//    }
//
//    var body: some View {
//        NavigationStack {
//            content
//                .onAppear {
//                    if !isPreview {
//                        fetchItems()
//                        fetchUserLocation()
//                    }
//                }
//                .environmentObject(itemManager)
//        }
//    }
//
//    private var content: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//                errorMessageView
//                topItemsView
//                otherPopularItemsView
//                categoriesSection
//            }
//            .padding(.horizontal)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Just Swap")
//                        .font(.headline)
//                        .foregroundStyle(Color("thirdColor"))
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    messageButton
//                }
//                ToolbarItem(placement: .navigationBarLeading) {
//                    menuPicker
//                }
//            }
//        }
//    }
//
//    // MARK: - Error Message
//    private var errorMessageView: some View {
//        if let errorMessage = errorMessage {
//            Text(errorMessage)
//                .foregroundColor(.red)
//                .padding() as! EmptyView
//        } else {
//            EmptyView()
//        }
//    }
//
//    // MARK: - Top Items View
//    private var topItemsView: some View {
//        let hottestItems = itemManager.items.sorted {
//            ($0.clickCount + $0.addToCartCount) > ($1.clickCount + $1.addToCartCount)
//        }.prefix(3)
//
//        return Group {
//            if !hottestItems.isEmpty {
//                HomeSectionView(title: "Hottest Items", items: Array(hottestItems))
//            } else {
//                EmptyView()
//            }
//        }
//    }
//
//
//
//    // MARK: - Other Popular Items
//    private var otherPopularItemsView: some View {
//        let otherItems = itemManager.items.sorted {
//            $0.clickCount + $0.addToCartCount > $1.clickCount + $1.addToCartCount
//        }.dropFirst(3)
//
//        return Group {
//            if !otherItems.isEmpty {
//                HomeSectionView(title: "Other Popular Items", items: Array(otherItems))
//                    .environmentObject(SwapCart.shared)
//            } else {
//                EmptyView()
//            }
//        }
//    }
//
//
//    // MARK: - Categories Section
//    private var categoriesSection: some View {
//        ForEach(CategoryManager.shared.categories) { category in
//            VStack(alignment: .leading, spacing: 10) {
//                NavigationLink(
//                    destination: CategoryItemsView(
//                        category: category,
//                        items: itemManager.items.filter { $0.selectedCategory == category.name }
//                    )
//                ) {
//                    Text(category.name)
//                        .font(.headline)
//                        .foregroundColor(.blue)
//                        .padding(.leading, 10)
//                }
//
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 15) {
//                        let categoryItems = itemManager.items.filter { $0.selectedCategory == category.name }
//
//                        ForEach(categoryItems) { item in
//                            VStack {
//                                NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
//                                    gridItemCard(for: item)
//                                }
//
//                                // Add-to-Cart Button
//                                Button(action: {
//                                    addToCart(item)
//                                }) {
//                                    Text("Add to Cart")
//                                        .font(.caption)
//                                        .foregroundColor(.white)
//                                        .padding(6)
//                                        .background(Color.blue)
//                                        .cornerRadius(8)
//                                }
//                                .padding(.top, 5)
//                            }
//                        }
//                    }
//                    .padding(.horizontal, 10)
//                }
//            }
//        }
//    }
//
//    private var menuPicker: some View {
//        Menu {
//            ForEach(CategoryManager.shared.categories) { category in
//                NavigationLink(destination: CategoryItemsView(category: category, items: itemManager.items)) {
//                    Text(category.name)
//                }
//            }
//            NavigationLink(destination: AccountView()) {
//                Text("Account")
//            }
//        } label: {
//            Image(systemName: "line.3.horizontal.decrease")
//                .foregroundColor(Color("thirdColor"))
//        }
//    }
//
//    private var messageButton: some View {
//        NavigationLink(destination: Text("Messages")) {
//            Image(systemName: "message.fill")
//                .foregroundColor(Color("mainColor"))
//        }
//    }
//
//    private func gridItemCard(for item: Item) -> some View {
//        AsyncImage(url: URL(string: item.imageUrls.first ?? "")) { image in
//            image.resizable()
//                .aspectRatio(contentMode: .fill)
//        } placeholder: {
//            Color.gray
//        }
//        .frame(width: 120, height: 120)
//        .cornerRadius(10)
//        .shadow(radius: 4)
//    }
//
//    private func fetchItems() {
//        Task {
//            do {
//                let fetchedItems = try await itemManager.fetchItemsByDistance()
//                self.items = fetchedItems
//            } catch {
//                errorMessage = "Failed to load items: \(error.localizedDescription)"
//            }
//        }
//    }
//        private var isPreview: Bool {
//            #if DEBUG
//            return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
//            #else
//            return false
//            #endif
//        }
//
//    private func fetchUserLocation() {
//        Task {
//            do {
//                userLocation = try await LocationManager.shared.getCurrentLocation().0
//            } catch {
//                errorMessage = "Failed to get user location: \(error.localizedDescription)"
//            }
//        }
//    }
//
//    private func addToCart(_ item: Item) {
//        SwapCart.shared.addItem(item)
//    }
//}
//
//struct HomeSectionView: View {
//    let title: String
//    let items: [Item]
//    @EnvironmentObject var swapCart: SwapCart
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text(title)
//                .font(.headline)
//                .padding(.leading, 10)
//
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 20) {
//                    ForEach(items) { item in
//                        VStack {
//                            NavigationLink(destination: ItemView(item: item, userAccountModel: UserAccountModel.shared)) {
//                                AsyncImage(url: URL(string: item.imageUrls.first ?? "")) { image in
//                                    image.resizable()
//                                        .aspectRatio(contentMode: .fill)
//                                } placeholder: {
//                                    Color.gray
//                                }
//                                .frame(width: 120, height: 120)
//                                .cornerRadius(10)
//                                .shadow(radius: 4)
//                            }
//
//                            Button(action: {
//                                if swapCart.items.contains(where: { $0.id == item.id }) {
//                                    swapCart.removeItem(item)
//                                } else {
//                                    swapCart.addItem(item)
//                                }
//                            }) {
//                                Text(swapCart.items.contains(where: { $0.id == item.id }) ? "Remove" : "Add")
//                                    .font(.caption)
//                                    .padding(5)
//                                    .background(Color.blue)
//                                    .foregroundColor(.white)
//                                    .cornerRadius(5)
//                            }
//                        }
//                    }
//                }
//                .padding(.horizontal, 10)
//            }
//        }
//    }
//}



//import SwiftUI
//import CoreLocation
//
//struct HomeScreenView: View {
//    @StateObject private var itemManager = ItemManager.shared
//    @State private var errorMessage: String?
//    @State private var isLoading: Bool = false
//    @State private var items: [Item] = []
//    @State private var userLocation: CLLocationCoordinate2D? = nil
//    @ObservedObject var userAccountModel: UserAccountModel
//    @EnvironmentObject var themeManager: ThemeManager
//
//    init(userAccountModel: UserAccountModel, items: [Item] = []) {
//        self._userAccountModel = ObservedObject(wrappedValue: userAccountModel)
//        let itemManager = ItemManager.shared
//        if !items.isEmpty {
//            itemManager.items = items
//        }
//        _itemManager = StateObject(wrappedValue: itemManager)
//    }
//
//    var body: some View {
//        NavigationStack {
//            content
//                .onAppear {
//                    if !isPreview {
//                        fetchItems()
//                        fetchUserLocation()
//                    }
//                }
//                .environmentObject(itemManager)
//        }
//    }
//
//    // MARK: - Main Content
//    private var content: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//                errorMessageView
//                itemsListView
//            }
//            .padding(.horizontal)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Just Swap")
//                        .font(.headline)
//                        .foregroundStyle(Color("thirdColor"))
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    messageButton
//                }
//                ToolbarItem(placement: .navigationBarLeading) {
//                    accountButton
//                }
//            }
//        }
//    }
//
//    // MARK: - Error Message
//    private var errorMessageView: some View {
//        Group {
//            if let errorMessage = errorMessage {
//                Text(errorMessage)
//                    .foregroundColor(.red)
//                    .padding()
//            } else {
//                EmptyView()
//            }
//        }
//    }
//
//    // MARK: - Items List View
//    // MARK: - Items List View
//    private var itemsListView: some View {
//        let topItems = Array(itemManager.items.sorted { $0.clickCount > $1.clickCount }.prefix(3))
//        
//        return VStack(alignment: .leading, spacing: 20) {
//            // Top "Popular" Items Section
//            if !topItems.isEmpty {
//                topItemsView(topItems)
//            }
//            
//            // Dynamic Categories and Subcategories
//            ForEach(CategoryManager.shared.categories) { category in
//                VStack(alignment: .leading, spacing: 10) {
//                    // Category Title with Navigation
//                    NavigationLink(
//                        destination: CategoryItemsView(
//                            category: category,
//                            items: itemManager.items.filter { $0.selectedCategory == category.name }
//                        )
//                    ) {
//                        Text(category.name)
//                            .font(.headline)
//                            .foregroundColor(.blue)
//                            .padding(.leading, 10)
//                    }
//                    
//                    // Items in Current Category
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 15) {
//                            let categoryItems = itemManager.items.filter { $0.selectedCategory == category.name }
//                            
//                            ForEach(categoryItems) { item in
//                                NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
//                                    gridItemCard(for: item)
//                                }
//                            }
//                        }
//                        .padding(.horizontal, 10)
//                    }
//                }
//            }
//        }
//        .padding(.vertical, 20)
//    }
//
//    private func topItemsView(_ items: [Item]) -> some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 20) {
//                ForEach(items) { item in
//                    NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
//                        topItemCard(for: item)
//                    }
//                }
//            }
//            .padding(.horizontal, 10)
//        }
//    }
//
//    private func topItemCard(for item: Item) -> some View {
//        ZStack(alignment: .topTrailing) {
//            imagesGridView(for: item, overlayName: "")
//                .frame(width: UIScreen.main.bounds.width * 0.8, height: 300)
//                .cornerRadius(12)
//                .shadow(radius: 5)
//
//            HStack(spacing: 4) {
//                Image(systemName: "flame.fill")
//                    .foregroundColor(.red)
//                Text("Popular")
//                    .font(.caption)
//                    .foregroundColor(.white)
//            }
//            .padding(6)
//            .background(Color.black.opacity(0.7))
//            .cornerRadius(8)
//            .padding(10)
//        }
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
//
////    private func imagesGridView(for item: Item, overlayName: String) -> some View {
////        ZStack(alignment: .bottomLeading) {
////            TabView {
////                ForEach(item.imageUrls, id: \.self) { imageUrl in
////                    if let url = URL(string: imageUrl) {
////                        AsyncImage(url: url) { image in
////                            image.resizable()
////                                .aspectRatio(contentMode: .fill)
////                        } placeholder: {
////                            ProgressView()
////                        }
////                    }
////                }
////            }
////            .tabViewStyle(PageTabViewStyle())
////            
////            Text(overlayName)
////                .font(.headline)
////                .foregroundColor(.white)
////                .padding(6)
////                .background(Color.black.opacity(0.7))
////                .cornerRadius(8)
////                .padding([.leading, .bottom], 10)
////        }
////    }
//
//    // MARK: - Toolbar Buttons
//    private var messageButton: some View {
//        NavigationLink(destination: Text("Messages")) {
//            Image(systemName: "message.fill")
//                .foregroundColor(Color("mainColor"))
//        }
//    }
//    
//    private var accountButton: some View {
//        NavigationLink(destination: AccountView()) {
//            Image(systemName: "person.circle")
//                .foregroundColor(Color("thirdColor"))
//        }
//    }
//
//    private var isPreview: Bool {
//        #if DEBUG
//        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
//        #else
//        return false
//        #endif
//    }
//
//    private func fetchItems() {
//        Task {
//            do {
//                let fetchedItems = try await itemManager.fetchItemsByDistance()
//                self.items = fetchedItems
//            } catch {
//                errorMessage = "Failed to load items: \(error.localizedDescription)"
//            }
//        }
//    }
//
//    private func fetchUserLocation() {
//        Task {
//            do {
//                userLocation = try await LocationManager.shared.getCurrentLocation().0
//            } catch {
//                errorMessage = "Failed to get user location: \(error.localizedDescription)"
//            }
//        }
//    }
//}
//import SwiftUI
//import CoreLocation
//
//struct HomeScreenView: View {
//    @StateObject private var itemManager = ItemManager.shared
//    @State private var errorMessage: String?
//    @State private var isLoading: Bool = false
//    @State private var items: [Item] = []
//    @State private var userLocation: CLLocationCoordinate2D? = nil
//    @ObservedObject var userAccountModel: UserAccountModel
//    @EnvironmentObject var themeManager: ThemeManager
//
//    init(userAccountModel: UserAccountModel, items: [Item] = []) {
//        self._userAccountModel = ObservedObject(wrappedValue: userAccountModel)
//        let itemManager = ItemManager.shared
//        if !items.isEmpty {
//            itemManager.items = items
//        }
//        _itemManager = StateObject(wrappedValue: itemManager)
//    }
//
//    var body: some View {
//        NavigationStack {
//            content
//                .onAppear {
//                    if !isPreview {
//                        fetchItems()
//                        fetchUserLocation()
//                    }
//                }
//                .environmentObject(itemManager)
//        }
//    }
//
//    private var content: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//                errorMessageView
//                topItemsView
//                otherPopularItemsView
//                categoriesSection
//            }
//            .padding(.horizontal)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Just Swap")
//                        .font(.headline)
//                        .foregroundStyle(Color("thirdColor"))
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    messageButton
//                }
//                ToolbarItem(placement: .navigationBarLeading) {
//                    menuPicker
//                }
//            }
//        }
//    }
//
//    // MARK: - Error Message
//    private var errorMessageView: some View {
//        if let errorMessage = errorMessage {
//            Text(errorMessage)
//                .foregroundColor(.red)
//                .padding()
//        } else {
//            EmptyView()
//        }
//    }
//
//    // MARK: - Top Items View
//    private var topItemsView: some View {
//        let hottestItems = Array(itemManager.items.sorted {
//            ($0.clickCount + $0.addToCartCount) > ($1.clickCount + $1.addToCartCount)
//        }.prefix(3))
//
//        if !hottestItems.isEmpty {
//            HomeSectionView(title: "Hottest Items", items: hottestItems)
//        } else {
//            EmptyView()
//        }
//    }
//
//    // MARK: - Other Popular Items
//    private var otherPopularItemsView: some View {
//        let otherItems = itemManager.items.sorted {
//            $0.clickCount + $0.addToCartCount > $1.clickCount + $1.addToCartCount
//        }.dropFirst(3)
//
//        if !otherItems.isEmpty {
//            SectionView(title: "Other Popular Items", items: Array(otherItems))
//        } else {
//            EmptyView()
//        }
//    }
//
//    // MARK: - Categories Section
//    private var categoriesSection: some View {
//        ForEach(CategoryManager.shared.categories) { category in
//            VStack(alignment: .leading, spacing: 10) {
//                NavigationLink(
//                    destination: CategoryItemsView(
//                        category: category,
//                        items: itemManager.items.filter { $0.selectedCategory == category.name }
//                    )
//                ) {
//                    Text(category.name)
//                        .font(.headline)
//                        .foregroundColor(.blue)
//                        .padding(.leading, 10)
//                }
//
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 15) {
//                        let categoryItems = itemManager.items.filter { $0.selectedCategory == category.name }
//
//                        ForEach(categoryItems) { item in
//                            NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
//                                gridItemCard(for: item)
//                            }
//                        }
//                    }
//                    .padding(.horizontal, 10)
//                }
//            }
//        }
//    }
//
//    private var menuPicker: some View {
//        Menu {
//            ForEach(CategoryManager.shared.categories) { category in
//                NavigationLink(destination: CategoryItemsView(category: category, items: itemManager.items)) {
//                    Text(category.name)
//                }
//            }
//            NavigationLink(destination: AccountView()) {
//                Text("Account")
//            }
//        } label: {
//            Image(systemName: "line.3.horizontal.decrease")
//                .foregroundColor(Color("thirdColor"))
//        }
//    }
//
//    private var messageButton: some View {
//        NavigationLink(destination: Text("Messages")) {
//            Image(systemName: "message.fill")
//                .foregroundColor(Color("mainColor"))
//        }
//    }
//
//    private func gridItemCard(for item: Item) -> some View {
//        AsyncImage(url: URL(string: item.imageUrls.first ?? "")) { image in
//            image.resizable()
//                .aspectRatio(contentMode: .fill)
//        } placeholder: {
//            Color.gray
//        }
//        .frame(width: 120, height: 120)
//        .cornerRadius(10)
//        .shadow(radius: 4)
//    }
//
//    private func fetchItems() {
//        Task {
//            do {
//                let fetchedItems = try await itemManager.fetchItemsByDistance()
//                self.items = fetchedItems
//            } catch {
//                errorMessage = "Failed to load items: \(error.localizedDescription)"
//            }
//        }
//    }
//
//    private func fetchUserLocation() {
//        Task {
//            do {
//                userLocation = try await LocationManager.shared.getCurrentLocation().0
//            } catch {
//                errorMessage = "Failed to get user location: \(error.localizedDescription)"
//            }
//        }
//    }
//}
//
//// MARK: - Helper Views
//struct HomeSectionView: View {
//    let title: String
//    let items: [Item]
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text(title)
//                .font(.headline)
//                .padding(.leading, 10)
//
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 20) {
//                    ForEach(items) { item in
//                        NavigationLink(destination: ItemView(item: item, userAccountModel: UserAccountModel)) {
//                            AsyncImage(url: URL(string: item.imageUrls.first ?? "")) { image in
//                                image.resizable()
//                                    .aspectRatio(contentMode: .fill)
//                            } placeholder: {
//                                Color.gray
//                            }
//                            .frame(width: 120, height: 120)
//                            .cornerRadius(10)
//                            .shadow(radius: 4)
//                        }
//                    }
//                }
//                .padding(.horizontal, 10)
//            }
//        }
//    }
//}


//import SwiftUI
//import CoreLocation
//
//struct HomeScreenView: View {
//    @StateObject private var itemManager = ItemManager.shared
//    @State private var errorMessage: String?
//    @State private var isLoading: Bool = false
//    @State private var items: [Item] = []
//    @State private var userLocation: CLLocationCoordinate2D? = nil
//    @ObservedObject var userAccountModel: UserAccountModel
//    @EnvironmentObject var themeManager: ThemeManager
//    
//    init(userAccountModel: UserAccountModel, items: [Item] = []) {
//        self._userAccountModel = ObservedObject(wrappedValue: userAccountModel)
//        let itemManager = ItemManager.shared
//        if !items.isEmpty {
//            itemManager.items = items
//        }
//        _itemManager = StateObject(wrappedValue: itemManager)
//    }
//    
//    var body: some View {
//        NavigationStack {
//            content
//                .onAppear {
//                    if !isPreview {
//                        fetchItems()
//                        fetchUserLocation()
//                    }
//                }
//                .environmentObject(itemManager)
//        }
//    }
//    
//    // MARK: - Main Content
//    private var content: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//                errorMessageView
//                itemsListView
//            }
//            .padding(.horizontal)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Just Swap")
//                        .font(.headline)
//                        .foregroundStyle(Color("thirdColor"))
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    messageButton
//                }
//                ToolbarItem(placement: .navigationBarLeading) {
//                    accountButton
//                }
//            }
//        }
//    }
//    
//    // MARK: - Error Message
//    private var errorMessageView: some View {
//        Group {
//            if let errorMessage = errorMessage {
//                Text(errorMessage)
//                    .foregroundColor(.red)
//                    .padding()
//            } else {
//                EmptyView()
//            }
//        }
//    }
//    
//    // MARK: - Items List View
//    private var itemsListView: some View {
//        let topItems = Array(itemManager.items.sorted { $0.clickCount > $1.clickCount }.prefix(3))
//        
//        return VStack(alignment: .leading, spacing: 20) {
//            // Top "Popular" Items Section
//            if !topItems.isEmpty {
//                topItemsView(topItems)
//            }
//            
//            // Dynamic Categories and Subcategories
//            ForEach(CategoryManager.shared.categories) { category in
//                VStack(alignment: .leading, spacing: 10) {
//                    // Category Title with Navigation
//                    NavigationLink(
//                        destination: CategoryItemsView(
//                            category: category,
//                            items: itemManager.items.filter { $0.selectedCategory == category.name }
//                        )
//                    ) {
//                        Text(category.name)
//                            .font(.headline)
//                            .foregroundColor(.blue)
//                            .padding(.leading, 10)
//                    }
//                    
//                    // Items in Current Category
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 15) {
//                            let categoryItems = itemManager.items.filter { $0.selectedCategory == category.name }
//                            
//                            ForEach(categoryItems) { item in
//                                NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
//                                    gridItemCard(for: item)
//                                }
//                            }
//                        }
//                        .padding(.horizontal, 10)
//                    }
//                }
//            }
//        }
//        .padding(.vertical, 20)
//    }
//
//
//    private func topItemsView(_ items: [Item]) -> some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 20) {
//                ForEach(items) { item in
//                    NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
//                        topItemCard(for: item)
//                    }
//                }
//            }
//            .padding(.horizontal, 10)
//        }
//    }
//
//    private func topItemCard(for item: Item) -> some View {
//        ZStack(alignment: .topTrailing) {
//            imagesGridView(for: item, overlayName: "")
//                .frame(width: UIScreen.main.bounds.width * 0.8, height: 300)
//                .cornerRadius(12)
//                .shadow(radius: 5)
//
//            HStack(spacing: 4) {
//                Image(systemName: "flame.fill")
//                    .foregroundColor(.red)
//                Text("Popular")
//                    .font(.caption)
//                    .foregroundColor(.white)
//            }
//            .padding(6)
//            .background(Color.black.opacity(0.7))
//            .cornerRadius(8)
//            .padding(10)
//        }
//    }
//
//    private func gridItemCard(for item: Item) -> some View {
//        imagesGridView(for: item, overlayName: "")
//            .frame(width: 120, height: 120)
//            .cornerRadius(10)
//            .shadow(radius: 4)
//    }
//
//    
//    private func remainingItemsGridView(_ items: [Item]) -> some View {
//        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 15) {
//            ForEach(items) { item in
//                NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
//                    gridItemCard(for: item)
//                }
//            }
//        }
//        .padding(.horizontal, 10)
//    }
//    
////    private func gridItemCard(for item: Item) -> some View {
////        VStack(alignment: .leading, spacing: 8) {
////            imagesGridView(for: item, overlayName: item.name)
////            HStack(alignment: .top, spacing: 8) {
////                priceInfoView(item)
////            }
////            Text(item.details)
////                .font(.caption)
////                .lineLimit(1)
////                .padding(.horizontal)
////        }
////        .background(Color.white)
////        .cornerRadius(10)
////        .shadow(radius: 4)
////    }
//    
//    private func priceInfoView(_ item: Item) -> some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text("Original Price:")
//                .font(.footnote)
//                .foregroundColor(.gray)
//            Text("$\(item.originalprice, specifier: "%.2f")")
//                .strikethrough()
//                .font(.footnote)
//                .foregroundColor(.gray)
//            Text("Value: $\(item.value, specifier: "%.2f")")
//                .font(.subheadline)
//                .fontWeight(.bold)
//        }
//    }
//    
//    private func imagesGridView(for item: Item, overlayName: String) -> some View {
//        ZStack(alignment: .bottomLeading) {
//            TabView {
//                ForEach(item.imageUrls, id: \.self) { imageUrl in
//                    if let url = URL(string: imageUrl) {
//                        AsyncImage(url: url) { image in
//                            image.resizable()
//                                .aspectRatio(contentMode: .fill)
//                        } placeholder: {
//                            ProgressView()
//                        }
//                    }
//                }
//            }
//            .tabViewStyle(PageTabViewStyle())
//            
//            Text(overlayName)
//                .font(.headline)
//                .foregroundColor(.white)
//                .padding(6)
//                .background(Color.black.opacity(0.7))
//                .cornerRadius(8)
//                .padding([.leading, .bottom], 10)
//        }
//    }
//    
//    // MARK: - Toolbar Buttons
//    private var messageButton: some View {
//        NavigationLink(destination: Text("Messages")) {
//            Image(systemName: "message.fill")
//                .foregroundColor(Color("mainColor"))
//        }
//    }
//    
//    private var accountButton: some View {
//        NavigationLink(destination: AccountView()) {
//            Image(systemName: "person.circle")
//                .foregroundColor(Color("thirdColor"))
//        }
//    }
//    
//    // MARK: - Helper Methods
//    private var isPreview: Bool {
//        #if DEBUG
//        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
//        #else
//        return false
//        #endif
//    }
//    
//    private func fetchItems() {
//        Task {
//            do {
//                let fetchedItems = try await itemManager.fetchItemsByDistance()
//                self.items = fetchedItems
//            } catch {
//                errorMessage = "Failed to load items: \(error.localizedDescription)"
//            }
//        }
//    }
//    
//    private func fetchUserLocation() {
//        Task {
//            do {
//                userLocation = try await LocationManager.shared.getCurrentLocation().0
//            } catch {
//                errorMessage = "Failed to get user location: \(error.localizedDescription)"
//            }
//        }
//    }
//}

//import SwiftUI
//import CoreLocation
//
//struct HomeScreenView: View {
////    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
//    
//    @StateObject private var itemManager = ItemManager.shared
//    @StateObject private var swapCart = SwapCart.shared
//    @State private var errorMessage: String?
//    @State private var messageCount: Int = 0
//    @State private var isLoading: Bool = false
//    @State private var items: [Item] = []
//    @State private var userLocation: CLLocationCoordinate2D? = nil
//
//    
//    @ObservedObject var userAccountModel: UserAccountModel
//    @EnvironmentObject var themeManager: ThemeManager
//
//    init(userAccountModel: UserAccountModel, items: [Item] = []) {
//        self._userAccountModel = ObservedObject(wrappedValue: userAccountModel)
//        let itemManager = ItemManager.shared
//        if !items.isEmpty {
//            itemManager.items = items
//        }
//        _itemManager = StateObject(wrappedValue: itemManager)
//    }
//    
//    var body: some View {
//        NavigationStack {
//            content
//                .onAppear {
//                    if !isPreview {
//                        fetchItems()
//                    }
//                }
//                .environmentObject(swapCart)
//        }
//    }
//    
//    private var content: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//                errorMessageView
//                itemsListView
//            }
//            .padding(.horizontal)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Just Swap")
//                        .font(.headline)
//                        .foregroundStyle(Color("thirdColor"))
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    messageButton
//                }
//                ToolbarItem(placement: .navigationBarLeading) {
//                    accountButton
//                }
//            }
//        }
//    }
//    
//    private var errorMessageView: some View {
//        Group {
//            if let errorMessage = errorMessage {
//                Text(errorMessage)
//                    .foregroundStyle(Color.red)
//                    .padding()
//            } else {
//                EmptyView()
//            }
//        }
//    }
//    
//  
////    
////    private func imagesGridView(for item: Item) -> some View {
////        TabView {
////            ForEach(item.imageUrls, id: \.self) { imageUrl in
////                if let url = URL(string: imageUrl) {
////                    AsyncImage(url: url) { image in
////                        image
////                            .resizable()
////                            .aspectRatio(contentMode: .fit)
////                            .clipped()
////                    } placeholder: {
////                        ProgressView()
////                    }
////                }
////            }
////        }
////        .frame(height: 400) // Adjust height as needed
////        .tabViewStyle(PageTabViewStyle())
////    }
//    private var itemsListView: some View {
//           let topItems = Array(itemManager.items.sorted { $0.clickCount > $1.clickCount }.prefix(3))
//           let remainingItems = Array(itemManager.items.dropFirst(3))
//           
//           return VStack(alignment: .leading, spacing: 20) {
//               if !topItems.isEmpty {
//                   topItemsView(topItems)
//               }
//               if !remainingItems.isEmpty {
//                   remainingItemsGridView(remainingItems)
//               }
//           }
//           .padding(.vertical, 20)
//       }
//       
//       private func topItemsView(_ items: [Item]) -> some View {
//           ScrollView(.horizontal, showsIndicators: true) {
//               HStack(spacing: 15) {
//                   ForEach(items) { item in
//                       NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
//                           topItemCard(for: item)
//                       }
//                   }
//               }
//               .padding(.horizontal, 10)
//           }
//       }
//    private func topItemCard(for item: Item) -> some View {
//        VStack(alignment: .leading, spacing: 12) {
//            ZStack(alignment: .topTrailing) {
//                imagesGridView(for: item, overlayName: item.name)
//
//                // Popular Tag
//                HStack(spacing: 4) {
//                    Image(systemName: "flame.fill")
//                        .foregroundColor(.red)
//                    Text("Popular")
//                        .font(.caption2) // Reduced font size for the tag
//                        .foregroundColor(.white)
//                }
//                .padding(6)
//                .background(Color.black.opacity(0.7))
//                .cornerRadius(8)
//                .padding(10)
//            }
//            .frame(height: 220) // Reduced image height
//            .padding(.bottom, 8) // Added space between image and content
//
//            // Price and Value
//            HStack(alignment: .top, spacing: 8) {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("Original Price:")
//                        .font(.footnote) // Reduced font size
//                        .foregroundColor(.gray)
//                    Text("Value:")
//                        .font(.footnote) // Reduced font size
//                        .foregroundColor(.gray)
//                }
//
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("$\(item.originalprice, specifier: "%.2f")")
//                        .strikethrough()
//                        .font(.footnote) // Reduced font size
//                        .foregroundColor(.gray)
//                    Text("$\(item.value, specifier: "%.2f")")
//                        .font(.subheadline)
//                        .fontWeight(.bold)
//                }
//            }
//            .padding(.horizontal)
//
//            // Details
//            Text(item.details)
//                .font(.caption) // Reduced font size for details
//                .lineLimit(2) // Limit to 2 lines to prevent overflowing
//                .padding(.horizontal)
//        }
//        .frame(width: UIScreen.main.bounds.width * 0.6)
//        .background(Color.white)
//        .cornerRadius(10)
//        .shadow(radius: 4)
//    }
//
//       private func remainingItemsGridView(_ items: [Item]) -> some View {
//           let columnWidth: CGFloat = UIScreen.main.bounds.width / 3 - 20
//           let itemHeight: CGFloat = 280
//
//           return LazyVGrid(
//               columns: [
//                   GridItem(.fixed(columnWidth), spacing: 15),
//                   GridItem(.fixed(columnWidth), spacing: 15),
//                   GridItem(.fixed(columnWidth), spacing: 15)
//               ],
//               spacing: 15
//           ) {
//               ForEach(items) { item in
//                   NavigationLink(destination: ItemView(item: item, userAccountModel: userAccountModel)) {
//                       gridItemCard(for: item)
//                   }
//               }
//           }
//           .padding(.horizontal, 10)
//       }
//
//    private func gridItemCard(for item: Item) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            imagesGridView(for: item, overlayName: item.name)
//                .frame(height: 180) // Reduced image height
//                .padding(.bottom, 6) // Added spacing below the image
//
//            // Price and Value
//            HStack(alignment: .top, spacing: 8) {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("Original Price:")
//                        .font(.footnote) // Reduced font size
//                        .foregroundColor(.gray)
//                    Text("Value:")
//                        .font(.footnote) // Reduced font size
//                        .foregroundColor(.gray)
//                }
//
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("$\(item.originalprice, specifier: "%.2f")")
//                        .strikethrough()
//                        .font(.footnote) // Reduced font size
//                        .foregroundColor(.gray)
//                    Text("$\(item.value, specifier: "%.2f")")
//                        .font(.subheadline)
//                        .fontWeight(.bold)
//                }
//            }
//            .padding(.horizontal)
//
//            // Details
//            Text(item.details)
//                .font(.caption) // Reduced font size for details
//                .lineLimit(1) // Limit to 1 line to maintain grid layout
//                .padding(.horizontal)
//        }
//        .background(Color.white)
//        .cornerRadius(10)
//        .shadow(radius: 4)
//    }
//
//
//
//    private func imagesGridView(for item: Item, overlayName: String) -> some View {
//        ZStack(alignment: .bottomLeading) {
//            TabView {
//                ForEach(item.imageUrls, id: \.self) { imageUrl in
//                    if let url = URL(string: imageUrl) {
//                        AsyncImage(url: url) { image in
//                            image
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                                .clipped()
//                        } placeholder: {
//                            ProgressView()
//                        }
//                    }
//                }
//            }
//            .tabViewStyle(PageTabViewStyle())
//
//            Text(overlayName)
//                .font(.headline)
//                .fontWeight(.bold)
//                .foregroundColor(.white)
//                .padding(6)
//                .background(Color.black.opacity(0.7))
//                .cornerRadius(8)
//                .padding([.leading, .bottom], 10)
//        }
//    }
//
//
//
//
//
//
//    private var messageButton: some View {
//        NavigationLink(destination: NewMessageView(currentUserId: "currentUserId")) {
//            ZStack {
//                Image(systemName: "message")
//                    .resizable()
//                    .frame(width: 24, height: 24)
//                    .foregroundStyle(Color("mainColor"))
//                if messageCount > 0 {
//                    Text("\(messageCount)")
//                        .font(.caption2)
//                        .foregroundColor(.white)
//                        .padding(4)
//                        .background(Color.red)
//                        .clipShape(Circle())
//                        .offset(x: 12, y: 12)
//                }
//            }
//        }
//    }
//    
//    private var accountButton: some View {
//        NavigationLink(destination: AccountView()) {
//            Image(systemName: "person.circle")
//                .resizable()
//                .frame(width: 24, height: 24)
//                .foregroundStyle(Color("thirdColor"))
//        }
//    }
//    

//    
//    private func fetchItems() {
//           Task {
//               do {
//                   let items = try await itemManager.fetchItemsByDistance()
//                   self.items = items
//               } catch {
//                   errorMessage = "Failed to load items: \(error.localizedDescription)"
//               }
//           }
//       }
//       
//       private func fetchUserLocation() {
//           Task {
//               do {
//                   userLocation = try await LocationManager.shared.getCurrentLocation().0
//               } catch {
//                   errorMessage = "Failed to get user location: \(error.localizedDescription)"
//               }
//           }
//       }
//   }




//#Preview {
//    let mockItems = [
//        Item(
//            name: "Sample Item 1",
//            details: "This is a sample item used for previews.",
//            originalprice: 19.99,
//            value: 15.99,
//            imageUrls: ["https://via.placeholder.com/200", "https://via.placeholder.com/200"],
//            condition: "New",
//            timestamp: Date(),
//            uid: "sampleUserId1",
//            category: "Electronics", subcategory: "Phones",
//            userName: "John Doe",
//            latitude: 37.7749,
//            longitude: -122.4194
//        ),
//        Item(
//            name: "Sample Item 2",
//            details: "This is another sample item used for previews.",
//            originalprice: 29.99,
//            value: 25.99,
//            imageUrls: ["https://via.placeholder.com/200", "https://via.placeholder.com/100"],
//            condition: "Used",
//            timestamp: Date(),
//            uid: "sampleUserId2",
//            category: "Books", subcategory: "Non-Fiction",
//            userName: "Jane Smith",
//            latitude: 34.0522,
//            longitude: -118.2437
//        ),
//        Item(
//            name: "Sample Item 3",
//            details: "This is yet another sample item used for previews.",
//            originalprice: 9.99,
//            value: 7.99,
//            imageUrls: ["https://via.placeholder.com/200", "https://via.placeholder.com/200"],
//            condition: "Good",
//            timestamp: Date(),
//            uid: "sampleUserId3",
//            category: "Clothing", subcategory: "Shirt",
//            userName: "Alice Johnson",
//            latitude: 40.7128,
//            longitude: -74.0060
//        )
//    ]
//    
//    return HomeScreenView(userAccountModel: UserAccountModel(authManager: AuthManager()), items: mockItems)
//        .environmentObject(SwapCart.shared)
//}
