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





class UserAccountModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var zipcode: String = ""
    @Published var profileImage: UIImage?
    
    private let authManager = AuthManager.shared
    
    init() {
        
        if let currentUser = Auth.auth().currentUser {
                name = currentUser.displayName ?? ""
                email = currentUser.email ?? ""
            
            
            fetchUserDetails(uid: currentUser.uid)
            
            }
        }
    func saveUserDetails() {
        if let currentUser = Auth.auth().currentUser {
            let changeRequest = currentUser.createProfileChangeRequest()
            changeRequest.displayName = name
            
            changeRequest.commitChanges { error in
                if let error = error {
                    print("Error updating profile: \(error.localizedDescription)")
                } else {
                    print("Profile Updated")
                }
            }
            if email != currentUser.email {
                currentUser.updateEmail(to: email) { error in
                    if let error = error {
                        print("Error updating email: \(error.localizedDescription)")
                    } else {
                        print("Email updated")
                    }
                }
            }
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
        
        func signOut() {
            authManager.signOut { result in
                switch result {
                case .success:
                    print("Signed out successfully")
                case .failure(let error):
                    print("Error signing outL \(error.localizedDescription)")
                }
            }
        }
    
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
        }
    }
    private func saveUserAdditionalDetails(uid: String) {
        let userData: [String: Any] = [
            "city": city,
            "state": state,
            "zipcode": zipcode
        ]
        Firestore.firestore().collection("users").document(uid).setData(userData, merge: true) { error in
            if let error = error {
                print("Error saving user details: \(error.localizedDescription)")
            } else {
                print("User details saved successfully")
            }
        }
    }
    }
