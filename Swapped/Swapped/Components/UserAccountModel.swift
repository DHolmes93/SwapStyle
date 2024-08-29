//
//  UserAccountModel.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import Foundation
import FirebaseAuth
import SwiftUI
import FirebaseFirestore


// Class is responsible for managing the user's account information that coincides with Firebase DB
class UserAccountModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var zipcode: String = ""
    @Published var profileImage: UIImage?
    @Published var rating: Double = 0.0
    @Published var needs: [String] = []
    @Published var interests: [String] = []
    @Published var otherUserNames: [String: String] = [:]
    @Published var otherUserProfileImages: [String: UIImage] = [:]
    
    private let authManager = AuthManager.shared
    // Initializer checks if the user is logged in and fetches their details
    init() {
        if let currentUser = Auth.auth().currentUser {
            name = currentUser.displayName ?? ""
            email = currentUser.email ?? ""
            fetchUserDetails(uid: currentUser.uid) // Fetch user additional details from Firestore
        }
    }
    // Save User Details and additional info to Firebase Auth an Firestore
    func saveUserDetails() {
        if let currentUser = Auth.auth().currentUser {
            let changeRequest = currentUser.createProfileChangeRequest()
            changeRequest.displayName = name
            
            //Commit profile changes
            changeRequest.commitChanges { error in
                if let error = error {
                    print("Error updating profile: \(error.localizedDescription)")
                } else {
                    print("Profile Updated")
                }
            }
            // Update email if changed an send Verification Email
            if email != currentUser.email {
                Auth.auth().currentUser?.sendEmailVerification(beforeUpdatingEmail: email) { error in
                    if let error = error {
                        print("Error updating email: \(error.localizedDescription)")
                    } else {
                        print("Verification Email sent and email updated")
                    }
                }
            }
            
            // Update the password if a new one has been provided
            if !password.isEmpty {
                currentUser.updatePassword(to: password) { error in
                    if let error = error {
                        print("Error updating password: \(error.localizedDescription)")
                    } else {
                        print("Password updated")
                    }
                }
            }
            saveUserAdditionalDetails(uid: currentUser.uid)
        }
    }
    
    // Sign user out using AuthManager in Firebase Auth
    func signOut() {
        authManager.signOut { result in
            switch result {
            case .success:
                print("Signed out successfully")
            case .failure(let error):
                print("Error signing out: \(error.localizedDescription)")
            }
        }
    }
    
    // Fetches user details from Firestore and updates the local variables with fetched data
    private func fetchUserDetails(uid: String) {
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user details: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data() else { return }
            self.city = data["city"] as? String ?? ""
            self.state = data["state"] as? String ?? ""
            self.zipcode = data["zipcode"] as? String ?? ""
            self.rating = data["rating"] as? Double ?? 0.0
            self.needs = data["needs"] as? [String] ?? []
            self.interests = data["interests"] as? [String] ?? []
            if let profileImageUrl = data["profileImageUrl"] as? String {
                self.fetchProfileImage(from: profileImageUrl) { image in
                    self.profileImage = image
                }
            }
        }
    }
    
    // Fetches the name and profile image of another user from Firestore and caches them locally
    func fetchNameAndProfileImage(userId: String, completion: @escaping (String, UIImage?) -> Void) {
        // Check if data has already cached
        if let name = otherUserNames[userId], let profileImage = otherUserProfileImages[userId] {
            completion(name, profileImage)
            return
        }
        // Fetch data from Firestore if not cached
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let name = document.data()?["name"] as? String ?? "Unknown"
                self.otherUserNames[userId] = name
                if let profileImageUrl = document.data()?["profileImageUrl"] as? String {
                    self.fetchProfileImage(from: profileImageUrl) { image in
                        self.otherUserProfileImages[userId] = image
                        completion(name, image)
                    }
                } else {
                    completion(name, nil)
                }
            } else {
                print("Document does not exist")
                    completion("Unknown", nil)
            }
        }
    }
    // Fetches just the name of another user from Firestore and caches it locally
    func fetchName(userId: String, completion: @escaping(String) -> Void) {
        // Check if name is already cached
        if let name = otherUserNames[userId] {
            completion(name)
            return
        }
        
        // Fetch name from Firestore if not cached
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let name = document.data()?["name"] as? String ?? "Unknown"
                self.otherUserNames[userId] = name
                completion(name)
            } else {
                print("Document does not exist")
                completion("Unknown")
            }
        }
    }
    // Saves addutional user details like city, state, rating, etc., to Firestore
    private func saveUserAdditionalDetails(uid: String) {
        let userData: [String: Any] = [
            "city": city,
            "state": state,
            "zipcode": zipcode,
            "rating": rating,
            "needs": needs,
            "interests": interests
        ]
        Firestore.firestore().collection("users").document(uid).setData(userData, merge: true) { error in
            if let error = error {
                print("Error saving user details: \(error.localizedDescription)")
            } else {
                print("User details saved successfully")
            }
        }
    }
    // Fetches an image from a given URL and converts it to a UIImage
    func fetchProfileImage(from url: String, completion: @escaping (UIImage?) -> Void) {
        guard let imageURL = URL(string: url) else { completion(nil); return }
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                completion(nil)
            }
        }.resume()
    }
    // Submits review for another user, saving it to Firestore and updating users rating.
    func submitReview(fromUserId: String, toUserId: String, rating: Double, comment: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let review = Review(fromUserId: fromUserId, toUserId: toUserId, rating: rating, comment: comment, timestamp: Date())
        let db = Firestore.firestore()
        let reviewRef = db.collection("users").document(toUserId).collection("reviews").document()
        
        do {
            try reviewRef.setData(from: review) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    self.updateUserRatingAndReviews(userId: toUserId, rating: rating, completion: completion)
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // Updates the reviewed user's overall rating and review count in Firestore
    private func updateUserRatingAndReviews(userId: String, rating: Double, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let userDocument: DocumentSnapshot
            do {
                try userDocument = transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            // Calculate new rating based on old rating an new review
            guard let oldRating = userDocument.data()?["rating"] as? Double,
                  let oldReviewCount = userDocument.data()?["reviewCount"] as? Int else {
                return nil
            }
            let newRating = (oldRating * Double(oldReviewCount) + rating) / Double(oldReviewCount + 1)
            let newReviewCount = oldReviewCount + 1
            
            transaction.updateData(["rating": newRating, "reviewCount": newReviewCount], forDocument: userRef)
            return nil
        }) { (object, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
        
        
    }
}
// Model for representing a review in Firestore, conforms to Codable and Identifiable
struct Review: Codable,Identifiable {
    @DocumentID var id: String?
    var fromUserId: String
    var toUserId: String
    var rating: Double
    var comment: String
    var timestamp: Date
}





