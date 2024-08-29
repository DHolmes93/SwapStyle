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

    @Environment(\.presentationMode) var presentationMode

    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Button(action: {
                        viewModel.showImageSourceDialog.toggle()
                    }) {
                        Text("Add Item")
                            .foregroundStyle(Color.blue)
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
                    ScrollView(.horizontal) {
                        HStack(spacing: 20) {
                            ForEach(viewModel.images.indices, id: \.self) { index in
                                ZStack {
                                    Image(uiImage: viewModel.images[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 150, height: 150)
                                        .cornerRadius(10)
                                        .padding(.top, 20)
                                    
                                    Button(action: {
                                        viewModel.deleteImage(at: index)
                                        
                                    }) {
                                        Image(systemName: "xmark.circle")
                                            .foregroundColor(.black)
                                            .padding(5)
                                        
                                            .clipShape(Circle())
                                            .offset(x: -50, y: -50)
                                    }
                                    .padding(.trailing, 10)
                                    .opacity(viewModel.images.count > 0 ? 1 : 0)
                                }
                                .frame(width: 120, height: 120)
                            }
                            
                        }
                        
                        .padding()
                        Button(action: {
                            viewModel.showImageSourceDialog.toggle()
                        }) {
                            Image(systemName: "plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .foregroundColor(viewModel.images.count < 5 ? .blue : .clear)
                                .padding(10)
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
                            Button("Cancel", role: .cancel)
                            {}
                        }
                        
                        .sheet(isPresented: $viewModel.isImagePickerPresented) {
                            ImagePicker(image: .constant(nil), images: $viewModel.images, selectionLimit: 5, sourceType: viewModel.sourceType)
                        }
                    }
                    .padding()
                }
                if viewModel.images.count >= 2 {
                    NavigationLink(destination: AddItemDetails(viewModel: viewModel, images: viewModel.images).environmentObject(itemManager).environmentObject(userAccountModel)) {
                        Text("Next")
                            .foregroundStyle(Color.blue)
                            .font(.headline)
                            .padding()
                    }
                } else {
                    Text("Please add at least 2 pictures to continue.")
                        .foregroundStyle(Color.red)
                        .font(.subheadline)
                        .padding()
                }
            }
            .navigationTitle("Add Item")
        }
    }
}

#Preview {
    AddItem()
        .environmentObject(ItemManager.shared)
}
