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
    @EnvironmentObject private var itemManager: ItemManager
    @EnvironmentObject var userAccountModel: UserAccountModel
    
    @State private var name = ""
    @State private var details = ""
    @State private var originalprice = ""
    @State private var value = ""
    @State private var condition = "Good"
    @State private var selectedCategory = CategoryManager.shared.categories.first!.name
        var images: [UIImage]
    @State private var isUploading = false

    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject private var categoryManager = CategoryManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    // Image Scrolling
                    ScrollView(.horizontal) {
                        HStack(spacing: 20) {
                            ForEach(images.indices, id: \.self) { index in
                                ZStack {
                                    Image(uiImage: images[index])
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
                                    .opacity(images.count > 0 ? 1 : 0)
                                }
                                .frame(width: 120, height: 120)
                                
                            }
                            .padding()
                        }
                        Divider()
                        ScrollView {
                            VStack {
                                TextField("Item Name", text: $name, prompt: Text("Item Name").foregroundColor(.black))
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(5)
                                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.orange, lineWidth: 2))
                                    .padding(.top)
                                TextField("Item Details", text: $details, prompt: Text("Item Details").foregroundColor(.black))
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(5)
                                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.orange, lineWidth: 2))
                                    .padding(.top)
                            }
                            Spacer()
                            HStack(spacing: 10) {
                                VStack(alignment: .center) {
                                    Text("Original Price")
                                        .font(.headline)
                                        .padding(.bottom, 2)
                                    TextField("$", text: $originalprice)
                                        .keyboardType(.decimalPad)
                                        .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 30)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(5)
                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.orange, lineWidth: 2))
                                }
                                VStack(alignment: .center) {
                                    Text("Value")
                                        .font(.headline)
                                        .padding(.bottom, 2)
                                    TextField("$", text: $value)
                                        .keyboardType(.decimalPad)
                                        .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: 30)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(5)
                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.orange, lineWidth: 2))
                                }
                            }
                            Spacer()
                            
                            Picker("Condition", selection: $condition) {
                                Text("New").tag("New")
                                Text("Used").tag("Used")
                                Text("Good").tag("Good")
                                Text("Poor").tag("Poor")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding()
                            Spacer()
                            
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categoryManager.categories) { category in
                                    Text(category.name).tag(category.name)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            
                        }
                        
                        .padding(.horizontal)
                    }
                    
                    
                    // Uploaded Item
                    
                    Spacer()
                    Button(action: uploadItem) {
                        Text("Upload Item")
                            .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                            .font(.headline)
                            .padding()
//                            .offset(y: 100)
                    }
                    
                    .disabled(images.isEmpty || isUploading)
                    .padding(.top, 20)
                }
                .padding()
                .navigationTitle("Just Swap")
                
            }
        }
        }
    private mutating func deleteImage(at index: Int) {
        images.remove(at: index)
    }
    private func uploadItem() {
        guard !images.isEmpty, let priceValue = Double(originalprice), let value = Double(value) else { return }
        isUploading = true
        
        let dispatchGroup = DispatchGroup()
        var imageUrls: [String] = []
        var uploadError: Error? = nil
        
        for image in images {
            dispatchGroup.enter()
            ItemManager.shared.uploadItem(userAccountModel: UserAccountModel(), images: [image], name: name, details: details, originalprice: priceValue, value: value, condition: condition, timestamp: Date(), category: selectedCategory) { result in
                switch result {
                case .success:
                    if let imageUrl = imageUrls.first {
                        imageUrls.append(imageUrl)
                    }
                case .failure(let error):
                    uploadError = error
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            isUploading = false
            if let error = uploadError {
                print("Failed to upload item: \(error.localizedDescription)")
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
        
        
    }
}
    
struct PlaceholderTextEditor: ViewModifier {
    let placeholder: String
    @Binding var text: String
    
    func body(content: Content) -> some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
        }
    }
}

#Preview {
    AddItem()
}
