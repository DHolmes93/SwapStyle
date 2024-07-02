//
//  SignUpView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import SwiftUI

struct SignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpSuccess = false
    var body: some View {
        VStack {
            Text("Sign Up")
                .font(.largeTitle)
                .padding(.top, 50)
            
            TextField("Name", text: $name)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.orange, lineWidth: 2))
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(5)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.orange, lineWidth: 2))
            
            Button(action: {
                handleSignUp()
            }) {
                Text("Sign Up")
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 130, height: 40)
                    .background(Color.blue)
                    .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2)) }
            NavigationLink(destination: MainView(), isActive: $isSignUpSuccess) { EmptyView()
                
            }
        }
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            VStack {
                Rectangle()
                    .fill(Color.green)
                    .frame(height: 60)
                    .edgesIgnoringSafeArea(.top)
                Spacer()
                Rectangle()
                    .fill(Color.green)
                    .frame(height: 60)
                    .edgesIgnoringSafeArea(.bottom)
            }
        )
        .navigationDestination(isPresented: $isSignUpSuccess) {
            MainView()
        }
    }
    
        func handleSignUp() {
            guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
                print("Missing Data")
                return
            }
            AuthManager.shared.signUp(withName: name, email: email, password: password) { result in
                switch result {
                case.success(_):
                    isSignUpSuccess = true
                case.failure(let error):
                    print("Failed to sign up: \(error.localizedDescription)")
                }
            }
        }
    }
        


#Preview {
    SignUpView()
    }
