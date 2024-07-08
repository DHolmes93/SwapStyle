//
//  SignUpView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore


struct ColoredPlaceholder: ViewModifier {
    let placeholder: String
    @State private var when: Bool
    init(placeholder: String, when: Bool) {
        self.placeholder = placeholder
        self._when = State(initialValue: when)
    }
    func body(content: Content) -> some View {
        content.overlay(
            Text(placeholder)
                .foregroundColor(when ? .gray : .black)
                .opacity(when ? 0.5 : 0.25)
                .padding(.horizontal, 8)
                .scaleEffect(when ? 0.75 : 1, anchor: .leading)
                .offset(x: when ? 10 : 0, y: when ? -12 : 0)
                .animation(nil)
                .onAppear {
                    guard when else { return }
                    withAnimation(Animation.easeOut(duration: 0.25).delay(0.25)) {
                        when = false
                    }
                }
        )
    }
}

extension TextField {
    @ViewBuilder func placeholder<Content: View>(when: Bool, content: () -> Content) -> some View {
        if when {
            content()
        } else {
            self
        }
    }
}

struct SignUpView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipcode = ""
    @State private var isSignUpSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color("mainColor").edgesIgnoringSafeArea(.all)
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .foregroundStyle(.linearGradient(colors: [Color("secondColor")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 1000, height: 400)
                .rotationEffect(.degrees(145))
                .offset(y: -350)
            
            Rectangle()
                .fill(Color("AccentColor"))
                .frame(width: 5, height: 700)
                .rotationEffect(.degrees(55))
                .offset(y: -105)
            
            VStack(spacing: 20) {
                
                Text("Sign Up")
                    .font(.largeTitle)
                    .padding(.top, 50)
                VStack(spacing: 16) {
                    Section(header: Text("Personal Information")) {
                        TextField("Name", text: $name, prompt: Text("Name").foregroundColor(.black)).foregroundColor(.black)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color("AccentColor"), lineWidth: 2))
                      
                        TextField("Email", text: $email, prompt: Text("Email").foregroundColor(.black)).foregroundColor(.black)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color("AccentColor"), lineWidth: 2))
    
                        SecureField("Password", text: $password, prompt: Text("Password").foregroundColor(.black))
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color("AccentColor"), lineWidth: 2))
                        SecureField("Confirm Password", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.black))
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color("AccentColor"), lineWidth: 2))
                        
                        
                    }
                    .frame(width: 375)
                    
                    Section(header: Text("Address")) {
                        TextField("City", text: $city, prompt: Text("City").foregroundColor(.black))
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color("secondColor"), lineWidth: 2))
                        
                        TextField("State", text: $state, prompt: Text("State").foregroundColor(.black))
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color("secondColor"), lineWidth: 2))

                        TextField("Zipcode", text: $zipcode, prompt: Text("Zipcode").foregroundColor(.black))
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color("secondColor"), lineWidth: 2))

                            .keyboardType(.numberPad)
                            .onReceive(Just(zipcode)) { newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    self.zipcode = filtered
                                }
                                
                            }
                        
                    }
                    .frame(width: 375)
                }
                
                
                
                Section {
                    Button(action: {
                        handleSignUp()
                    }) {
                        Text("Sign Up")
                            .foregroundStyle(Color("AccentColor"))
                            .padding()
                            .frame(width: 130, height: 40)
                            .background(Color("secondColor"))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color("AccentColor"), lineWidth: 2))
                    }
                }
            }
        }
    }
    func handleSignUp() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            print("Missing Data")
            return
        }
        guard password == confirmPassword else {
            self.errorMessage = "Passwords do not match"
            return
        }
        AuthManager.shared.signUp(withName: name, email: email, password: password) { result in
            switch result {
            case.success(_):
                saveUserData()
                isSignUpSuccess = true
            case.failure(let error):
                print("Failed to sign up: \(error.localizedDescription)")
            }
        }
    }
    func saveUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let userData: [String : Any] = [
            "name": name,
            "email": email,
            "city": city,
            "state": state,
            "zipcode": zipcode]
        Firestore.firestore().collection("users").document(uid).setData(userData) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            } else {
                print("User data saved successfully. ")
            }
        }
    }
}

#Preview {
    SignUpView()
    }

    
//struct SignUpView_Previews: PreviewProvider {
//    static var previews: some View {
//        SignUpView()
//    }
//}






//struct DiagnalSplitView: View {
//    let color: Color
//
//    var body: some View {
//        GeometryReader { geometry in
//            Path { path in
//                path.move(to: CGPoint(x: 0, y: 0))
//                path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
//                path.addLine(to: CGPoint(x:geometry.size.width, y: geometry.size.height))
//
//            }
//            .fill(self.color)
//            .edgesIgnoringSafeArea(.all)
//        }
//    }
//}
