//
//  SignInView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import GoogleSignInSwift

struct SignInView: View {
    
    @Environment(\.colorScheme) var colorScheme // Detect current color scheme
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isNavigating = false // Control navigation
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color("mainColor").edgesIgnoringSafeArea(.all)

                // Navigation link to MainView
                NavigationLink(destination: MainView(), isActive: $isNavigating) {
                    EmptyView() // Use EmptyView for hidden navigation
                }

                signInButtonsView()
                    .onAppear {
                        // Check if user is already signed in
                        if authManager.isSignedIn {
                            isNavigating = true // Automatically navigate if already signed in
                        }
                    }
            }
            .navigationBarBackButtonHidden(authManager.isSignedIn) // Hide the back button
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    @ViewBuilder
    private func signInButtonsView() -> some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .foregroundStyle(.linearGradient(colors: [Color("secondColor")], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 1000, height: 400)
            .rotationEffect(.degrees(145))
            .offset(y: -350)

        VStack {
            HStack(spacing: 30) {
                Spacer()
                Image("Swap-2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170, height: 170)
                    .padding(.top, 50)

                Text("Just Swap")
                    .foregroundStyle(Color("thirdColor"))
                    .font(.system(size: 45, weight: .bold))
                    .padding(.top, 20)

                Spacer()
            }
            .padding(.bottom, 80)

            Spacer()

            // Sign-in buttons
            VStack(alignment: .center, spacing: 40) {
                GoogleSignInButton {
                    authManager.googleSignIn { success in
                        if success {
                            print("Google Sign-In successful")
                            authManager.isSignedIn = true // Update sign-in state
                            isNavigating = true // Navigate to MainView after successful sign-in
                        } else {
                            showAlertWithMessage("Google Sign-In failed.")
                        }
                    }
                }
                .frame(width: 250, height: 45)
                .cornerRadius(10)
                .padding()

                SignInWithAppleButton(
                    onRequest: { request in
                        let appleIDRequest = ASAuthorizationAppleIDProvider().createRequest()
                        appleIDRequest.requestedScopes = [.fullName, .email]
                        request.requestedScopes = appleIDRequest.requestedScopes
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            handleAuthorization(authorization)
                        case .failure(let error):
                            showAlertWithMessage("Apple Sign-In failed: \(error.localizedDescription)")
                        }
                    }
                )
                .signInWithAppleButtonStyle(.whiteOutline)
                .frame(width: 250, height: 45)
                .cornerRadius(10)
                .padding()

                // Phone number sign-in button
                HStack(spacing: 10) {
                    Image(systemName: "phone.fill")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundStyle(Color("thirdColor"))
                    NavigationLink(destination: SignInWithPhoneNumber()) {
                        Text("Sign In with Phone Number")
                            .foregroundColor(.black)
                            .padding()
                            .frame(width: 250, height: 40)
                            .background(Color("secondColor"))
                            .cornerRadius(10)
                    }
                }
                .offset(x: -18)
            }

            Spacer()
        }
    }

    private func handleAuthorization(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            showAlertWithMessage("Invalid credentials.")
            return
        }

        let userID = appleIDCredential.user
        let fullName = appleIDCredential.fullName
        let email = appleIDCredential.email

        guard let identityToken = appleIDCredential.identityToken,
              let authCode = appleIDCredential.authorizationCode,
              let tokenString = String(data: identityToken, encoding: .utf8),
              let authCodeString = String(data: authCode, encoding: .utf8) else {
            showAlertWithMessage("Failed to retrieve identity or auth token.")
            return
        }

        let appleCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nil, accessToken: authCodeString)

        Auth.auth().signIn(with: appleCredential) { authResult, error in
            if let error = error {
                showAlertWithMessage("Apple Sign-In failed: \(error.localizedDescription)")
                return
            }

            // Successful sign-in, update auth state and navigate to MainView
            print("Apple Sign-In successful")
            authManager.isSignedIn = true
            isNavigating = true
        }
    }

    private func showAlertWithMessage(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthManager.shared)
}
