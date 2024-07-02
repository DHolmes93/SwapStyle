//
//  SignInView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSignedIn = false
    @StateObject private var authManager = AuthManager.shared
    @State private var rotateGlobe = false
    
    var body: some View {
        if isSignedIn {
            MainView()
        } else {
            ZStack {
                VStack {
                    Text("Swapped")
                        .font(.largeTitle)
                        .padding(.top, 50)
                    
                    Image(systemName: "globe")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .rotationEffect(rotateGlobe ? Angle.degrees(360) :
                                            Angle.degrees(0))
                        .onAppear {
                            withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                                rotateGlobe = true
                            }
                        }
                    
                    
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.green, lineWidth: 2))
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.green, lineWidth: 2))
                    
                    Button(action: {
                        authManager.signIn(withEmail: email, password: password) { result in
                            switch result {
                            case .success:
                                isSignedIn = true
                            case .failure(let error):
                                print("Error signing in: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        Text("Sign In")
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 130, height: 40)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2))
                    }
                    NavigationLink(destination: SignUpView()) {
                        Text("Sign Up")
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 130, height: 40)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2))
                    }
                }
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(10)
                
                VStack {
                    Rectangle()
                        .fill(Color.green)
                        .frame(height: 60)
                    Spacer()
                    Rectangle()
                        .fill(Color.green)
                        .frame(height: 60)
                    
                }
                .edgesIgnoringSafeArea(.vertical)
            }
            .onAppear {
                authManager.checkAuthState { isSignedIn in
                    self.isSignedIn = isSignedIn
                }
            }
        }
    }
}




#Preview {
    SignInView()
}
