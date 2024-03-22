//
//  PDFViewer.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 21.02.2024.
//

import SwiftUI
import PDFKit
import UIKit

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {}
}

struct PDFViewerRepresentable: UIViewRepresentable {
    
    var url: URL
    //var doc: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        // Создаем экземпляр PDFView
        let pdfView = PDFView()
        pdfView.autoScales = true // Автоматическое масштабирование для лучшего отображения
        
        // Загружаем PDF-документ
        if let document = PDFDocument(url: self.url) {
            pdfView.document = document
        }
        
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Обновляем документ, если url изменится
        if let document = PDFDocument(url: self.url) {
            
            uiView.document = document
        }
    }
}

struct PDFViewer: View {
    var url: URL
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            PDFViewerRepresentable(url: url)
                .sheet(isPresented: $showingShareSheet, content: {
                    
                    if let document = PDFDocument(url: self.url) {
                        //pdfView.document = document
                        ActivityView(activityItems: [document.dataRepresentation()!], applicationActivities: nil)
                        
                        
                    }
                })
                .edgesIgnoringSafeArea(.all)
            .navigationTitle("document")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                Button(action: {
                    self.showingShareSheet = true
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        
    }
    
}
