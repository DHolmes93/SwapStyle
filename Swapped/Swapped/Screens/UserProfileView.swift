//
//  UserProfileView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/17/24.
//
import SwiftUI

struct UserProfileView: View {
    @StateObject private var itemManager = ItemManager.shared
    @StateObject private var userAccountModel = UserAccountModel.shared
    var userUID: String

    var body: some View {
        VStack {
            // Profile Image
            if let profileImageUrlString = userAccountModel.profileImageUrl,
               let profileImageUrl = URL(string: profileImageUrlString),
               !profileImageUrlString.isEmpty {
                AsyncImage(url: profileImageUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                    default:
                        ProgressView()
                            .frame(width: 100, height: 100)
                    }
                }
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .clipShape(Circle())
            }

            // User Details
            VStack(alignment: .leading, spacing: 4) {
                if !userAccountModel.name.isEmpty {
                    Text(userAccountModel.name)
                        .font(.title)
                }
                if !userAccountModel.email.isEmpty {
                    Text(userAccountModel.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text("Rating: \(userAccountModel.rating, specifier: "%.1f")")
                    .font(.headline)
                    .padding(.top, 2)
                if !userAccountModel.city.isEmpty || !userAccountModel.state.isEmpty {
                    Text("Location: \(userAccountModel.city), \(userAccountModel.state)")
                        .font(.body)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal)

            // Divider
            Divider()
                .padding(.vertical, 8)

            // Items Section
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
                .listStyle(InsetGroupedListStyle())
            }
        }
        .padding()
        .onAppear {
            Task {
                do {
                    // Fetch user profile data
                    try await userAccountModel.fetchUserProfile(userUID: userUID)
                    print("Profile Image URL: \(userAccountModel.profileImageUrl ?? "No URL")")
                    
                    // Fetch user items
                    try await itemManager.fetchItemsforUser(for: userUID)
                    print("Successfully fetched user data and items")
                } catch {
                    print("Error fetching data: \(error.localizedDescription)")
                }
            }
        }
    }
}

