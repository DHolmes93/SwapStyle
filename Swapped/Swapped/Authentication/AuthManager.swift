//
//  AuthManager.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//

import Foundation

import UIKit
import FirebaseAuth
import FirebaseDatabase




class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var isSignedIn: Bool = false
    
    func signIn(withEmail email: String, password: String, completion: @escaping(Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let authResult = authResult {
                let user = User(id: authResult.user.uid, name:
                                    authResult.user.displayName ?? "", email:
                                    authResult.user.email ?? "")
                self.isSignedIn = true
                completion(.success(user))
            }
            
            
        }
    }
    
    func signUp(withName name: String, email: String, password: String, completion: @escaping(Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) {
            authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let authResult = authResult {
                
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = name
                changeRequest.commitChanges() {
                    error in if let error = error {
                        completion(.failure(error))
                                   } else {
                            let user = User(id: authResult.user.uid, name: name, email: authResult.user.email ?? "")
                                       self.isSignedIn = true
                            completion(.success(user))
                        }
                        
                        
                    }
                }
               
            }
                    
                }
    func checkAuthState(completion: @escaping (Bool) -> Void) {
        if Auth.auth().currentUser != nil {
            completion(true)
            isSignedIn = true
        } else {
            completion(false)
            isSignedIn = false
        }
    }
    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            isSignedIn = false
            completion(.success(()))
        } catch let signOutError as NSError {
            completion(.failure(signOutError))
        }
    }
 
    
            }

struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
}
