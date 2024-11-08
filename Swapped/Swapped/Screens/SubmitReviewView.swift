//
//  SubmitReview.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/17/24.
//

import SwiftUI

struct SubmitReviewView: View {
    @State private var rating: Double = 0.0
    @State private var comment: String = ""
    let fromUserId: String
    let toUserId: String
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userAccountModel: UserAccountModel
    var body: some View {
        VStack {
            Text("Submit Review")
                .font(.title)
            RatingView(rating: $rating)
            TextField("Comment", text: $comment)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
//            Button(action: submitReview) {
//                Text("Submit")
//                    .padding()
//            }
        }
        .padding()
    }
//    private func submitReview() {
//        userAccountModel.submitReview(fromUserId: fromUserId, toUserId: toUserId, rating: rating, comment: comment) { result in
//            switch result {
//            case .success:
//                presentationMode.wrappedValue.dismiss()
//            case .failure(let error):
//                print("Failed to submit review: \(error.localizedDescription)")
//            }
//        }
//    }
}
struct RatingView: View {
    @Binding var rating: Double
    var body: some View {
        HStack {
            ForEach(1..<6) { star in
                Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(star <= Int(rating) ? .yellow : .gray)
                    .onTapGesture {
                        rating = Double(star)
                }
            }
        }
    }
}

#Preview {
    SubmitReviewView(fromUserId: "user 1", toUserId: "user 2", userAccountModel: UserAccountModel(authManager: AuthManager()))
}
