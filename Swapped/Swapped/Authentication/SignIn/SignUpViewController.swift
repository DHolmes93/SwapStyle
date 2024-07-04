//
//  SignUpViewController.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//
//import Foundation
//import UIKit

//class SignUpViewController: UIViewController {
//    private let containerView = UIView()
//    private let nameTextField = UITextField()
//    private let emailTextField = UITextField()
//    private let passwordTextField = UITextField()
//    private let cityTextField = UITextField()
//    private let stateTextField = UITextField()
//    private let signUpButton = UIButton(type: .system)
//    
//    
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//        setupViews()
//        setupConstraints()
//    }
//    private func setupViews() {
//        // Name Text Field
//        nameTextField.placeholder = "Name"
//        nameTextField.borderStyle = .roundedRect
//        nameTextField.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Email Text Field
//        emailTextField.placeholder = "Email"
//        emailTextField.borderStyle = .roundedRect
//        emailTextField.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Password Text Field
//        passwordTextField.placeholder = "password"
//        passwordTextField.borderStyle = .roundedRect
//        passwordTextField.isSecureTextEntry = true
//        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Sign Up Button
//        signUpButton.setTitle("Sign In", for: .normal)
//        signUpButton.titleLabel?.font = UIFont(name: "Impact", size: 18)
//        signUpButton.setTitleColor(.white, for: .normal)
//        signUpButton.backgroundColor = .systemBlue
//        signUpButton.layer.borderWidth = 2
//        signUpButton.layer.borderColor = UIColor.systemBlue.cgColor
//        signUpButton.layer.cornerRadius = 10
//        signUpButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
//        signUpButton.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(containerView)
//        view.addSubview(nameTextField)
//        view.addSubview(emailTextField)
//        view.addSubview(passwordTextField)
//        view.addSubview(signUpButton)
//        
//    }
//    private func setupConstraints() {
//        containerView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            
//            nameTextField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
//            nameTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//            nameTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//            
//            emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
//            emailTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//            emailTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//            
//            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
//            passwordTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//            passwordTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//            
//            signUpButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30),
//            signUpButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
//            signUpButton.widthAnchor.constraint(equalToConstant: 200),
//            signUpButton.heightAnchor.constraint(equalToConstant: 50),
//            signUpButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
//            
//        ])
//        
//    }
//    
//    
//    
//    @objc func handleSignUp() {
//        guard let name = nameTextField.text, !name.isEmpty,
//              let email = emailTextField.text, !email.isEmpty,
//              let password = passwordTextField.text, !password.isEmpty
//        else {
//            print("Missing Data")
//            return
//        }
//        AuthManager.shared.signUp(withName: name, email: email, password: password) {
//            result in switch result {
//            case .success(_):
//                print("Successfully signed in")
//            case.failure(let error): print("Failed to sign in with email: \(error.localizedDescription)")
//            }
//        }
//    }
//    @objc func cancelSignUp() {
//        dismiss(animated: true, completion: nil)
//    }
//    
//}
