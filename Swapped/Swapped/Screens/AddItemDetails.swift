//
//  AddItemDetails.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/19/24.
//

import SwiftUI
import PhotosUI

struct AddItemDetails: View {
    @ObservedObject var viewModel: AddItemViewModel
    @ObservedObject private var categoryManager = CategoryManager.shared
    @EnvironmentObject private var itemManager: ItemManager
    @EnvironmentObject var userAccountModel: UserAccountModel
    
    @State private var name = ""
    @State private var details = ""
    @State private var originalprice = ""
    @State private var value = ""
    @State private var condition = "Good"
//    @State private var selectedCategory: Category? = CategoryManager.shared.categories.first
//    @State private var selectedSubCategory: Category?
    var images: [UIImage]
    @State private var isUploading = false
    @State private var showDollarSign = false  // Toggle dollar sign visibility
    @State private var showSuccessAlert = false // State for success alert
    
    @Binding var selectedCategory: Category?
    @Binding var selectedSubCategory: Category?
    
    @Environment(\.presentationMode) var presentationMode
    
    @FocusState private var isFocusedOriginalPrice: Bool
    @FocusState private var isFocusedValue: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                // Top Title
                Text("Add New Item")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                // Image Scrolling Section
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(images.indices, id: \.self) { index in
                            ZStack {
                                Image(uiImage: images[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150, height: 150)
                                    .cornerRadius(10)
                                    .padding(.top, 20)
                                
                                // Delete Image Button
                                Button(action: {
                                    viewModel.deleteImage(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.7)))
                                        .offset(x: -50, y: -50)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .frame(height: 180)
                
                Divider().padding(.horizontal)
                
                // TextFields for Item Details
                VStack(spacing: 15) {
                    // Item Name
                    CustomTextField(placeholder: "Item Name", text: $name)
                    
                    // Item Details
                    CustomTextField(placeholder: "Item Details", text: $details)
                    
                    // Price and Value Section
                    HStack(spacing: 20) {
                        CustomTextFieldWithDollarSign(
                            placeholder: "Original Price",
                            text: $originalprice,
                            isFocused: $isFocusedOriginalPrice)
                        CustomTextFieldWithDollarSign(
                            placeholder: "Value",
                            text: $value,
                            isFocused: $isFocusedValue)
                        
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            HStack {
                                Button("Cancel") {
                                    isFocusedOriginalPrice = false
                                    isFocusedValue = false
                                    originalprice = ""  // Optionally clear text for both fields
                                    value = ""
                                }
                                Button("Done") {
                                    isFocusedOriginalPrice = false
                                    isFocusedValue = false
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Condition Picker
                Picker("Condition", selection: $condition) {
                    Text("New").tag("New")
                    Text("Used").tag("Used")
                    Text("Good").tag("Good")
                    Text("Poor").tag("Poor")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Upload Button
                Button(action: uploadItem) {
                    Text(isUploading ? "Uploading..." : "Upload Item")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(images.isEmpty || selectedCategory == nil || selectedSubCategory == nil || isUploading ? Color.gray : Color.blue)
                        .cornerRadius(10)
                        .padding(.top, 10)
                        .padding(.horizontal)
                }
                .disabled(images.isEmpty || selectedCategory == nil || selectedSubCategory == nil || isUploading)
                
                Spacer()
            }
            .navigationTitle("Just Swap")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
            .alert("Item Successfully Uploaded!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private mutating func deleteImage(at index: Int) {
        images.remove(at: index)
    }
    
    private func uploadItem() {
        guard !isUploading else { return } // Ensure upload doesn't start twice
        guard !images.isEmpty, let priceValue = Double(originalprice), let value = Double(value) else { return }
        guard let selectedCategoryName = selectedCategory?.name,
              let selectedSubCategoryName = selectedSubCategory?.name else {
            print("Category or SubCategory not selected")
            return
        }

        // Fetch user details to ensure userName is available
        Task {
            do {
                // Fetch user details before uploading
                try await userAccountModel.fetchUserDetails()
                
                isUploading = true
                
                // Call the new async uploadItem method
                try await ItemManager.shared.uploadItem(
                    userAccountModel: userAccountModel,
                    images: images,
                    name: name,
                    details: details,
                    originalprice: priceValue,
                    value: value,
                    condition: condition,
                    timestamp: Date(),
                    selectedCategory: selectedCategoryName,
                    selectedSubCategory: selectedSubCategoryName
                )
                
                // Dismiss the view and show success alert
                presentationMode.wrappedValue.dismiss()
                showSuccessAlert = true
            } catch {
                print("Failed to upload item: \(error.localizedDescription)")
            }
            isUploading = false
        }
    }

}

// Custom TextField with Dollar Sign
struct CustomTextFieldWithDollarSign: View {
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool  // Binding to focus

    var body: some View {
        ZStack(alignment: .leading) {
            Text("$")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.leading, 5)
                .opacity(text.isEmpty ? 0.3 : 1)  // Adjust opacity based on text
            
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .padding(.leading, 20)  // Padding to avoid overlapping the dollar sign
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 2)
                )
                .focused($isFocused)  // Handle focus
        }
        .padding(.horizontal)
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 2)
            )
            .padding(.horizontal)
    }
}
//#Preview {
//    AddItemDetails(viewModel: AddItemViewModel(), images: [])
//}
