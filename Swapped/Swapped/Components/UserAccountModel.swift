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
    private var otherUserProfileImages: [String: String] = [:]
    
    private var authManager: AuthManager
    @Published var userAccountData: UserAccountData?
    private var currentUser: User?
    
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
          self.currentUser = authManager.currentUser
          self.createdAt = Date()
          
          // Set the name based on userAccountData or other logic
          self.setNameBasedOnUserAccountData()
      }
      
      private func setNameBasedOnUserAccountData() {
          // Check if userAccountData already has a name entered by the user
          if let userAccountName = userAccountData?.name, !userAccountName.isEmpty {
              // Use the name from userAccountData if it exists
              self.name = userAccountName
          } else if let currentUserName = currentUser?.name, currentUserName != currentUser?.email {
              // If no name in userAccountData, fallback to currentUser's name (if not tied to email)
              self.name = currentUserName
          } else {
              // Fallback if there's no valid name in both userAccountData or currentUser
              self.name = "Unknown"
          }
      }
    func createProfile() async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found.")
            return false
        }

        guard let profileImageUrl = self.profileImageUrl, !profileImageUrl.isEmpty else {
            print("Profile image URL is missing.")
            return false
        }

        // Ensure all necessary fields are provided
        guard !self.name.isEmpty else {
            print("Name is required.")
            return false
        }

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
            try await Firestore.firestore().collection("users").document(userId).setData(userProfileData, merge: true)
            print("Profile created successfully.")
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
    func fetchUserProfile(userUID: String) async throws {
        // Check for the "Unknown User ID" case
        if userUID == "Unknown User ID" {
            // Handle the special case where no real data is available
            DispatchQueue.main.async {
                self.name = "Unknown"
                self.email = "No Email"
                self.city = "Unknown"
                self.state = "Unknown"
                self.zipcode = "Unknown"
                self.country = "Unknown"
                self.rating = 0.0
                self.profileImageUrl = nil
                self.needs = []
                self.interests = []
                self.goals = []
                self.skills = []
                self.isProfileCompleted = false
            }
            return
        }

        do {
            // Fetch the document from Firestore
            let document = try await Firestore.firestore()
                .collection("users")
                .document(userUID)
                .getDocument()

            // Ensure data is present in the document
            guard let data = document.data() else {
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "No data found for user ID: \(userUID)"])
            }

            // Decode Firestore data into the properties
            DispatchQueue.main.async {
                self.name = data["name"] as? String ?? "Unknown"
                self.email = data["email"] as? String ?? "No Email"
                self.city = data["city"] as? String ?? "Unknown"
                self.state = data["state"] as? String ?? "Unknown"
                self.zipcode = data["zipcode"] as? String ?? "Unknown"
                self.country = data["country"] as? String ?? "Unknown"
                self.rating = data["rating"] as? Double ?? 0.0
                self.profileImageUrl = data["profileImageUrl"] as? String
                self.needs = data["needs"] as? [String] ?? []
                self.interests = data["interests"] as? [String] ?? []
                self.goals = data["goals"] as? [String] ?? []
                self.skills = data["skills"] as? [String] ?? []
                self.isProfileCompleted = data["isProfileCompleted"] as? Bool ?? false
            }
        } catch let error as URLError {
            // Handle specific URL errors
            print("URLError fetching user profile: \(error.localizedDescription)")
            throw error
        } catch {
            // Handle general errors
            print("Error fetching user profile: \(error.localizedDescription)")
            throw error
        }
    }
    func fetchAndSetProfileImage() async {
            guard let imageUrlString = self.profileImageUrl,
                  let imageUrl = URL(string: imageUrlString) else {
                print("Invalid profileImageUrl.")
                return
            }

            do {
                // Fetch the image data from the URL
                let (data, _) = try await URLSession.shared.data(from: imageUrl)
                if let fetchedImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profileImage = fetchedImage
                    }
                    print("Profile image fetched successfully.")
                } else {
                    print("Failed to convert data to UIImage.")
                }
            } catch {
                // Handle errors
                print("Error fetching profile image: \(error.localizedDescription)")
            }
        }
    
    // Fetch user notifications (stub implementation)
    func fetchUserNotifications() async -> [AppNotification] {
        guard let currentUser = currentUser else {
            print("No current user available.")
            return []
        }

        do {
            // Fetch received messages for the current user
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(currentUser.id)
                .collection("notifications")
                .getDocuments()

            let notifications = snapshot.documents.compactMap { doc -> AppNotification? in
                guard
                    let typeRaw = doc["type"] as? String,
                    let type = NotificationType(rawValue: typeRaw),
                    let fromUserId = doc["fromUserId"] as? String,
                    let message = doc["message"] as? String
                else {
                    return nil
                }

                // Use the sender's name from the notification if available, else fetch from the database
                let fromUserName = doc["fromUserName"] as? String ?? "Unknown"

                return AppNotification(type: type, fromUserId: fromUserId, fromUserName: fromUserName, message: message)
            }

            return notifications
        } catch {
            print("Error fetching user notifications: \(error)")
            return []
        }
    }

    
    func uploadProfileImage(image: UIImage) async -> Bool {
        // Ensure the user is authenticated
        guard let currentUser = await authManager.currentUser else {
            print("User is not authenticated.")
            return false
        }
        
        // Use the authenticated user's ID
        let uid = currentUser.id
        print("Uploading image for user ID: \(uid)")

        // Create a reference to Firebase Storage
        let storageRef = Storage.storage().reference()
        let profileImageRef = storageRef.child("profileImages/\(uid).jpg")

        // Convert UIImage to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data.")
            return false
        }

        do {
            // Upload the image to Firebase Storage
            let _ = try await profileImageRef.putDataAsync(imageData)

            // Retrieve the download URL for the uploaded image
            let downloadURL = try await profileImageRef.downloadURL()

            // Save the download URL to Firestore under the user's document
            try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .updateData(["profileImageUrl": downloadURL.absoluteString])

            print("Profile image uploaded successfully. URL: \(downloadURL.absoluteString)")

            // Optional: You can update the userAccountModel to reflect the new image URL
            DispatchQueue.main.async {
                // Assuming userAccountModel has profileImageUrl as a published property
                self.profileImageUrl = downloadURL.absoluteString
            }

            return true
        } catch let error as NSError {
            // Log the error details for troubleshooting
            print("Error uploading image: \(error.domain) (\(error.code)): \(error.localizedDescription)")
            return false
        }
    }




    // MARK: - Public Function to Call Both Methods Sequentially
    func uploadImageAndCreateProfile(image: UIImage) async -> Bool {
        guard (Auth.auth().currentUser?.uid) != nil else {
            print("User not authenticated.")
            return false
        }

        do {
            // Upload profile image
            let imageUploadSuccess = await uploadProfileImage(image: image)
            
            if imageUploadSuccess {
                // Create profile if image upload succeeds
                let profileCreationSuccess = await createProfile()
                return profileCreationSuccess
            } else {
                print("Image upload failed. Profile creation aborted.")
                return false
            }
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
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

                // Update the UserAccountModel
                updateUserDetails(with: userData)
                print("User data loaded successfully:", userData)

            } catch let decodingError as DecodingError {
                // Handle decoding error
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
        DispatchQueue.main.async {
            self.id = userData.uid
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
    func fetchUserData(for userId: String) async throws -> UserAccountData {
        let userDoc = Firestore.firestore().collection("users").document(userId)
        let snapshot = try await userDoc.getDocument()
        guard let data = snapshot.data() else {
            throw NSError(domain: "User not found", code: 404, userInfo: nil)
        }
        return try Firestore.Decoder().decode(UserAccountData.self, from: data)
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
            await uploadProfileImage(image: profileImage)
        } else {
            await saveUserAdditionalDetails(uid: currentUser.uid)
        }
    }
    // Fetches the profile image URL for the current user
    func fetchProfileImageUrl() async {
        guard let uid = await authManager.currentUser?.id else {
            print("User not authenticated")
            return
        }

        do {
            // Fetch user document from Firestore
            let document = try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .getDocument()

            // Check if document exists and retrieve the image URL from Firestore
            if let data = document.data(), let imageUrl = data["profileImageUrl"] as? String {
                // Ensure that UI updates are done on the main thread
                DispatchQueue.main.async {
                    self.profileImageUrl = imageUrl
                }
                print("Fetched profile image URL: \(imageUrl)")
            }
        } catch {
            print("Error fetching profile image URL: \(error.localizedDescription)")
        }
    }
    // Fetch user's name (or UID) from Firestore
        func fetchName() async {
            guard let uid = await authManager.currentUser?.id else {
                print("User not authenticated")
                return
            }

            do {
                let document = try await Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .getDocument()

                if let data = document.data(), let userName = data["name"] as? String {
                    DispatchQueue.main.async {
                        self.name = userName
                    }
                }
            } catch {
                print("Error fetching user name: \(error.localizedDescription)")
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
//    // MARK: - Fetch Name and Profile Image
    // MARK: - Fetch Name and Profile Image
    func fetchNameAndProfileImage(userId: String) async -> (String, String?) {
        // Check for invalid userId
        guard userId != "Unknown", !userId.isEmpty else {
            print("Invalid userId: \(userId)")
            return ("Unknown", nil)
        }
        
        // Check cache first
        if let name = otherUserNames[userId], let profileImageUrl = otherUserProfileImages[userId] {
            return (name, profileImageUrl)
        }
        
        do {
            let document = try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .getDocument()
            
            guard document.exists else {
                print("User document does not exist for UID: \(userId)")
                return ("Unknown", nil)
            }
            
            // Extract user data
            let name = document.data()?["name"] as? String ?? "Unknown"
            otherUserNames[userId] = name
            
            if let profileImageUrl = document.data()?["profileImageUrl"] as? String {
                otherUserProfileImages[userId] = profileImageUrl
                return (name, profileImageUrl)
            } else {
                print("No profileImageUrl found for UID: \(userId)")
                return (name, nil)
            }
            
        } catch {
            print("Error fetching user document: \(error.localizedDescription)")
            return ("Unknown", nil)
        }
    }

//    // MARK: - Fetch Name and Profile Image
    // MARK: - Helper Methods
    func fetchProfileImage(from url: String) async -> UIImage? {
        guard let imageUrl = URL(string: url) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: imageUrl)
            return UIImage(data: data)
        } catch {
            print("Failed to download image: \(error.localizedDescription)")
            return nil
        }
    }
    // MARK: - Helper Methods
    func fetchCurrentUserProfileImage() async -> UIImage? {
        // Ensure the user is authenticated
        guard let currentUser = await authManager.currentUser,
              let profileImageUrl = userAccountData?.profileImageUrl,  // Assuming this property exists
              let imageUrl = URL(string: profileImageUrl) else {
            print("Current user or profile image URL not available.")
            return nil
        }

        do {
            // Fetch the image data from the URL
            let (data, _) = try await URLSession.shared.data(from: imageUrl)
            return UIImage(data: data)
        } catch {
            // Handle errors and log them
            print("Failed to download image for user \(currentUser.id): \(error.localizedDescription)")
            return nil
        }
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
