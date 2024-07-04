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
    @State private var offset: CGFloat = 0
    @State private var isKeyboardVisible = false
    
    var body: some View {
        NavigationStack {
            if isSignedIn {
                MainView()
            } else {
                
                    ZStack {
                        Color.purple.edgesIgnoringSafeArea(.all)
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .foregroundStyle(.linearGradient(colors: [.green], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 1000, height: 400)
                            .rotationEffect(.degrees(145))
                            .offset(y: -350)
                        Spacer()
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: 5, height: 700)
                            .rotationEffect(.degrees(55))
                            .offset(y: -105)
                        
                        VStack(spacing: 20) {
                            
                            Text("                            ")
                                .scrambleEffect(text: "Swap It Out")
                                .font(.system(size: 40, weight: .bold))
                                .padding(.top, 50)
                            
                            Spacer()
                            VStack(spacing: 20) {
                                TextField("Email", text: $email, prompt: Text("Email").foregroundColor(.black))
                                    .foregroundColor(.black)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding()
                                    .background(Color.clear.opacity(0.8))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2))
                                    
                                
                                
                                
                                SecureField("Password", text: $password, prompt: Text("Password").foregroundColor(.black))
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color.clear.opacity(0.9))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2))
                                
                            }
                            .frame(width: 350)
                            .padding(.horizontal, 16)
                            .offset(y: offset)
                            Spacer()
                            
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
                                    .background(Color.orange)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: 2))
                            }
                            Spacer()
                            
                            NavigationLink(destination: SignUpView()) {
                                Text("Dont have an Account? Sign Up")
                                    .foregroundColor(.white)
                                    .underline()
                                
                            }
                            .padding(.bottom, 20)
                        }
                        .padding()
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                    .onAppear {
                        authManager.checkAuthState { isSignedIn in
                            self.isSignedIn = isSignedIn
                            
                        }
                        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                            if let userInfo = notification.userInfo,
                               let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                                let textFieldBottomY = UIScreen.main.bounds.height - 350 + offset
                                let visibleKeyboardY = UIScreen.main.bounds.height - keyboardFrame.height
                                let moveUp = textFieldBottomY - visibleKeyboardY
                                if moveUp > 0 {
                                    withAnimation {
                                        self.offset -= moveUp
                                    }
                                    self.isKeyboardVisible = false
                                }
                            }
                        }
                        
                        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                            withAnimation {
                                self.offset = 0
                            }
                        }
                    }
                    .onDisappear {
                        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
                        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
                    }
                }
            }
            
        }
        
    }

#Preview {
    SignInView()
}


//extension View {
//    func textFieldModifier() -> some View {
//        self
//            .textFieldStyle(PlainTextFieldStyle())
//            .overlay(
//                HStack {
//                    Spacer()
//                    Button(action: {
//                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                    }) {
//                        Image(systemName: "xmark.circle.fill")
//                            .foregroundColor(.gray)
//                    }
//                    .padding(.trailing, 8)
//                })
//    }
//}



//                                .padding(.bottom, 20)
//                                .hidden()



//                            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 50)










