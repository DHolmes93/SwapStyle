//
//  UserProfileView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/17/24.
//

import SwiftUI

struct UserProfileView: View {
    @StateObject private var itemManager = ItemManager.shared
    @StateObject private var viewModel = UserAccountModel()
    let userId: String
    var body: some View {
        VStack(spacing: 20) {
            if let profileImage = viewModel.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
            } else {
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 100)
                    .foregroundStyle(Color.blue)
                Divider()
                Spacer()
            }
            Text(viewModel.name)
                .font(.largeTitle)
                .padding(.top)
            Text("Rating: \(viewModel.rating, specifier: "%.1f")")
                .font(.title2)
                .padding(.top, 2)
            Text("City: \(viewModel.city)  State: \(viewModel.state)")
                .font(.body)
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
            itemManager.fetchItems { result in
                switch result {
                case .success(let items):
                    print("Successfully fetched items: \(items)")
                case .failure(let error):
                    print("Failed to fetch items: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    UserProfileView(userId: "otherUserId")
}
