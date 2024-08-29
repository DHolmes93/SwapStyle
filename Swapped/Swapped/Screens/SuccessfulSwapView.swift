//
//  SuccessfulSwapView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/13/24.
//

import SwiftUI

struct SuccessfulSwapView: View {
    let fromItem: Item
    let toItem: Item
    let fromUserId: String
    let toUserId: String
    @State private var navigateToReview = false
    @ObservedObject var userAccountmodel: UserAccountModel
    var body: some View {
        VStack {
            Text("Swapped")
                .font(.largeTitle)
                .padding()
            
            HStack {
                VStack {
                    Text("Your Item")
                    StandardItemView(item: fromItem)
                }
                VStack {
                    Text("Swapped For")
                    StandardItemView(item: toItem)
                }
            }
            .padding()
            
            Button(action: {
                navigateToReview = true
            }) {
                Text("Leave a Review")
                    .font(.title2)
                    .padding()
                    .foregroundStyle(Color.blue)
            }
            .padding()
            .background(NavigationLink(destination: SubmitReviewView(fromUserId: fromUserId, toUserId: toUserId, userAccountModel: UserAccountModel()),
                                       isActive: $navigateToReview
                                      ) {
                EmptyView()
            }
                        )
        }
    }
}

#Preview {
    SuccessfulSwapView(
fromItem: Item(
            name: "Sample Item 1",
            details: "Sample details 1",
            originalprice: 100.0,
            value: 80.0,
            imageUrls: ["https://via.placeholder.com/150"],
            condition: "New",
            timestamp: Date(),
            uid: "uid1",
            category: "Electronics"
        ),
        toItem: Item(
            name: "Sample Item 2",
            details: "Sample details 2",
            originalprice: 200.0,
            value: 150.0,
            imageUrls: ["https://via.placeholder.com/150"],
            condition: "Used",
            timestamp: Date(),
            uid: "uid2",
            category: "Furniture"
        ),
        fromUserId: "user1",
        toUserId: "user2",
userAccountmodel: UserAccountModel()
    )
}
