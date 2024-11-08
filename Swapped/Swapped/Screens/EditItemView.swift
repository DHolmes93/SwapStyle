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
    @State private var isDeleteConfirmed = false

    init(item: Item) {
        _item = State(initialValue: item)
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Horizontal ScrollView for Images
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
                                case .failure:
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

                // Form for Item Details
                Form {
                    Section(header: Text("Item Details")) {
                        TextField("Name", text: $item.name)
                            .padding()
                        TextField("Details", text: $item.details)
                            .padding()
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

                        Picker("Category", selection: $item.selectedCategory) {
                            ForEach(categoryManager.categories, id: \.self) { category in
                                Text(category.name).tag(category.name)
                            }
                        }
                        .padding()
                        .cornerRadius(5)
                    }
                }

                // Action Buttons Section
                HStack(spacing: 30) {
                    Button(action: {
                        showDeleteConfirmation()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.red)
                            Text("Delete")
                                .foregroundColor(.red)
                        }
                    }
                    .alert(isPresented: $showAlert) {
                        if isDeleteConfirmed {
                            return Alert(
                                title: Text("Delete Item"),
                                message: Text(alertMessage),
                                primaryButton: .destructive(Text("Delete")) {
                                    confirmDeleteItem()
                                },
                                secondaryButton: .cancel {
                                    isDeleteConfirmed = false
                                }
                            )
                        } else {
                            return Alert(
                                title: Text("Update Item"),
                                message: Text(alertMessage),
                                dismissButton: .default(Text("OK")) {
                                    if alertMessage == "Item updated successfully!" {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            )
                        }
                    }

                    Button(action: {
                        updateItem()
                    }) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.blue)
                            Text("Update")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Edit Item")
        }
    }

    private func showDeleteConfirmation() {
        alertMessage = "Are you sure you want to delete this item?"
        isDeleteConfirmed = true
        showAlert = true
    }

    private func confirmDeleteItem() {
        print("Attempting to delete item with ID: \(item.uid)")

        // Use a Task to handle the async call
        Task {
            do {
                try await itemManager.deleteItem(itemId: item.uid)
                print("Item deleted successfully from Firestore.")
                alertMessage = "Item deleted successfully!"
                // Remove the item from the screen
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Failed to delete item: \(error.localizedDescription)")
                alertMessage = "Failed to delete item: \(error.localizedDescription)"
                showAlert = true
            }
        }

        // Optionally, hide the delete confirmation alert
        isDeleteConfirmed = false
    }

    private func updateItem() {
        print("Attempting to update item with ID: \(item.uid)")

        // Use a Task to handle the async call
        Task {
            do {
                try await itemManager.updateItem(item)
                print("Item updated successfully.")
                alertMessage = "Item updated successfully!"
                showAlert = true
            } catch {
                print("Failed to update item: \(error.localizedDescription)")
                alertMessage = "Failed to update item: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

//#Preview {
//    let mockItem = Item(
//        name: "BoFlex",
//        details: "Sample details",
//        originalprice: 120.0,
//        value: 80,
//        imageUrls: ["https://via.placeholder.com/150", "https://via.placeholder.com/150"],
//        condition: "Good",
//        timestamp: Date(),
//        uid: "45768403j",
//        category: "Sports", subcategory: "Ball",
//        userName: "Flower Pot",
//        latitude: 0.0,
//        longitude: 0.0
//    )
//    let category = CategoryManager.shared
//    let item = ItemManager.shared
//    return EditItemView(item: mockItem)
//        .environmentObject(category)
//        .environmentObject(item)
//}
//
extension NumberFormatter {
    static var currency: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }
}
