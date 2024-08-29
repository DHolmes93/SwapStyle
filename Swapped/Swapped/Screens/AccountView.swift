//
//  AccountView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/1/24.
//

import SwiftUI
import PhotosUI

struct AccountView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var itemManager: ItemManager
    @StateObject private var viewModel = UserAccountModel()
    @State private var isImagePickerPresented = false
    @State private var showImageSourceDialog = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary

    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Button(action: {
                    showImageSourceDialog.toggle()
                }) {
                    if let profileImage = viewModel.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                }
                .confirmationDialog("Select Image Source", isPresented: $showImageSourceDialog, titleVisibility: .visible) {
                    Button("Camera") {
                        sourceType = .camera
                        isImagePickerPresented.toggle()
                    }
                    Button("Photo Library") {
                        sourceType = .photoLibrary
                        isImagePickerPresented.toggle()
                    }
                    Button("Cancel", role: .cancel) {}
                    
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(image: $viewModel.profileImage, images: .constant([]), selectionLimit: 1, sourceType: sourceType)
                    
                }
                TextField("Name", text: $viewModel.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                TextField("City", text: $viewModel.city)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                TextField("State", text: $viewModel.state)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                TextField("Zipcode", text: $viewModel.zipcode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                Text("Rating: \(viewModel.rating, specifier: "%.1f")")
                    .padding()
                
                Button(action: {
                    viewModel.saveUserDetails()
                    
                }) {
                    Text("Save")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: {
                    viewModel.signOut()
                }) {
                    Text("Sign Out")
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Divider()
                Text("My Items")
                    .font(.headline)
                List(itemManager.items) { item in
                    Text(item.name)
                }
                .onAppear {
                    itemManager.fetchItems { result in
                        switch result {
                        case .success(let items):
                            itemManager.items = items
                        case .failure(let error):
                            print("Error fetching items: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("User Account")
            .onChange(of: authManager.isSignedIn) { isSignedIn in
                if !isSignedIn {
                    if let window = UIApplication.shared.windows.first {
                        window.rootViewController = UIHostingController(rootView: SignInView()
                        .environmentObject(authManager))
                        
                    }
                }}
        }
    }
    private func makePickerConfiguration(source: UIImagePickerController.SourceType) -> PHPickerConfiguration {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        return config
    }
}

#Preview {
    AccountView()
}
