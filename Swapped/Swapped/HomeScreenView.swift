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
    @EnvironmentObject private var notificationManager: NotificationManager // Observe NotificationManager
    var fromUserId: String?
    var fromUserName: String?
    var message: String?

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
                        HStack(spacing: 16) { // Adjust the spacing between buttons as needed
                                   notificationButton
                                   messageButton
                        }
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
            Image(systemName: "line.3.horizontal")
                .font(.title3)
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
//                        .background(Circle().fill(Color.white).shadow(radius: 5))
                        .offset(x: 10, y: -10) // Adjust positioning of the number
                }
            }
        }
    }
    private var notificationButton: some View {
        NavigationLink(destination: NotificationsView()
            .environmentObject(NotificationManager.shared))
        { // Link to notifications page
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(Color("mainColor"))

                // Show combined notification count
                if notificationManager.unreadMessageCount > 0 || notificationManager.unreadSwapRequestCount > 0 {
                    Text("\(notificationManager.unreadMessageCount + notificationManager.unreadSwapRequestCount)")
                        .font(.caption)
                        .foregroundColor(.red) // Change the color to make it more noticeable
                        .offset(x: 10, y: -10) // Position it relative to the bell icon
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

