//
//  UserSession.swift
//  Just Swap
//
//  Created by Donovan Holmes on 12/1/24.
//
import Firebase

class UserSession: ObservableObject {
    @Published var uid: String
    @Published var username: String
    @Published var email: String
    @Published var fcmToken: String?

    init(uid: String, username: String, email: String, fcmToken: String? = nil) {
        self.uid = uid
        self.username = username
        self.email = email
        self.fcmToken = fcmToken
    }

    // Update the session data (e.g., FCM token)
    func updateFCMToken(fcmToken: String) {
        self.fcmToken = fcmToken
        // Optionally, store this data in Firestore or your backend
        updateFCMTokenInFirestore()
    }

    // Function to update the FCM token in Firestore
    private func updateFCMTokenInFirestore() {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        userRef.setData(["fcmToken": fcmToken ?? ""], merge: true) { error in
            if let error = error {
                print("Error updating FCM token: \(error.localizedDescription)")
            } else {
                print("FCM token updated successfully in Firestore.")
            }
        }
    }
}

