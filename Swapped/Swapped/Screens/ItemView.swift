//
//  ItemView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.

import SwiftUI
import FirebaseFirestore
import CoreLocation
import FirebaseAuth

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ItemView: View {
    let item: Item
    let userAccountModel: UserAccountModel
    
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
    
    @EnvironmentObject var swapCart: SwapCart
    @EnvironmentObject var itemManager: ItemManager
    @StateObject private var locationManager = LocationManager()
    
    @State private var animateSwap = false
    @State private var addedToCart = false
    @State private var showPossibleSwap = false
    @State private var distanceToItem: Double?
    @State private var askToSwapPressed = false
    @State private var showCurrentUserItems = false
    @State private var currentUserItems: [Item] = []  // Store current user items
    @State private var fullScreenImage: IdentifiableURL?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var fetchedUserAccount: UserAccountModel?
    @State private var fromUserName: String = ""
    @State private var toUserName: String = ""
    @Environment(\.presentationMode) var presentationMode
    
   
    
    var currentUserId: String {
        guard let user = Auth.auth().currentUser else {
            print("User is not logged in.")
            return "Unknown" // Or handle it in a way that makes sense for your app
        }
        return user.uid
    }
    var currentUserName: String {
          userAccountModel.name
      }


    var body: some View {
        NavigationStack {
            VStack {
                imageSection
                
                VStack(alignment: .leading, spacing: 8) {
                    productInfoSection
                    actionButtonsSection
                }
                .padding(.horizontal)
                
                if let distance = distanceToItem {
                    Text("Distance: \(Int(distance * 0.000621371)) miles") // Convert meters to miles and round
                           .font(.subheadline)
                           .foregroundColor(.gray)
                                }
                
                swapPossibleIndicator
            }
            .padding()
            .navigationBarItems(trailing: cartButton(swapCart: SwapCart.shared))
            .navigationBarBackButtonHidden(false)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    backButton
//                }
//            }
            .fullScreenCover(item: $fullScreenImage) { _ in fullScreenImageView }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Swap Request"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .onAppear {
            print("Item UID: \(item.uid)")
            print("Current User ID: \(currentUserId)")

            // Fetch current user's items asynchronously
            Task {
                do {
                    currentUserItems = try await fetchItems()
                    // Determine if a swap is possible after fetching the items
                    let canSwap = determinePossibleSwap(for: item, currentUserId: currentUserId, currentUserItems: currentUserItems)
                    print("Possible Swap: \(canSwap)")
                    showPossibleSwap = canSwap // Update the state for swap possibility
                } catch {
                    print("Error fetching current user items: \(error)")
                }
            }

            // Fetch user account for the item's owner
            fetchUserAccount(for: item.uid)
            

            // Calculate distance to the item asynchronously
            Task {
                await calculateDistanceToItem()
            }
        }
    }

           // MARK: - Fetch Items
           private func fetchItems() async throws -> [Item] {
               guard let uid = Auth.auth().currentUser?.uid else {
                   throw NSError(domain: "No user logged in", code: 401, userInfo: nil)
               }

               // Fetch items from Firestore
               let userItemsRef = Firestore.firestore().collection("users").document(uid).collection("items")
               let snapshot = try await userItemsRef.getDocuments()
               let items = snapshot.documents.compactMap { document in
                   var item = try? document.data(as: Item.self)
                   item?.id = document.documentID
                   return item
               }

               // Return fetched items
               return items
           }

    // MARK: - View Components
    
    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: 12) {
                    ForEach(item.imageUrls, id: \.self) { imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: 700, maxHeight: 700)
                                    .cornerRadius(10)
                                    .onTapGesture {
                                        if let url = URL(string: imageUrl) {
                                            fullScreenImage = IdentifiableURL(url: url)
                                        }
                                    }
                            case .failure:
                                Text("Failed to load").foregroundColor(.red)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            if item.uid != currentUserId {
                Button(action: { addToCart(swapCart: SwapCart.shared) }) {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color("secondColor"))
                        .padding()
                }
                .offset(x: -20, y: 20)
            }
        }
    }
    
    private var productInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.title2)
                .fontWeight(.bold)
            
            NavigationLink(destination: UserProfileView(userUID: item.uid)) {
                Text("Owner: \(item.userName)")
                    .font(.subheadline)
                    .foregroundColor(.blue) // Indicate it's tappable
            }
            
            HStack {
                Text("Condition: \(item.condition)")
                Spacer()
                VStack {
                    Text("Original Price: $\(item.originalprice, specifier: "%.2f")")
                    Text("Value: $\(item.value, specifier: "%.2f")")
                }
            }
            .font(.subheadline)
            
            Text("Category: \(item.selectedCategory)")
                .font(.subheadline)
        }
    }
    private func fetchUsernames(for item: Item) async {
        // Fetch the current user's username
        do {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            let currentUser = try await itemManager.getUsername(for: currentUserId)
            fromUserName = currentUser
            
            // Fetch the item's owner's username
            let ownerUserName = try await itemManager.getUsername(for: item.uid)
            toUserName = ownerUserName
        } catch {
            print("Error fetching usernames: \(error)")
        }
    }
    
    private var actionButtonsSection: some View {
        Group {
            HStack(spacing: 40) {
                // Show the "Send Message" button only if the item is not owned by the current user
                if item.uid != currentUserId {
                    NavigationLink(destination: MessagingScreenView(currentUserId: currentUserId, otherUserId: item.uid, chatId: "\(item.uid)_chat")) {
                        Text("Send Message")
                            .foregroundStyle(Color("mainColor"))
                            .padding()
                            .background(Color("secondColor"))
                            .cornerRadius(5)
                    }
                }
                
                // Show the "Ask To Swap" button only if the item is not owned by the current user
                if item.uid != currentUserId {
                    Button(action: {
                        Task {
                            
                            // Fetch usernames before presenting the sheet
                            await fetchUsernames(for: item)
                            showCurrentUserItems = true
                        }
                        
                    }) {
                        Text("Ask To Swap")
                            .foregroundStyle(Color("mainColor"))
                            .padding()
                            .background(Color("secondColor"))
                            .cornerRadius(5)
                    }
                    .sheet(isPresented: $showCurrentUserItems) {
                        // Pass the fetched usernames to the sheet view
                        CurrentUserItemsView(itemToSwap: item)
                    }
                }
            }
            .padding()
            .background(Color.white) // Example of consistent styling
            .cornerRadius(10)
        }
    }
    
    private func calculateDistanceToItem() async {
        do {
            // Get the user's current location, assuming the method returns a tuple
            let (currentLocationCoordinate, _, _, _, _) = try await locationManager.getCurrentLocation()

            // Ensure currentLocationCoordinate is not nil
            guard let currentLocationCoordinate = currentLocationCoordinate else {
                print("Current location is nil")
                return
            }

            // Convert currentLocationCoordinate to CLLocation
            let currentLocation = CLLocation(latitude: currentLocationCoordinate.latitude, longitude: currentLocationCoordinate.longitude)

            // Create a CLLocation object for the item's location
            let itemLocation = CLLocation(latitude: item.latitude, longitude: item.longitude)

            // Calculate the distance in meters
            let distance = currentLocation.distance(from: itemLocation)
            
            // Update the distanceToItem property
            self.distanceToItem = distance
        } catch {
            print("Failed to get current location: \(error.localizedDescription)")
        }
    }

    // MARK: - View Components
    private var swapPossibleIndicator: some View {
        VStack {
            // Show indicator only if a swap is possible and the item is not owned by the current user
            if item.uid != currentUserId && showPossibleSwap {
                Text("Swap Possible")
                    .font(.headline)
                    .foregroundColor(animateSwap ? .red : .green) // Toggle between colors
                    .scaleEffect(animateSwap ? 1.5 : 1.0) // Animate scaling
                    .onAppear {
                        // Start the flashing animation when the view appears
                        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            animateSwap = true
                        }
                    }
            }
        }
        .onAppear {
            // Check if the item is eligible for a swap
            if item.uid != currentUserId {
                let canSwap = determinePossibleSwap(for: item, currentUserId: currentUserId, currentUserItems: currentUserItems)
                showPossibleSwap = canSwap
            }
        }
    }
    private var fullScreenImageView: some View {
        AsyncImage(url: fullScreenImage?.url) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
            case .failure:
                Text("Failed to load").foregroundColor(.red)
            @unknown default:
                EmptyView()
            }
        }
        .onTapGesture {
            fullScreenImage = nil
        }
    }
    private func cartButton(swapCart: SwapCart) -> some View {
        NavigationLink(destination: SwapCartView()) {
            ZStack {
                Image(systemName: "cart")
                    .resizable()
                    .frame(width: 24, height: 24)
                if swapCart.items.count > 0 {
                    Text("\(swapCart.items.count)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 12, y: -12)
                }
            }
        }
    }

    // MARK: - Functions
    private func addToCart(swapCart: SwapCart) {
        swapCart.addItem(item)
        addedToCart = true
    }
    private func isPossibleSwapMatch(for item: Item, with currentUserItems: [Item]) -> Bool {
        print("Checking swap criteria for item: \(item.name) (Value: \(item.value), Condition: \(item.condition))")
        
        for userItem in currentUserItems {
            let priceDifference = abs(item.value - userItem.value)
            print("Comparing with user item: \(userItem.name) (Value: \(userItem.value), Condition: \(userItem.condition))")
            print("Price difference: \(priceDifference)")
            
            if item.condition == userItem.condition && priceDifference <= 20.0 {
                print("Match found: \(userItem.name)")
                return true
            }
        }
        
        print("No matching items found for swap.")
        return false
    }
    private func determinePossibleSwap(for item: Item, currentUserId: String, currentUserItems: [Item]) -> Bool {
        // Ensure the item is not owned by the current user
        guard item.uid != currentUserId else {
            print("Item is owned by the current user. Swap not possible.")
            return false
        }

        // Check if the user has an item matching the swap criteria
        return isPossibleSwapMatch(for: item, with: currentUserItems)
    }
    private func fetchUserAccount(for uid: String) {
        Firestore.firestore().collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("User document not found for uid: \(uid)")
                return
            }
            
            guard let data = document.data() else {
                print("No data found in user document for uid: \(uid)")
                return
            }
            
            // Map Firestore document data to UserAccountModel
            if let name = data["name"] as? String {
                self.fetchedUserAccount = UserAccountModel(authManager: AuthManager())
                self.fetchedUserAccount?.name = name
            }
        }
    }
}
