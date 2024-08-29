//
//  ItemView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import SwiftUI
import FirebaseFirestore

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ItemView: View {
    let item: Item
    @State private var animateSwap = false
    @State private var addedToCart = false
    @State private var showPossibleSwap = false
    @State private var askToSwapPressed = false
    @State private var showCurrentUserItems = false
    @EnvironmentObject private var swapCart: SwapCart
    @EnvironmentObject private var itemManager: ItemManager
    @Environment(\.presentationMode) var presentationMode
    @State private var fullScreenImage: IdentifiableURL?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var userAccount: UserAccountModel?
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
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
                                            .frame(maxWidth: 1000, maxHeight: 1000)
                                            .cornerRadius(10)
                                            .onTapGesture {
                                                if let url = URL(string: imageUrl) {
                                                    fullScreenImage = IdentifiableURL(url: url)
                                                }
                                            }
                                    case .failure:
                                        Text("Failed to load")
                                            .foregroundStyle(Color.red)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                        .offset(x: 70)
                    }
                    .padding(.horizontal)
            
                    Button(action: {
                        addToCart(swapCart: SwapCart.shared)
                    }) {
                        Image(systemName: "cart.badge.plus")
                            .font(Font.system(size: 30, weight: .bold))
                            .foregroundStyle(Color("secondColor"))
                            .padding()
                            .cornerRadius(5)
//
                    }
                    .offset(x: -300, y: 140)
                    .padding()
                }
                Text("Product Owner: \(item.userName ?? "Unknown User")")
                        .offset(x: 100)
                    Text(item.name)
                        .font(.headline)
                        .offset(x: 100)
                    Text("Condition: \(item.condition)")
                        .font(.subheadline)
                        .offset(x: 100)
                    Text("Original Price: $\(item.originalprice, specifier: "%.2f")")
                        .font(.subheadline)
                        .offset(x: 100)
                    Text("Category: \(item.category)")
                        .font(.subheadline)
                        .offset(x: 100)
                
                GeometryReader { geometry in
                    VStack {
                        if showPossibleSwap && isPossibleSwapMatch(for: item, swapCart: SwapCart.shared) {
                            Text("Swap Possible")
                                .font(.largeTitle)
                                .foregroundStyle(Color("mainColor"))
                                .scaleEffect(animateSwap ? 1.5 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true))
                                .onAppear {
                                    self.animateSwap = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                        self.animateSwap = false
                                    }
                                }
                                .offset(x: min(geometry.size.width, 20), y: geometry.size.height - 20)
                        }
                        
                    }
                    
                }
                .frame(height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                HStack(spacing: 90) {
//                    if let userAccount = userAccount {
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
            }
            .padding()
            .navigationBarItems(trailing: cartButton(swapCart: SwapCart.shared))
        }
        .onAppear {
            determinePossibleSwap()
            fetchUserAccount(for: item.uid)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
        }
        .fullScreenCover(item: $fullScreenImage) { identifiableURL in
            AsyncImage(url: identifiableURL.url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                    case .failure:
                        Text("Failed to load")
                            .foregroundStyle(Color.red)
                    @unknown default:
                        EmptyView()
                    }
            }
                .onTapGesture {
                    fullScreenImage = nil
                }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Swap Request"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
       

    private var backButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundStyle(Color("mainColor"))
                .imageScale(.large)
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
    private func addToCart(swapCart: SwapCart) {
        swapCart.addItem(item)
        addedToCart = true
    }
    private func showAlert(message: String) {
            self.alertMessage = message
            self.showAlert = true
        }
    
    func isPossibleSwapMatch(for item: Item, swapCart: SwapCart) -> Bool {
        for cartItem in swapCart.items {
            let priceDifference = abs(item.value - cartItem.value)
            if item.condition == cartItem.condition && priceDifference <= 20.0 {
                return true
            }
        }
        return false
    }
    private func determinePossibleSwap() {
        if ItemManager.shared.items.contains(where: { $0.id == item.id}) || item.userName == "currentUserName" {
            showPossibleSwap = false
        } else {
            showPossibleSwap = true
        }
    }
    private func fetchUserAccount(for uid: String) {
            Firestore.firestore().collection("users").document(uid).getDocument { document, error in
                if let document = document, document.exists {
                    let data = document.data()
                    let name = data?["name"] as? String ?? "Unknown"
                    let profilePictureURL = data?["profilePictureURL"] as? String ?? ""
                    self.userAccount = UserAccountModel()
                }
            }
        }
}

#Preview {
    let mockItem1 = Item(
                name: "Sample Item",
                details: "Sample details",
                originalprice: 120.0,
                value:80,
                imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
                condition: "Good",
                timestamp: Date(),
                uid: "45768403j",
                category: "Sports"
            )
    
        let mockItem2 = Item(
            name: "Sample Item 2",
            details: "Sample details",
            originalprice: 80.0,
            value: 66.0,
            imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
            condition: "Good",
            timestamp: Date(),
            uid: "45768403j",
            category: "Electronics"
        )
    let cart = SwapCart.shared
    let itemManager = ItemManager.shared
    return NavigationStack {
        ItemView(item: mockItem1)
            .environmentObject(cart)
            .environmentObject(itemManager)
    }
}
