//
//  ItemView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.

import SwiftUI
import FirebaseFirestore
import CoreLocation

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ItemView: View {
    let item: Item
    let userAccountModel: UserAccountModel
    
    @EnvironmentObject private var swapCart: SwapCart
    @EnvironmentObject private var itemManager: ItemManager
    @StateObject private var locationManager = LocationManager()
    
    @State private var animateSwap = false
    @State private var addedToCart = false
    @State private var showPossibleSwap = false
    @State private var distanceToItem: Double?
    @State private var askToSwapPressed = false
    @State private var showCurrentUserItems = false
    @State private var fullScreenImage: IdentifiableURL?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var fetchedUserAccount: UserAccountModel?
    @Environment(\.presentationMode) var presentationMode
    
   
    
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
            determinePossibleSwap()
            fetchUserAccount(for: item.uid)
            Task {
                await calculateDistanceToItem()
            }
        }
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
            
            if item.userName != currentUserName {
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
            
            NavigationLink(destination: UserProfileView()) {
                       Text("Owner: \(item.userName)")
                           .font(.subheadline)
                           .foregroundColor(.blue) // Use a color to indicate it's tappable
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
    
    private var actionButtonsSection: some View {
        Group {
            if item.userName != currentUserName {
                HStack(spacing: 40) {
                    NavigationLink(destination: MessagingScreenView(currentUserId: "currentUserId", otherUserId: item.uid, chatId: "\(item.uid)_chat")) {
                        Text("Send Message")
                            .foregroundStyle(Color("mainColor"))
                            .padding()
                            .background(Color("secondColor"))
                            .cornerRadius(5)
                    }
                    
                    Button(action: {
                        showCurrentUserItems = true
                    }) {
                        Text("Ask To Swap")
                            .foregroundStyle(Color("mainColor"))
                            .padding()
                            .background(Color("secondColor"))
                            .cornerRadius(5)
                    }
                    .sheet(isPresented: $showCurrentUserItems) {
                        CurrentUserItemsView(itemToSwap: item)
                    }
                }
                .padding()
                .background(Color.white) // Example of consistent styling
                .cornerRadius(10)
            } else {
                AnyView(EmptyView()) // Use AnyView to handle type mismatch
            }
        }
    }
    private func calculateDistanceToItem() async {
        do {
            // Get the user's current location, assuming the method returns a tuple
            let (currentLocation, _, _, _, _) = try await locationManager.getCurrentLocation()

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


    private var swapPossibleIndicator: some View {
        VStack {
            if showPossibleSwap && isPossibleSwapMatch(for: item, swapCart: SwapCart.shared) {
                Text("Swap Possible")
                    .font(.largeTitle)
                    .foregroundColor(Color("mainColor"))
                    .scaleEffect(animateSwap ? 1.5 : 1.0)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            animateSwap = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation {
                                animateSwap = false
                        }
                    }
                }
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
    
    private func isPossibleSwapMatch(for item: Item, swapCart: SwapCart) -> Bool {
        for cartItem in swapCart.items {
            let priceDifference = abs(item.value - cartItem.value)
            if item.condition == cartItem.condition && priceDifference <= 20.0 {
                return true
            }
        }
        return false
    }
    
    private func determinePossibleSwap() {
        showPossibleSwap = !ItemManager.shared.items.contains { $0.id == item.id } && item.userName != currentUserName
    }
    
    private func fetchUserAccount(for uid: String) {
        Firestore.firestore().collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                _ = data?["name"] as? String ?? "Unknown"
                self.fetchedUserAccount = UserAccountModel(authManager: AuthManager()) // Set fetched values here as needed
            }
        }
    }
}
