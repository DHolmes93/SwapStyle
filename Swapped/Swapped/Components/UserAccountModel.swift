//
//  UserAccountModel.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import Foundation
import FirebaseAuth
import SwiftUI


class UserAccountModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var profileImage: UIImage?
    
    private let authManager = AuthManager.shared
    
    init() {
        
        if let currentUser = Auth.auth().currentUser {
                name = currentUser.displayName ?? ""
                email = currentUser.email ?? ""
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
    }
