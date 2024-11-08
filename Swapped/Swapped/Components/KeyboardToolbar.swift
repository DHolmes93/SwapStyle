//
//  KeyboardToolbar.swift
//  Swapped
//
//  Created by Donovan Holmes on 9/12/24.
//

import Foundation
import SwiftUI
import UIKit

struct KeyboardToolbar: UIViewRepresentable {
    var onDone: () -> Void
    var onCancel: () -> Void
    
    func makeUIView(context: Context) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        // Create Done and Cancel buttons
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(context.coordinator.doneTapped))
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: context.coordinator, action: #selector(context.coordinator.cancelTapped))
        
        // Flexible space to push the Done button to the right
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [cancelButton, flexibleSpace, doneButton]
        return toolbar
    }
    
    func updateUIView(_ uiView: UIToolbar, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDone: onDone, onCancel: onCancel)
    }
    
    class Coordinator: NSObject {
        var onDone: () -> Void
        var onCancel: () -> Void
        
        init(onDone: @escaping () -> Void, onCancel: @escaping () -> Void) {
            self.onDone = onDone
            self.onCancel = onCancel
        }
        
        @objc func doneTapped() {
            onDone()
        }
        
        @objc func cancelTapped() {
            onCancel()
        }
    }
}
