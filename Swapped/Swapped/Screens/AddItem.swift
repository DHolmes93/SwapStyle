//
//  AddItem.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//
import SwiftUI
import PhotosUI

struct AddItem: View {
    @StateObject var viewModel = AddItemViewModel()
    @EnvironmentObject private var itemManager: ItemManager
    @EnvironmentObject private var userAccountModel: UserAccountModel
    @EnvironmentObject private var categoryManager: CategoryManager
    @EnvironmentObject private var authManager: AuthManager

    @Environment(\.presentationMode) var presentationMode

    @State private var selectedCategory: Category?
    @State private var selectedSubcategory: Category?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Check if user profile is complete
                    if !UserAccountModel.shared.isProfileCompleted {
//                        print("Profile completion status updated: \(isProfileCompleted)")
                        Text("Please complete your profile before adding items.")
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding()
                    } else {
                        // Image Picker
                        Button(action: {
                            viewModel.showImageSourceDialog.toggle()
                        }) {
                            Text("Add Photos")
                                .foregroundColor(.black)
                                .font(.headline)
                                .padding()
                        }
                        .confirmationDialog("Select Image Source", isPresented: $viewModel.showImageSourceDialog, titleVisibility: .visible) {
                            Button("Camera") {
                                viewModel.sourceType = .camera
                                viewModel.isImagePickerPresented.toggle()
                            }
                            Button("Photo Library") {
                                viewModel.sourceType = .photoLibrary
                                viewModel.isImagePickerPresented.toggle()
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                        .sheet(isPresented: $viewModel.isImagePickerPresented) {
                            ImagePicker(image: .constant(nil), images: $viewModel.images, selectionLimit: 5, sourceType: viewModel.sourceType)
                        }
                        
                        // Image Scrolling
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(viewModel.images.indices, id: \.self) { index in
                                    ZStack {
                                        Image(uiImage: viewModel.images[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 150, height: 150)
                                            .cornerRadius(10)
                                        
                                        Button(action: {
                                            viewModel.deleteImage(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.black)
                                                .padding(5)
                                        }
                                        .offset(x: -50, y: -50)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Category Picker
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select Item Category").tag(nil as Category?)
                            ForEach(categoryManager.categories, id: \.self) { category in
                                Text(category.name).tag(category as Category?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                        .onChange(of: itemManager.selectedCategory) { newCategory in
                            itemManager.selectedSubcategory = nil
                                                }
                        
                        // Subcategory Picker (only if a category is selected)
                        if let subcategories = selectedCategory?.subcategories, !subcategories.isEmpty {
                            Picker("Subcategory", selection: $selectedSubcategory) {
                                Text("Select Item Subcategory").tag(nil as Category?)
                                ForEach(subcategories, id: \.self) { subcategory in
                                    Text(subcategory.name).tag(subcategory as Category?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal)
                        }
                        
                        // Show 'Next' button if more than 2 images have been selected
                        if viewModel.images.count >= 2 {
                            NavigationLink(destination: AddItemDetails(viewModel: viewModel, images: viewModel.images, selectedCategory: $selectedCategory, selectedSubCategory: $selectedSubcategory)
                                            .environmentObject(itemManager)
                                            .environmentObject(userAccountModel)) {
                                Text("Next")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding()
                        } else {
                            Text("Please add at least 2 pictures to continue.")
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding()
                        }
                    }
                    Spacer()
                }
                .padding()
                .onAppear {
                               Task {
                                   await fetchUserDetails()
               
                                   // Check profile completion status when the view appears
                                   userAccountModel.checkProfileCompletion()
                                   print("Profile completion status updated: \(userAccountModel.isProfileCompleted)")
                               }
                           }
                .navigationTitle("Add Item")
            }
        }
    }
    private func fetchUserDetails() async {
        guard (await authManager.currentUser) != nil else {
               print("No current user found.")
               return
           }
   
           // Fetch user details
           await userAccountModel.fetchUserDetails()
   
           // Check if location permission is granted before requesting
           if LocationManager.shared.authroizationStatus == .notDetermined {
               LocationManager.shared.requestLocationAuthorization()
           }
       }
}

#Preview {
    AddItem()
        .environmentObject(ItemManager.shared)
        .environmentObject(CategoryManager.shared)
        .environmentObject(UserAccountModel.shared) // Add UserAccountModel to preview
}
//struct AddItem: View {
//    @ObservedObject var userAccountModel = UserAccountModel.shared
//    @StateObject var viewModel = AddItemViewModel() // Ensure your view model is also properly managed
//    @ObservedObject var authManager = AuthManager.shared
//
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    
//                    // Check if user profile is complete
//                    if !userAccountModel.isProfileCompleted {
//                        Text("Please complete your profile before adding items.")
//                            .foregroundColor(.red)
//                            .font(.subheadline)
//                            .padding()
//                    } else {
//                        // Image Picker
//                        Button(action: {
//                            viewModel.showImageSourceDialog.toggle()
//                        }) {
//                            Text("Add Photos")
//                                .foregroundColor(.black)
//                                .font(.headline)
//                                .padding()
//                        }
//                        .confirmationDialog("Select Image Source", isPresented: $viewModel.showImageSourceDialog, titleVisibility: .visible) {
//                            Button("Camera") {
//                                viewModel.sourceType = .camera
//                                viewModel.isImagePickerPresented.toggle()
//                            }
//                            Button("Photo Library") {
//                                viewModel.sourceType = .photoLibrary
//                                viewModel.isImagePickerPresented.toggle()
//                            }
//                            Button("Cancel", role: .cancel) {}
//                        }
//                        .sheet(isPresented: $viewModel.isImagePickerPresented) {
//                            ImagePicker(image: .constant(nil), images: $viewModel.images, selectionLimit: 5, sourceType: viewModel.sourceType)
//                        }
//                    }
//                }
//                .padding()
//            }
//
//            .navigationTitle("Add Item")
//        }
//    }
//
//}
