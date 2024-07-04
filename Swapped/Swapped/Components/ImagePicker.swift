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
  
    
    func makeUIViewController(context: Context) ->  PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = selectionLimit
        configuration.filter = .images
        
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
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
    }
}
 
