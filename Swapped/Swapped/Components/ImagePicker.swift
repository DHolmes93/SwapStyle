//
//  ImagePicker.swift
//  Swapped
//
//  Created by Donovan Holmes on 7/2/24.

import SwiftUI
import PhotosUI
import AVFoundation

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var images: [UIImage]
    var selectionLimit: Int
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var buttonColor: UIColor = .systemBlue
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
        configuration.filter = .images // Allow images including Live Photos

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        picker.view.tintColor = buttonColor
        return picker
    }

    private func makeUIImagePickerController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.navigationBar.tintColor = buttonColor
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

                // Load UIImage if available
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, error in
                        if let uiImage = image as? UIImage {
                            uiImages.append(uiImage)
                        } else if let error = error {
                            print("Error loading image: \(error.localizedDescription)")
                        }
                        group.leave()
                    }
                }
                // Load PHAsset if available (for Live Photos)
                else if provider.hasItemConformingToTypeIdentifier("com.apple.live-photo") {
                    // Use the PHAssetIdentifier from the PHPickerResult
                    if let assetIdentifier = result.assetIdentifier {
                        let fetchOptions = PHFetchOptions()
                        fetchOptions.predicate = NSPredicate(format: "localIdentifier = %@", assetIdentifier)
                        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: fetchOptions)

                        if let livePhotoAsset = assets.firstObject {
                            // Load the still image from the Live Photo
                            self.fetchImage(from: livePhotoAsset) { image in
                                if let img = image {
                                    uiImages.append(img)
                                }
                                group.leave()
                            }
                        } else {
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                } else {
                    group.leave() // If neither image nor Live Photo could be loaded
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

        private func fetchImage(from asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
            let imageManager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat
            
            // Fetch the still image for the Live Photo
            imageManager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options) { (image, _) in
                completion(image)
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

