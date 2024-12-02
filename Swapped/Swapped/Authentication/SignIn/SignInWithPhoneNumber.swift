//
//  SignInWithPhoneNumber.swift
//  Swapped
//
//  Created by Donovan Holmes on 9/22/24.

import SwiftUI
import FirebaseAuth

struct SignInWithPhoneNumber: View {
    @State private var phoneNumber: String = ""
    @State private var verificationCode: String = ""
    @State private var verificationID: String?
    @State private var isVerificationCodeSent = false
    @State private var errorMessage: String?
    @State private var isNavigating = false // Control navigation

    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if !isVerificationCodeSent {
                    TextField("Enter your Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .onSubmit(sendVerificationCode)
                    
                    Button(action: sendVerificationCode) {
                        Text("Send Verification Code")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                } else {
                    TextField("Enter verification code", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .onSubmit(verifyCode)
                    
                    Button(action: verifyCode) {
                        Text("Verify Code")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .overlay(
                NavigationLink(destination: MainView(), isActive: $isNavigating) {
                    EmptyView() // No visible link
                }
                .hidden() // Hide the NavigationLink
            )
        }
    }
    
    private func sendVerificationCode() {
        authManager.sendPhoneVerificationCode(phoneNumber: phoneNumber) { result in
            switch result {
            case .success(let verificationID):
                self.verificationID = verificationID
                self.isVerificationCodeSent = true
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func verifyCode() {
        guard let verificationID = verificationID else {
            errorMessage = "Verification ID not found"
            return
        }
        
        authManager.verifyPhoneCode(verificationID: verificationID, verificationCode: verificationCode) { success in
            if success {
                // Verification succeeded
                self.isNavigating = true // Navigate to MainView
            } else {
                // Verification failed
                self.errorMessage = "Verification failed. Please check your code and try again."
            }
        }
    }
}

#Preview {
    SignInWithPhoneNumber()
        .environmentObject(AuthManager.shared)
}
