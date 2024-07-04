//
//  SignInViewController.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//
//
//import Foundation
//import UIKit
//import SwiftUI
//
//protocol SignInViewControllerDelegate: AnyObject {
//    func dicCompleteSignIn(user: User)
//    func didRequestSignUp()
//}
//
//
//class SignInViewController: UIViewController {
//    
//    weak var delegate:
//    SignInViewControllerDelegate?
//    
//    private let containerView = UIView()
//    private let titleLabel = UILabel()
//    private let imageView = UIImageView()
//    private let emailTextField = UITextField()
//    private let passwordTextField = UITextField()
//    private let signInButton = UIButton(type: .system)
//    private let signUpButton = UIButton(type: .system)
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//        setupViews()
//        setupConstraints()
//    }
//    
//    private func setupViews() {
//        //Title Label
//        titleLabel.text = "Swapped"
//        titleLabel.font = UIFont(name: "Impact", size: 45)
//        titleLabel.textAlignment = .center
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Text Fields
//        emailTextField.placeholder = "Email"
//        emailTextField.textColor = .black
//        emailTextField.borderStyle = .roundedRect
//        emailTextField.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Password Text Fields
//        passwordTextField.placeholder = "Password"
//        passwordTextField.textColor = .black
//        passwordTextField.borderStyle = .roundedRect
//        passwordTextField.isSecureTextEntry = true
//        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Buttons
//        signInButton.setTitle("Sign In", for: .normal)
//        signInButton.titleLabel?.font = UIFont(name: "Impact", size: 18)
//        signInButton.setTitleColor(.white, for: .normal)
//        signInButton.backgroundColor = .systemBlue
//        signInButton.layer.borderWidth = 2
//        signInButton.layer.borderColor = UIColor.systemBlue.cgColor
//        signInButton.layer.cornerRadius = 10
//        signInButton.addTarget(self, action: #selector(handleSignIn), for: .touchUpInside)
//        signInButton.translatesAutoresizingMaskIntoConstraints = false
//        
//        signUpButton.setTitle("Don't have an Account? Sign Up", for: .normal)
//        signUpButton.titleLabel?.font = UIFont(name: "Impact", size: 18)
//        signUpButton.setTitleColor(.white, for: .normal)
//        signUpButton.backgroundColor = .systemBlue
//        signUpButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
//        signUpButton.translatesAutoresizingMaskIntoConstraints = false
//        
//        
//        // Subviews
//        view.addSubview(containerView)
//        containerView.addSubview(titleLabel)
//        containerView.addSubview(emailTextField)
//        containerView.addSubview(passwordTextField)
//        containerView.addSubview(signInButton)
//        containerView.addSubview(signUpButton)
//        setupColoredBlocks()
//    }
//        
//    
//    private func setupColoredBlocks() {
//        let topBlock = UIView()
//        topBlock.backgroundColor = .systemGreen
//        topBlock.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(topBlock)
//        NSLayoutConstraint.activate([
//            topBlock.topAnchor.constraint(equalTo: view.topAnchor),
//            topBlock.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            topBlock.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            topBlock.heightAnchor.constraint(equalToConstant: 60)
//        ])
//        let bottomBlock = UIView()
//        bottomBlock.backgroundColor = .systemGreen
//        bottomBlock.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(bottomBlock)
//        NSLayoutConstraint.activate([
//            bottomBlock.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            bottomBlock.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            bottomBlock.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            bottomBlock.heightAnchor.constraint(equalToConstant: 60)
//        
//        ])
//    }
//    
//    private func setupConstraints() {
//        containerView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            
//            // Title Label
//            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
//            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 50),
////            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
////            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//            
//            
//            // Email Text Field
//            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
//            emailTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
//            emailTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
//            // Password Text Field
//            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 20),
//            passwordTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
//            passwordTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
//            passwordTextField.heightAnchor.constraint(equalToConstant: 40),
//            // Sign In Button
//            signInButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 40),// distance between sign in button and text field
//            signInButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),// center buttons
//            signInButton.widthAnchor.constraint(equalToConstant: 130), //Width of sign In button
//            signInButton.heightAnchor.constraint(equalToConstant: 40),// height of sign in button
//            
//            // Sign Up Button
//            signUpButton.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 20),// Distance between text fields
//            signUpButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
////            signUpButton.widthAnchor.constraint(equalToConstant: 130),
////            signUpButton.heightAnchor.constraint(equalToConstant: 40),
////            signUpButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
//            
//            
//            
//        ])
//        
//    }
//    
//        
//        
//        @objc func handleSignIn() {
//            guard let email = emailTextField.text, !email.isEmpty,
//                  let password = passwordTextField.text, !password.isEmpty
//            else {
//                print("Missing Data")
//                return
//            }
//            AuthManager.shared.signIn(withEmail: email, password: password) {
//                result in switch result {
//                case .success(_):
//                    print("Successfully signed in")
//                case.failure(let error): print("Failed to sign in with email: \(error.localizedDescription)")
//                }
//            }
//        }
//        @objc func handleSignUp() {
//            delegate?.didRequestSignUp()
//        }
//    func presentSignInView() {
//        let signInView = SignInView()
//    
//           
//        
//        let hostingController = UIHostingController(rootView: signInView)
//        present(hostingController, animated: true, completion: nil)
//    }
//        @objc func cancelSignUp() {
//            dismiss(animated: true, completion: nil)
//        }
//    }
