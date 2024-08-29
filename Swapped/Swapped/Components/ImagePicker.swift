//
//  ImagePicker.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.
//

import Foundation
import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var images: [UIImage]
    var selectionLimit: Int
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Environment(\.presentationMode) private var presentationMode
    
    
    func makeUIViewController(context: Context) -> UIViewController {
        if sourceType == .camera {
                    return makeUIImagePickerController(context: context)
                } else {
                    return makePHPickerViewController(context: context)
                }
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    private func makePHPickerViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = selectionLimit
        configuration.filter = .images
        
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
        
    }
    
    private func makeUIImagePickerController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
   
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    class Coordinator: NSObject, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            let group = DispatchGroup()
            
            
            var uiImages: [UIImage] = []
            for result in results {
                group.enter()
                let provider = result.itemProvider
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, _ in
                        if let uiImage = image as? UIImage {
                            uiImages.append(uiImage)
                        }
                        group.leave()
                    }
                    
                } else {
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                if self.parent.selectionLimit == 1 {
                    self.parent.image = uiImages.first
                } else {
                    self.parent.images.append(contentsOf: uiImages)
                }
            }
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            if let uiImage = info[.originalImage] as? UIImage {
                if self.parent.selectionLimit == 1 {
                    self.parent.image = uiImage
                } else {
                    self.parent.images.append(uiImage)
                }
            }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
