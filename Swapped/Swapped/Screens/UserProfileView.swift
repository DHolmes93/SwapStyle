//
//  UserProfileView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/17/24.
//
//import SwiftUI
//
//struct UserProfileView: View {
//    @StateObject private var itemManager = ItemManager.shared
//    @ObservedObject var viewModel: UserAccountModel // Changed to @ObservedObject
//    let userId: String
//
//    var body: some View {
//        VStack(spacing: 20) {
//            if let profileImage = viewModel.profileImage {
//                Image(uiImage: profileImage)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: 100, height: 100)
//                    .clipShape(Circle())
//                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
//                    .shadow(radius: 10)
//            } else {
//                Image(systemName: "person.circle")
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: 100, height: 100)
//                    .foregroundStyle(Color.blue)
//            }
//            Text(viewModel.name)
//                .font(.largeTitle)
//                .padding(.top)
//
//            
//            if itemManager.items.isEmpty {
//                Text("User has no items posted")
//                    .font(.headline)
//                    .padding()
//            } else {
//                List(itemManager.items) { item in
//                    VStack(alignment: .leading) {
//                        Text(item.name)
//                            .font(.headline)
//                        Text(item.details)
//                            .font(.subheadline)
//                        Text("$\(item.originalprice, specifier: "%.2f")")
//                            .font(.subheadline)
//                    }
//                }
//            }
//        }
//        .onAppear {
//            Task {
//                // Load the user details, including profile image
//                do {
//                    try await viewModel.fetchUserDetails()
//                    print("Successfully fetched user details")
//                } catch {
//                    print("Failed to fetch user details: \(error.localizedDescription)")
//                }
//                
//                // Fetch items for the user
//                do {
//                    let items = try await itemManager.fetchItems()
//                    print("Successfully fetched items: \(items)")
//                } catch {
//                    print("Failed to fetch items: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    UserProfileView(viewModel: UserAccountModel(authManager: AuthManager()), userId: "otherUserId") // Pass an instance of UserAccountModel
//}


import SwiftUI


struct UserProfileView: View {
    @StateObject private var itemManager = ItemManager.shared
    @StateObject private var userAccountModel = UserAccountModel.shared
       
       var body: some View {
           VStack {
               // User profile details
               if let profileImageUrl = userAccountModel.profileImageUrl {
                   AsyncImage(url: URL(string: profileImageUrl)) { image in
                       image.resizable()
                   } placeholder: {
                       Image(systemName: "person.circle")
                   }
                   .frame(width: 100, height: 100)
                   .clipShape(Circle())
               }
               
               Text(userAccountModel.name)
                   .font(.title)
               
               Text(userAccountModel.email)
                   .font(.subheadline)
               Text("Rating: \(userAccountModel.rating, specifier: "%.1f")")
                               .font(.title2)
                               .padding(.top, 2)
               Text("City: \(userAccountModel.city)  State: \(userAccountModel.state)")
                               .font(.body)
                               .padding(.top, 2)
               
               
               // Divider
               Divider()
                .padding(.top, 2)
            
            if itemManager.items.isEmpty {
                Text("User has no items posted")
                    .font(.headline)
                    .padding()
            } else {
                List(itemManager.items) { item in
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.headline)
                        Text(item.details)
                            .font(.subheadline)
                        Text("$\(item.originalprice, specifier: "%.2f")")
                            .font(.subheadline)
                    }
                }
            }
        }
        .onAppear {
            Task {
                do {
                    await userAccountModel.fetchUserDetails()
                    print("Successfully fetched user details")
                } catch {
                    print("Failed to fetch user details: \(error.localizedDescription)")
                }

                do {
                    try await itemManager.fetchItems()
                    print("Successfully fetched items")
                } catch {
                    print("Failed to fetch items: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
}
