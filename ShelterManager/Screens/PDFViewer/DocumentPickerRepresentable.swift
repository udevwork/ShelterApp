//
//  DocumentPickerView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 21.02.2024.
//

import SwiftUI
import UIKit
import FirebaseStorage
import UniformTypeIdentifiers

struct DocumentPickerRepresentable: UIViewControllerRepresentable {
    var completion: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(documentTypes: ["com.adobe.pdf"], in: .open)
        
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
        var parent: DocumentPickerRepresentable

        init(_ documentPicker: DocumentPickerRepresentable) {
            self.parent = documentPicker
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.completion(url)
        }
    }
}

