//
//  AddItem.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import SwiftUI

struct AddItem: View {
    @State private var name = ""
    @State private var details = ""
    @State private var price = ""
    @State private var condition = "Good"
    @State private var description = ""
    @State private var showImagePicker = false
    @State private var image: UIImage?
    
    @State private var isUploading = false
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationStack {
        ScrollView {
            VStack {
                TextField("Item Name", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.orange, lineWidth: 2))
                    .padding(.top)
                TextField("Item Details", text: $details)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.orange, lineWidth: 2))
                    .padding(.top)
                TextField("Price", text: $price)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.orange, lineWidth: 2))
                
                Picker("Condition", selection: $condition) {
                    Text("Great").tag("Great")
                    Text("Good").tag("Good")
                    Text("Poor").tag("Poor")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                TextField("Description", text: $description)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.orange, lineWidth: 2))
                
                Button(action: {
                    showImagePicker = true
                }) {
                    Text("Select Image")
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        .padding()
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $image)
                }
                .padding(.top, 20)
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding(.top, 20)
                }
                Button(action: {
                    guard let image =
                            image, let priceValue = Double(price) else { return }
                    isUploading = true
                    
                    ItemManager.shared.uploadItem(image: image, name: name, details: details, price: priceValue, condition: condition, description: description, timestamp: Date()) { result in
                        isUploading = false
                        switch result {
                        case .success: presentationMode.wrappedValue.dismiss()
                        case .failure(let error):
                            print("Failed to upload item: (error.localizedDescription)")
                        }
                    }
                }) {
                    Text("Upload Item")
                        .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        .padding()
                    
                }
                .disabled(isUploading)
                
                
            }
        }
            .padding()
            .navigationTitle("Swapped")
            
        }
      
    }
}

#Preview {
    AddItem()
}
