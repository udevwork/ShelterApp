//
//  ResipientProfileView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 19.02.2024.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import AlertToast

class ResidentProfileModel: ObservableObject {

    @Published var user: RemoteUser = RemoteUser()
    @Published var listOfFiles: [StorageReference] = []
    @Published var showPDFViewes: Bool = false
    
    // alerts
    @Published var showLoadingAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    var errorAlertText: String = ""
    
    var pdfUrlToView: URL? = nil
    
    init(user: RemoteUser) {
        self.user = user
    }
    
    init(userID: String) {
        showLoadingAlert = true
        let db = Firestore.firestore()
        let path = db.collection("Users").document(userID)
        path.getDocument { snap, error in
            if let error = error {
                print("Ошибка при получении пользователей: \(error.localizedDescription)")
            } else {
                do {
                    self.user = try snap!.data(as: RemoteUser.self)
                } catch let error {
                    print(error.localizedDescription)
                    try? Auth.auth().signOut()
                }
            }
        }
    }
    
    func saveData() {
        // Получаем ссылку на хранилище Firestore
            let db = Firestore.firestore()
            
            // Ссылка на конкретный документ пользователя по ID
            let id = user.id
            let userRef = db.collection("Users").document(id)
            
            // Создаем словарь из обновленных данных пользователя
            let updatedUserData: [String: Any] = [
                "userName": user.userName            
            ]
            
            // Обновляем данные пользователя
            userRef.updateData(updatedUserData) { error in
                if let error = error {
                    print("Ошибка при обновлении пользователя: \(error.localizedDescription)")
                } else {
                    print("Данные пользователя успешно обновлены")
                }
            }
    }
    
    

    
    func downloadPdf(storageRef: StorageReference) {
        showLoadingAlert = true
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UserEnv.current?.uid ?? "tempfile")

        storageRef.write(toFile: localURL) { url, error in
            if let error = error {
              
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
        let userPdfsRef = storageRef.child("pdfs/\(user.id)/")
        
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
        let path = "pdfs/\(user.id)/\(docName)"
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
    
}

struct ResidentProfileView: View {
    
    @StateObject var model: ResidentProfileModel
    @EnvironmentObject var userEnv: UserEnv
    @State private var isPickerPresented = false
    @State var showAlert: Bool = false


    var body: some View {
        NavigationStack {
            if model.user.id.isEmpty == false {
                List {
                    Section("Person") {
                        HStack {
                            Text("Resident name: ").foregroundColor(Color(UIColor.secondaryLabel))
                            TextField("Name", text: $model.user.userName)
                        }
                     
                        Button {
                            model.saveData()
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            self.showAlert.toggle()
                        } label: {
                            Label("Save", systemImage: "icloud.and.arrow.up")
                        }
                        
                    }
                    
                    Section("Documents") {
                        
                        ForEach(model.listOfFiles, id: \.self) { item in
                            
                            Button {
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                self.model.downloadPdf(storageRef: item)
                            } label: {
                                HStack {
                                    Image(systemName: "doc.fill").foregroundColor(Color(UIColor.secondaryLabel))
                                    Text(item.name).foregroundColor(Color(UIColor.label))
                                }.contextMenu {
                                    Button {
                                        model.deleteFile(docName: item.name)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }

                                }
                            }
                        }
                        
                        Button {
                      
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            isPickerPresented = true
                        } label: {
                            HStack {
                                Label("Upload pdf file", systemImage: "plus.circle.fill")
                            }
                        }
                        
                    }
                    
                    if userEnv.id == model.user.id {
                        Section {
                            Button(action: signOut) {
                                Text("Sign out")
                            }
                        }
                    }
                    
                    UserIDTextView()
                    
                }
                
                .navigationTitle(model.user.userName)
                .onAppear {
                    model.getListOfFiles()
                }
                .sheet(isPresented: $model.showPDFViewes) {
                    if let url = model.pdfUrlToView {
                        PDFViewer(url: url)
                    }
                }
                .refreshable(action: {
                    self.model.getListOfFiles()
                })
                .toast(isPresenting: $model.showLoadingAlert) {
                    AlertToast(type: .loading, title: "Loading")
                }
                .toast(isPresenting: $model.showErrorAlert) {
                    AlertToast(displayMode: .alert, type: .error(.red), title: model.errorAlertText)
                }
                .toast(isPresenting: $showAlert) {
                    AlertToast(displayMode: .alert, type: .complete(.green))
                }
                .sheet(isPresented: $isPickerPresented) {
                    DocumentPickerRepresentable { url in
                        if url.startAccessingSecurityScopedResource() {
                            self.model.showLoadingAlert = true
                            uploadPdf(fileURL: url) { result in
                                switch result {
                                    case .success(let downloadURL):
                                        print("Загруженный URL: \(downloadURL)")
                                        self.model.getListOfFiles()
                                        self.model.showLoadingAlert = false
                                    case .failure(let error):
                                        print("Ошибка загрузки блять: \(error)")
                                        self.model.showLoadingAlert = false
                                        self.model.errorAlertText = error.localizedDescription
                                        self.model.showErrorAlert = true
                                }
                               
                            }
                            url.stopAccessingSecurityScopedResource()
                        } else {
                            self.model.errorAlertText = "Failed"
                            self.model.showErrorAlert = true
                        }
                    }
                }
            }
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        if let user = Auth.auth().currentUser {
            print(user.email!)
            
        } else {
            print("no user")
            
            userEnv.isLogged = false
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
    
    func uploadPdf(fileURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        // Сначала копируем файл в локальную директорию
        
        copyFileToLocalDirectory(fileURL: fileURL) { result in
            switch result {
                case .success(let localURL):

                    let storageRef = Storage.storage().reference()
                    let pdfRef = storageRef.child("pdfs/\(model.user.id)/\(localURL.lastPathComponent)")
                    
                    pdfRef.putFile(from: localURL, metadata: nil) { metadata, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        pdfRef.downloadURL { url, error in
                            if let error = error {
                                completion(.failure(error))
                            } else if let url = url {
                                completion(.success(url))
                            }
                        }
                    }
                    
                    
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
}

//#Preview {
//    ResidentProfileView()
//}
