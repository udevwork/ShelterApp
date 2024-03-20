//
//  DocumentsView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 10.03.2024.
//

import SwiftUI
import FirebaseStorage
import Firebase
import AlertToast

class DocumentsViewModel: ObservableObject {
    
    @Published var showLoadingAlert: Bool = false
    @Published var listOfFiles: [StorageReference] = []
    @Published var showPDFViewes: Bool = false
    @Published var showErrorAlert: Bool = false
    var errorAlertText: String = ""
    var pdfUrlToView: URL? = nil
    var id: String
    
    init(id: String) {
        self.id = id
    }
    
    func downloadPdf(storageRef: StorageReference) {
        showLoadingAlert = true
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UserEnv.current?.uid ?? "tempfile")
        
        storageRef.write(toFile: localURL) { url, error in
            if let error = error {
                print(error.localizedDescription)
            } else if let url = url {
                self.showLoadingAlert = false
                self.pdfUrlToView = url
                self.showPDFViewes.toggle()
            }
        }
    }
    
    func getListOfFiles() {
        showLoadingAlert = true
        // Получаем ссылку на хранилище
        let storageRef = Storage.storage().reference()
        
        // Создаем ссылку на директорию, где хранятся PDF-файлы пользователя
        let userPdfsRef = storageRef.child("pdfs/\(id)/")
        
        // Получаем список всех файлов в директории
        userPdfsRef.listAll { (result, error) in
            if let error = error {
                print("Ошибка при получении списка файлов: \(error.localizedDescription)")
                return
            }
            self.listOfFiles.removeAll()
            for item in result!.items {
                self.listOfFiles.append(item)
            }
            self.showLoadingAlert = false
            // Если вам нужно также обработать список поддиректорий, вы можете перебрать result.prefixes
            //for prefix in result!.prefixes {
            //  print("Найдена поддиректория: \(prefix)")
            //}
        }
    }
    
    func deleteFile(docName: String) {
        // Получаем ссылку на Storage
        let storage = Storage.storage()
        
        // Создаем ссылку на файл, который хотим удалить
        let path = "pdfs/\(id)/\(docName)"
        let storageRef = storage.reference(withPath: path)
        
        // Удаляем файл
        storageRef.delete { error in
            if let error = error {
                // Обработка ошибки, если файл не удалось удалить
                print("Error deleting file: \(error.localizedDescription)")
            } else {
                // Файл успешно удален
                print("File successfully deleted")
                self.getListOfFiles()
            }
        }
    }
    
    func copyFileToLocalDirectory(fileURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let fileManager = FileManager.default
        let tempDirURL = fileManager.temporaryDirectory
        let targetURL = tempDirURL.appendingPathComponent(fileURL.lastPathComponent)
        
        do {
            // Если файл уже существует, удаляем его перед копированием
            if fileManager.fileExists(atPath: targetURL.path) {
                try fileManager.removeItem(at: targetURL)
            }
            try fileManager.copyItem(at: fileURL, to: targetURL)
            completion(.success(targetURL))
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func uploadPdf(fileURL: URL) {
        // Сначала копируем файл в локальную директорию
        
        copyFileToLocalDirectory(fileURL: fileURL) { result in
            switch result {
                case .success(let localURL):
                    
                    let storageRef = Storage.storage().reference()
                    let pdfRef = storageRef.child("pdfs/\(self.id)/\(localURL.lastPathComponent)")
                    
                    pdfRef.putFile(from: localURL, metadata: nil) { metadata, error in
                        if let error = error {
                            print("Ошибка загрузки: \(error)")
                            self.showLoadingAlert = false
                            self.errorAlertText = error.localizedDescription
                            self.showErrorAlert = true
                            return
                        }
                        
                        pdfRef.downloadURL { url, error in
                            if let error = error {
                                print("Ошибка загрузки: \(error)")
                                self.showLoadingAlert = false
                                self.errorAlertText = error.localizedDescription
                                self.showErrorAlert = true
                            } else if let url = url {
                                print("Загруженный URL: \(url)")
                                self.getListOfFiles()
                                self.showLoadingAlert = false
                            }
                        }
                    }
                    
                    
                case .failure(let error):
                    print("Ошибка загрузки: \(error)")
                    self.showLoadingAlert = false
                    self.errorAlertText = error.localizedDescription
                    self.showErrorAlert = true
            }
        }
    }
    
}

struct DocumentsView: View {
    
    @StateObject var model: DocumentsViewModel
    @State private var isPickerPresented = false
    var editble: Bool
    
    var body: some View {
        List {
            
            Section("Documents") {
                
                ForEach(model.listOfFiles, id: \.self) { item in
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        self.model.downloadPdf(storageRef: item)
                    } label: {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text(item.name)
                        }.foregroundColor(Color(UIColor.label))
                        .contextMenu {
                            Button {
                                model.deleteFile(docName: item.name)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }.disabled(!editble)
                        }
                    }
                }
            }
            if editble {
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    isPickerPresented = true
                } label: {
                    HStack {
                        Label("Upload pdf file", systemImage: "plus.circle.fill")
                    }
                }
            }
        }.sheet(isPresented: $isPickerPresented) {
            DocumentPickerRepresentable { url in
                if url.startAccessingSecurityScopedResource() {
                    self.model.showLoadingAlert = true
                    model.uploadPdf(fileURL: url)
                    url.stopAccessingSecurityScopedResource()
                } else {
                    self.model.errorAlertText = "Failed"
                    self.model.showErrorAlert = true
                }
            }
        }
        .sheet(isPresented: $model.showPDFViewes) {
            if let url = model.pdfUrlToView {
                PDFViewer(url: url)
            }
        }
        .toast(isPresenting: $model.showLoadingAlert) {
            AlertToast(type: .loading, title: "Loading", subTitle: "PDF file")
        }
        .onAppear {
            model.getListOfFiles()
        }
        .navigationTitle("Documents")
    }
}
