//
//  PDFCamera.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 22.03.2024.
//

import SwiftUI
import IRLPDFScanContent

struct PDFCamera: View {
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var scanner: IRLPDFScanContent = IRLPDFScanContent()
    @StateObject var documentsViewModel: DocumentsViewModel
    @State var filename: String = ""
    
    var body: some View {
      
            VStack {
                TextInput(text: $filename,
                          title: "File name: ",
                          systemImage: "pencil")
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
               Spacer()
                if let latestScan = scanner.latestScan {
                    latestScan.swiftUIPDFView
                        .cornerRadius(10)
                } else {
                    Text("Press the Scan button")
                }
                Spacer()
            }.padding()
            .navigationTitle("PDF Scan")
            .toolbar {
                Button("Scan", action: {
                    scanner.present(animated: true, completion: nil)
                })
                Button {
                    guard let scanImages = scanner.latestScan else {return}
                    documentsViewModel.showLoadingAlert = true
                    let _ = scanImages.generatePDFDocument(with: filename, pdfView: nil) { doc, url in
                        if let docData = doc.dataRepresentation() {
                            documentsViewModel.uploadPdf(fileData: docData, name: filename)
                            
                        }
                    }
                    dismiss()
                   
                } label: {
                    Text("Upload")
                }
            }
        
    }
}
