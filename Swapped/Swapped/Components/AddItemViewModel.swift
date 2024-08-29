//
//  AddItemViewModel.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/19/24.
//

import Foundation
import SwiftUI

class AddItemViewModel: ObservableObject {
    @Published var images: [UIImage] = []
    @Published var showImageSourceDialog = false
    @Published var isImagePickerPresented = false
    @Published var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func deleteImage(at index: Int) {
        images.remove(at: index)
    }
}
