//
//  UserAccountModel.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore
import UIKit
import FirebaseAuth
import FirebaseStorage

struct UserAccountData: Codable {
    var uid: String
    var name: String
    var email: String
    var birthdate: Date?
    var city: String
    var state: String
    var zipcode: String
    var country: String?
    var profileImageUrl: String?
    var fcmToken: String?
    var rating: Double?
    var needs: [String]?
    var interests: [String]
    var goals: [String]
    var skills: [String]
    var isProfileCompleted: Bool?
}

class UserAccountModel: ObservableObject, Decodable {
    @DocumentID var id: String?
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var birthdate: Date = Date() // Default value
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var zipcode: String = ""
    @Published var country: String = ""
    
    // Profile-related fields
    @Published var profileImageUrl: String?
    @Published var profileImage: UIImage?
    @Published var rating: Double = 0.0
    @Published var needs: [String] = []
    @Published var interests: [String] = []
    @Published var goals: [String] = []
    @Published var skills: [String] = []
    @Published var selectedInterests: [ProfileItem] = []
    
    // User-specific metadata
    @Published var isProfileCompleted: Bool = false
    @Published var selectedInterestIndex: Int = 0
    @Published var selectedSkillIndex: Int = 0
    
    private var otherUserNames: [String: String] = [:]
    private var otherUserProfileImages: [String: UIImage] = [:]
    
    private var authManager: AuthManager
    @Published var userAccountData: UserAccountData?
    
    // Shared instance
    static let shared = UserAccountModel(authManager: AuthManager())
    
    let createdAt: Date
    
    var isProfileComplete: Bool {
          // Check if essential fields are filled
          return !name.isEmpty &&
                !email.isEmpty &&
                !city.isEmpty &&
                !state.isEmpty &&
                !zipcode.isEmpty &&
                !interests.isEmpty &&
                !goals.isEmpty &&
                !skills.isEmpty && profileImageUrl != nil
      }
    
    private enum CodingKeys: String, CodingKey {
        case name, email, birthdate, city, state, zipcode, country, rating, profileImageUrl, needs, interests, goals, skills, isProfileCompleted, selectedInterestIndex, selectedSkillIndex, createdAt
    }
    
    // Initializer for Decodable
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.email = try container.decode(String.self, forKey: .email)
        self.birthdate = try container.decode(Date.self, forKey: .birthdate)
        self.city = try container.decode(String.self, forKey: .city)
        self.state = try container.decode(String.self, forKey: .state)
        self.zipcode = try container.decode(String.self, forKey: .zipcode)
        self.country = try container.decode(String.self, forKey: .country)
        self.rating = try container.decode(Double.self, forKey: .rating)
        self.profileImageUrl = try? container.decode(String.self, forKey: .profileImageUrl)
        self.needs = try container.decode([String].self, forKey: .needs)
        self.interests = try container.decode([String].self, forKey: .interests)
        self.goals = try container.decode([String].self, forKey: .goals)
        self.skills = try container.decode([String].self, forKey: .skills)
        self.isProfileCompleted = try container.decode(Bool.self, forKey: .isProfileCompleted)
        self.selectedInterestIndex = try container.decode(Int.self, forKey: .selectedInterestIndex)
        self.selectedSkillIndex = try container.decode(Int.self, forKey: .selectedSkillIndex)
        
        // Initialize AuthManager
        self.authManager = AuthManager()
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
                   self.createdAt = timestamp.dateValue()
               } else {
                   self.createdAt = Date() // Fallback to current date or handle as needed
               }
        
    }
    
    // Initializer for creating a new user
    init(authManager: AuthManager) {
        self.authManager = authManager
        self.createdAt = Date()
        
         }
    
    func createProfile() async -> Bool {
           guard let userId = Auth.auth().currentUser?.uid else {
               print("No authenticated user found.")
               return false
           }

           // Ensure profileImageUrl is available
           guard let profileImageUrl = self.profileImageUrl else {
               print("Profile image URL is nil")
               return false
           }

           // Create the user profile data
           let userProfileData: [String: Any] = [
               "name": self.name,
               "city": self.city,
               "state": self.state,
               "country": self.country,
               "zipcode": self.zipcode,
               "birthdate": self.birthdate,
               "goals": self.goals,
               "interests": self.interests,
               "skills": self.skills,
               "profileImageUrl": profileImageUrl
           ]

           do {
               // Save the profile data to Firestore
               try await Firestore.firestore().collection("users").document(userId).setData(userProfileData, merge: true)
               return true
           } catch {
               print("Error saving profile: \(error.localizedDescription)")
               return false
           }
       }
    func fetchProfile() async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found.")
            return false
        }

        do {
            let document = try await Firestore.firestore().collection("users").document(userId).getDocument()
            guard document.exists else {
                print("No profile found for user: \(userId)")
                return false
            }

            if let data = document.data() {
                self.name = data["name"] as? String ?? ""
                self.city = data["city"] as? String ?? ""
                self.state = data["state"] as? String ?? ""
                self.country = data["country"] as? String ?? ""
                self.zipcode = data["zipcode"] as? String ?? ""
                self.interests = data["interests"] as? [String] ?? [] // Assuming interests is an array
                self.goals = data["goals"] as? [String] ?? []         // Assuming goals is an array
                self.skills = data["skills"] as? [String] ?? []       // Assuming skills is an array
                self.profileImageUrl = data["profileImageUrl"] as? String
                if let birthdateTimestamp = data["birthdate"] as? Timestamp {
                        self.birthdate = birthdateTimestamp.dateValue()
                    } else {
                        self.birthdate = Date() // Optional allows nil
                    }
                

                // Check profile completion after setting properties
                checkProfileCompletion()
            }

        } catch {
            print("Error fetching profile: \(error.localizedDescription)")
            return false
        }

        return true
    }


    // MARK: - Public Function to Call Both Methods Sequentially
    func uploadImageAndCreateProfile(image: UIImage) async -> Bool {
           guard let userId = Auth.auth().currentUser?.uid else {
               print("User not authenticated.")
               return false
           }
           
           // Upload profile image and wait for completion
           let imageUploadSuccess = await uploadProfileImage(image: image, uid: userId)
           
           // If image upload was successful, proceed to create the profile
           if imageUploadSuccess {
               let profileCreationSuccess = await createProfile()
               return profileCreationSuccess
           } else {
               print("Image upload failed. Profile creation aborted.")
               return false
           }
       }


    
    private func createUserSubCollections(for userId: String) async -> Bool {
        let userReviewsRef = Firestore.firestore().collection("users").document(userId).collection("reviews")
        
        let initialReview = Review(fromUserId: "system", toUserId: userId, rating: 5.0, comment: "Welcome!", timestamp: Date())
        
        do {
            try await userReviewsRef.addDocument(from: initialReview)
            print("Initial review document created for user ID: \(userId)")
            return true
        } catch {
            print("Error adding review: \(error.localizedDescription)")
            return false
        }
    }
    // Helper function to recursively convert Firestore data to JSON-compatible data
    // Function to convert Firestore data to JSON-compatible data using JSONSerialization
    func convertFirestoreDataToJSONCompatible(_ documentData: [String: Any]) -> [String: Any] {
        var jsonCompatibleData = [String: Any]()
        
        for (key, value) in documentData {
            if let dateValue = value as? Date {
                // Convert Date to timeIntervalSince1970
                jsonCompatibleData[key] = dateValue.timeIntervalSince1970
            } else if let timestampValue = value as? Timestamp {
                // Convert Firestore Timestamp to Date and then to timeIntervalSince1970
                jsonCompatibleData[key] = timestampValue.dateValue().timeIntervalSince1970
            } else if let subDict = value as? [String: Any] {
                // Recursively handle nested dictionaries
                jsonCompatibleData[key] = convertFirestoreDataToJSONCompatible(subDict)
            } else if let subArray = value as? [Any] {
                // Handle arrays by converting each element recursively
                jsonCompatibleData[key] = subArray.map { element in
                    convertElementToJSONCompatible(element)
                }
            } else {
                // Copy other JSON-compatible values directly
                jsonCompatibleData[key] = value
            }
        }
        
        return jsonCompatibleData
    }

    // Helper function to handle individual elements within an array
    func convertElementToJSONCompatible(_ element: Any) -> Any {
        if let dateElement = element as? Date {
            return dateElement.timeIntervalSince1970
        } else if let timestampElement = element as? Timestamp {
            return timestampElement.dateValue().timeIntervalSince1970
        } else if let dictElement = element as? [String: Any] {
            return convertFirestoreDataToJSONCompatible(dictElement)
        } else {
            // Return the element as is if it is JSON-compatible
            return element
        }
    }

//    func convertFirestoreData(_ documentData: [String: Any]) -> [String: Any] {
//        var jsonCompatibleData = [String: Any]()
//
//        for (key, value) in documentData {
//            if let dateValue = value as? Date {
//                // Convert Date to ISO8601 string or timestamp
//                jsonCompatibleData[key] = dateValue.timeIntervalSince1970 // or use dateValue.ISO8601String() if you prefer a string format
//            } else if let subDict = value as? [String: Any] {
//                // Recursively handle nested dictionaries
//                jsonCompatibleData[key] = convertFirestoreData(subDict)
//            } else if let subArray = value as? [Any] {
//                // Recursively handle arrays
//                jsonCompatibleData[key] = subArray.map { element in
//                    if let dateElement = element as? Date {
//                        return dateElement.timeIntervalSince1970
//                    } else if let dictElement = element as? [String: Any] {
//                        return convertFirestoreData(dictElement)
//                    } else {
//                        return element
//                    }
//                }
//            } else {
//                // Copy any other values as they are JSON compatible
//                jsonCompatibleData[key] = value
//            }
//        }
//        
//        return jsonCompatibleData
//    }


    func loadUserDetails() async {
        guard let userId = await authManager.currentUser?.id else {
            print("No current user found")
            return
        }

        print("Fetching user details for user ID: \(userId)")

        let documentRef = Firestore.firestore().collection("users").document(userId)

        do {
            let document = try await documentRef.getDocument()

            // Check if the document exists
            guard document.exists else {
                print("No document found for user ID: \(userId)")
                return
            }

            // Fetch document data
            guard let documentData = document.data() else {
                print("Document data is nil")
                return
            }

            // Debug: Print raw document data
            print("Raw document data: \(documentData)")

            // Attempt decoding
            do {
                let jsonCompatibleData = convertFirestoreDataToJSONCompatible(documentData)
                let userData = try JSONDecoder().decode(UserAccountData.self, from: JSONSerialization.data(withJSONObject: jsonCompatibleData))
                updateUserDetails(with: userData)
                print("User data loaded successfully:", userData)

            } catch let decodingError as DecodingError {
                // Handle different cases for decoding error
                handleDecodingError(decodingError)
            } catch {
                print("Failed to decode UserAccountData:", error)
            }

        } catch {
            print("Error fetching document: \(error.localizedDescription)")
        }
    }

    // Helper function to handle decoding errors more clearly
    private func handleDecodingError(_ error: DecodingError) {
        switch error {
        case .dataCorrupted(let context):
            print("Data corrupted at \(context.codingPath): \(context.debugDescription)")
        case .keyNotFound(let key, let context):
            print("Key '\(key)' not found at \(context.codingPath): \(context.debugDescription)")
        case .typeMismatch(let type, let context):
            print("Type mismatch for type '\(type)' at \(context.codingPath): \(context.debugDescription)")
        case .valueNotFound(let value, let context):
            print("Value '\(value)' not found at \(context.codingPath): \(context.debugDescription)")
        @unknown default:
            print("Unknown decoding error: \(error)")
        }
    }

    // Helper function to update UserAccountModel with the decoded data
    private func updateUserDetails(with userData: UserAccountData) {
        self.name = userData.name
        self.email = userData.email
        self.birthdate = userData.birthdate ?? Date()  // Use default if nil
        self.city = userData.city
        self.state = userData.state
        self.zipcode = userData.zipcode
        self.country = userData.country ?? ""
        self.profileImageUrl = userData.profileImageUrl
        self.rating = userData.rating ?? 0.0
        self.needs = userData.needs ?? []
        self.interests = userData.interests
        self.goals = userData.goals
        self.skills = userData.skills
        self.isProfileCompleted = userData.isProfileCompleted ?? false
    }


    func checkProfileCompletion() {
        print("Checking profile completion...")
        print("Name: \(name)")
        print("Email: \(authManager.currentUser?.email ?? "No Email")")
        print("City: \(city)")
        print("State: \(state)")
        print("Zipcode: \(zipcode)")
        print("Interests count: \(interests.count)")
        print("Goals count: \(goals.count)")
        print("Skills count: \(skills.count)")
        print("Profile Image URL: \(profileImageUrl ?? "No URL")")
        
        // Unwrapping email
        let userEmail = authManager.currentUser?.email ?? ""
        
        isProfileCompleted =
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !userEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !zipcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !interests.isEmpty &&
            !goals.isEmpty &&
            !skills.isEmpty &&
            !(profileImageUrl?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false)
        
        print("Profile completion status: \(isProfileCompleted)")
    }



    func fetchUserDetails() async {
           await loadUserDetails() // Fetches user details and updates the model
       }
    private func updateFromFirestore(_ data: [String: Any]) {
        name = data["name"] as? String ?? ""
        email = data["email"] as? String ?? ""
        // Populate other fields similarly...
    }

    func saveUserDetails() async {
        guard let currentUser = Auth.auth().currentUser else {
            print("No current user found.")
            return
        }

        let changeRequest = currentUser.createProfileChangeRequest()
        changeRequest.displayName = name

        do {
            try await changeRequest.commitChanges()
            print("Profile updated successfully")
        } catch {
            print("Error updating profile: \(error.localizedDescription)")
        }

        if let profileImage = profileImage {
            await uploadProfileImage(image: profileImage, uid: currentUser.uid)
        } else {
            await saveUserAdditionalDetails(uid: currentUser.uid)
        }
    }

    func uploadProfileImage(image: UIImage, uid: String) async -> Bool {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("Failed to convert profile image to JPEG data.")
                return false
            }

            let storageRef = Storage.storage().reference().child("profileImages/\(uid).jpg")

            do {
                // Upload image data to Firebase Storage
                _ = try await storageRef.putDataAsync(imageData)
                
                // Get download URL of the uploaded image
                let downloadURL = try await storageRef.downloadURL()
                
                // Update profileImageUrl with the downloaded URL string
                DispatchQueue.main.async {
                    self.profileImageUrl = downloadURL.absoluteString
                }
                
                return true
            } catch {
                print("Error uploading image: \(error.localizedDescription)")
                return false
            }
        }

        func fetchProfileImageUrl() async -> String? {
            guard let uid = Auth.auth().currentUser?.uid else {
                print("User not authenticated")
                return nil
            }

            let db = Firestore.firestore()
            let userDocRef = db.collection("users").document(uid)

            do {
                let document = try await userDocRef.getDocument()
                guard let data = document.data(),
                      let profileImageUrl = data["profileImageUrl"] as? String else {
                    print("User document does not exist or profileImageUrl not found")
                    return nil
                }
                return profileImageUrl
            } catch {
                print("Error fetching user document: \(error.localizedDescription)")
                return nil
            }
        }
    func fetchProfileImageUrlForUser(for userId: String) async -> String? {
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userId)

        do {
            let document = try await userDocRef.getDocument()
            guard let data = document.data(),
                  let profileImageUrl = data["profileImageUrl"] as? String else {
                print("User document does not exist or profileImageUrl not found for userId: \(userId)")
                return nil
            }
            return profileImageUrl
        } catch {
            print("Error fetching user document for userId \(userId): \(error.localizedDescription)")
            return nil
        }
    }
    

    private func saveUserAdditionalDetails(uid: String) async {
        let userDocumentRef = Firestore.firestore().collection("users").document(uid)
        
        let userData: [String: Any] = [
            "name": name,
            "birthdate": birthdate,
            "city": city,
            "state": state,
            "zipcode": zipcode,
            "country": country,
            "email": email,
            "rating": rating,
            "profileImageUrl": profileImageUrl ?? "",
            "needs": needs,
            "interests": interests,
            "goals": goals,
            "skills": skills,
            "isProfileCompleted": isProfileCompleted
        ]
        
        do {
            try await userDocumentRef.updateData(userData)
            print("User data updated successfully.")
        } catch {
            print("Error updating user details: \(error.localizedDescription)")
        }
    }



    // MARK: - Fetch Name and Profile Image

    func fetchNameAndProfileImage(userId: String, completion: @escaping (String, UIImage?) -> Void) {
        if let name = otherUserNames[userId], let profileImage = otherUserProfileImages[userId] {
            completion(name, profileImage)
            return
        }

        Firestore.firestore().collection("users").document(userId).getDocument { document, error in
            guard let document = document, document.exists else {
                completion("Unknown", nil)
                return
            }

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
        }
    }

    // MARK: - Helper Methods
    func fetchProfileImage(from imageUrl: String, completion: @escaping (UIImage?) -> Void) {
           guard let url = URL(string: imageUrl) else {
               completion(nil)
               return
           }

           // Fetch the image data
           URLSession.shared.dataTask(with: url) { data, response, error in
               if let error = error {
                   print("Error fetching profile image: \(error.localizedDescription)")
                   completion(nil)
                   return
               }
               guard let data = data, let image = UIImage(data: data) else {
                   print("Failed to convert data to image.")
                   completion(nil)
                   return
               }
               DispatchQueue.main.async {
                   completion(image) // Call the completion handler with the loaded image
               }
           }.resume() // Don't forget to resume the task
       }

    // Convert the object to a dictionary for saving to Firestore
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "birthdate": birthdate,
            "city": city,
            "state": state,
            "zipcode": zipcode,
            "country": country,
            "skills": skills,
            "interests": interests,
            "goals": goals,
            "profileImageUrl": profileImageUrl ?? "" // Store the URL string for the profile image
        ]
    }
}

// Review model
struct Review: Codable, Identifiable {
    @DocumentID var id: String?
    var fromUserId: String
    var toUserId: String
    var rating: Double
    var comment: String
    var timestamp: Date

    init(fromUserId: String, toUserId: String, rating: Double, comment: String, timestamp: Date = Date()) {
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.rating = rating
        self.comment = comment
        self.timestamp = timestamp
    }
}
