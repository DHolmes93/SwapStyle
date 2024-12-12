//
//  AuthManager.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//
import Foundation
import FirebaseAuth
import AuthenticationServices
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn

class AuthManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    static let shared = AuthManager()
    
    @Published var isSignedIn: Bool = false
    @Published var currentUser: User?
    @Published var phoneNumber: String = ""
    private var verificationID: String?

    override init() {
        super.init()
        checkCurrentUser()
    }

    private func checkCurrentUser() {
        if let firebaseUser = Auth.auth().currentUser {
            self.currentUser = User(firebaseUser: firebaseUser)
            self.isSignedIn = true
        } else {
            self.currentUser = nil
            self.isSignedIn = false
        }
    }

    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        handleAuthorization(authorization)
    }
    
    private func handleAuthorization(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("Invalid credential")
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to fetch identity token")
            return
        }
        
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nil)
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                print("Error signing in with Apple: \(error.localizedDescription)")
                return
            }
            
            guard let authResult = authResult else {
                print("Auth result is nil")
                return
            }
            
            let userID = authResult.user.uid
            let userName = appleIDCredential.fullName?.givenName ?? "No Name"
            let userEmail = appleIDCredential.email ?? "No Email"
            
            // Save user information to Firestore and set currentUser
            self.checkAndCreateUser(uid: userID, name: userName, email: userEmail, phoneNumber: nil)
        }
    }
    
    func sendPhoneVerificationCode(phoneNumber: String, completion: @escaping (Result<String, Error>) -> Void) {
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    completion(.failure(error))
                } else if let verificationID = verificationID {
                    completion(.success(verificationID))
                }
            }
        }
    
    func verifyPhoneCode(verificationID: String, verificationCode: String, completion: @escaping (Bool) -> Void) {
        guard let verificationID = self.verificationID else {
            print("Verification ID is nil.")
            completion(false)
            return
        }

        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)

        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                print("Phone sign-in error: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let user = authResult?.user else {
                print("User is nil after phone sign-in.")
                completion(false)
                return
            }
            
            // Save user information to Firestore and set currentUser
            self.checkAndCreateUser(uid: user.uid, name: nil, email: nil, phoneNumber: self.phoneNumber)
            completion(true)
        }
    }

    func googleSignIn(completion: @escaping (Bool) -> Void) {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("Root view controller not found")
            completion(false)
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                print("Error during Google sign-in: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let user = result?.user else {
                print("Failed to retrieve Google user")
                completion(false)
                return
            }

            let idToken = user.idToken?.tokenString
            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(withIDToken: idToken ?? "", accessToken: accessToken)
            
            Task {
                do {
                    let authResult = try await Auth.auth().signIn(with: credential)
                    
                    let userID = authResult.user.uid
                    let userName = user.profile?.name ?? "No Name"
                    let userEmail = authResult.user.email ?? "No Email"
                    
                    // Save user information to Firestore and set currentUser
                    self.checkAndCreateUser(uid: userID, name: userName, email: userEmail, phoneNumber: nil)
                    
                    completion(true)
                } catch {
                    print("Error signing in with Google: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }

    private func checkAndCreateUser(uid: String, name: String?, email: String?, phoneNumber: String?) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        userRef.getDocument { (document, error) in
            if let error = error {
                print("Error checking user existence: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                print("User already exists in Firestore.")
                self.currentUser = User(firebaseUser: Auth.auth().currentUser!) // Set currentUser if exists
            } else {
                var userData: [String: Any] = ["uid": uid]
                
                if let name = name, !name.isEmpty {
                    userData["name"] = name
                }
                
                if let email = email, !email.isEmpty {
                    userData["email"] = email
                }
                
                if let phoneNumber = phoneNumber, !phoneNumber.isEmpty {
                    userData["phoneNumber"] = phoneNumber
                }
                
                userRef.setData(userData) { error in
                    if let error = error {
                        print("Error adding user to Firestore: \(error.localizedDescription)")
                    } else {
                        print("User successfully added to Firestore.")
                        self.currentUser = User(firebaseUser: Auth.auth().currentUser!) // Set currentUser after creation
                    }
                }
            }
        }
    }

    func signOut() async throws {
        do {
            try Auth.auth().signOut()
            isSignedIn = false
            currentUser = nil // Clear current user on sign out
        } catch {
            throw error // Re-throw the error for the caller to handle
        }
    }
}

// User model
struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var phoneNumber: String?
    var phone: String?
    var selectedInterestIndex: Int?
    var selectedSkillIndex: Int?
    
    init(firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.name = firebaseUser.displayName ?? ""
        
    }
}
