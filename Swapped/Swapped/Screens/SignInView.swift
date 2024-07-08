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
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
   @State private var shakeEffect = false
    @State private var isSignedIn = false
    @State private var offset: CGFloat = 0
    @State private var isKeyboardVisible = false
    
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        NavigationStack {
            if isSignedIn {
                MainView()
            } else {
                
                    ZStack {
                        Color("mainColor").edgesIgnoringSafeArea(.all)
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .foregroundStyle(.linearGradient(colors: [Color("secondColor")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 1000, height: 400)
                            .rotationEffect(.degrees(145))
                            .offset(y: -350)
                        Spacer()
                        Rectangle()
                            .fill(Color("AccentColor"))
                            .frame(width: 5, height: 700)
                            .rotationEffect(.degrees(55))
                            .offset(y: -105)
                        
                        VStack(spacing: 20) {
                            Text("                            ")
                                .scrambleEffect(text: "Swap It Out")
                                .foregroundStyle(Color("mainColor"))
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
                                    .modifier(ShakeEffect(shakes: shakeEffect ? 2 : 0))
                                
                                
                                
                                SecureField("Password", text: $password, prompt: Text("Password").foregroundColor(.black))
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color.clear.opacity(0.9))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2))
                                    .modifier(ShakeEffect(shakes: shakeEffect ? 2 : 0))
                                
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
                                        errorMessage = ""
                                    case .failure(let error):
                                        shakeEffect = true
                                    
                                        password = ""
                                        errorMessage = "Incorrect email or password"
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            shakeEffect = false
                                        }
                                        print("Error signing in: \(error.localizedDescription)")
                                    }
                                    
                                }
                            }) {
                                Text("Sign In")
                                    .foregroundStyle(Color("AccentColor"))
                                    .padding()
                                    .frame(width: 130, height: 40)
                                    .background(Color("secondColor"))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color("AccentColor"), lineWidth: 2))
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
    struct ShakeEffect: GeometryEffect {
        var amount: CGFloat = 10
        var shakesPerUnit = 3
        var shakes: Int
        
        var animatableData: CGFloat {
            get { CGFloat(shakes) }
            set { shakes = Int(newValue) }
        }
        
        func effectValue(size: CGSize) -> ProjectionTransform {
            ProjectionTransform(CGAffineTransform(translationX:
                amount * sin(CGFloat(shakes) * .pi * CGFloat(shakesPerUnit)),
                y: 0))
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










