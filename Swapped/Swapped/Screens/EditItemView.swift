//
//  EditItemView.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/13/24.
//

import SwiftUI
import FirebaseFirestore
import SDWebImageSwiftUI

struct EditItemView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var itemManager: ItemManager
    @EnvironmentObject private var categoryManager: CategoryManager
    @State private var item: Item
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(item: Item) {
        _item = State(initialValue: item)
    }
    var body: some View {
        NavigationStack {
            VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(item.imageUrls.indices, id: \.self) { index in
                            AsyncImage(url: URL(string: item.imageUrls[index])) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 250)
                                        .cornerRadius(10)
                                case.failure:
                                    Text("Failed to load")
                                        .foregroundStyle(Color.red)
                                @unknown default:
                                    EmptyView()
                                }
                                
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                }
                .padding(.top)
                Divider()
                    .padding(.vertical)
                Form {
                    VStack {
                        Section(header: Text("Item Details")) {
                            TextField("Name", text: $item.name)
                            TextField("Details", text: $item.details)
                            TextField("Original Price", value: $item.originalprice, formatter: NumberFormatter.currency)
                                .keyboardType(.decimalPad)
                                .padding()
                            TextField("Value", value: $item.value, formatter: NumberFormatter.currency)
                                .keyboardType(.decimalPad)
                                .padding()
                            
                            Picker("Condition", selection: $item.condition) {
                                Text("New").tag("New")
                                Text("Used").tag("Used")
                                Text("Good").tag("Good")
                                Text("Poor").tag("Poor")
                            }
                            
                            Picker("Category", selection: $item.category) {
                                ForEach(categoryManager.categories, id: \.self) { category in
                                    Text(category.name).tag(category.name)
                                }
                            }
                            .padding()
                            .cornerRadius(5)
                        }
                        .padding(.horizontal)
                        Button("Update Item") {
                            itemManager.updateItem(item) { result in
                                switch result {
                                case .success:
                                    alertMessage = "Item updated successfully!"
                                    showAlert = true
                                case .failure(let error):
                                    alertMessage = "Failed to update item: \(error.localizedDescription)"
                                    showAlert = true
                                }
                            }
                        }
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("Update Item"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                                if alertMessage == "Item updated successfully!" {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            })
                        }
                        .padding(.top)
                    }
                    .navigationTitle("Edit Item")
                }
            }
        }
    }
}


#Preview {
    let mockItem = Item(
                name: "BoFlex",
                details: "Sample details",
                originalprice: 120.0,
                value:80,
                imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
                condition: "Good",
                timestamp: Date(),
                uid: "45768403j",
                category: "Sports"
            )
    let category = CategoryManager.shared
    let item = ItemManager.shared
    return EditItemView(item: mockItem)
        .environmentObject(category)
        .environmentObject(item)
    
}

    extension NumberFormatter {
        static var currency: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            return formatter
        }
    }
