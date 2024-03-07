//
//  PDFViewer.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 21.02.2024.
//

import SwiftUI
import PDFKit

struct PDFViewerRepresentable: UIViewRepresentable {
    var url: URL

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
    var body: some View {
        PDFViewerRepresentable(url: url).edgesIgnoringSafeArea(.all)
    }
}
