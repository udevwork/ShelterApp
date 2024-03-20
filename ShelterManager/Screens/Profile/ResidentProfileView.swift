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
import PhotosUI
import UIKit
import Kingfisher

class ResidentProfileModel: ObservableObject {
    
    @Published var user: Remote.User = Remote.User()
    
    @Published var livingSpace: Remote.LivingSpace? = nil
    @Published var address: Remote.Address? = nil
    
    @Published var avatarUrl: URL? = nil
    
    // alerts
    @Published var showLoadingAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    var errorAlertText: String = ""
    
    @Published var fullSizeImage: URL? = nil
    @Published var isShowingFullScreen = false
    var photoManager: PhotoUploaderManager
    
    init(user: Remote.User) {
        self.user = user
        photoManager = PhotoUploaderManager(id: user.id)
        fetchLinkedUserDate()
    }
    
    init(userID: String) {
        showLoadingAlert = true
        photoManager = PhotoUploaderManager(id: userID)
        let path = Fire.base.users.document(userID)
        path.getDocument { snap, error in
            if let error = error {
                print("Ошибка при получении пользователей: \(error.localizedDescription)")
            } else {
                do {
                    if let snap = snap {
                        self.user = try snap.decode()
                        self.fetchLinkedUserDate()
                    } else {
                        try? Auth.auth().signOut()
                    }
                } catch let error {
                    print(error.localizedDescription)
                    try? Auth.auth().signOut()
                }
            }
        }
       
    }
    
    func fetchLinkedUserDate() {
        Task {
            if let id = user.linkedLivingspaceID, id.isEmpty == false {
                let ref = Fire.base.livingSpaces.document(id)
                if let doc = try? await ref.getDocument() {
                    livingSpace = try doc.decode()
                }
            }
            
            if let id = user.linkedAddressID, id.isEmpty == false {
                let ref = Fire.base.addresses.document(id)
                
                if let doc = try? await ref.getDocument() {
                    address = try doc.decode()
                    
                }
            }
            DispatchQueue.main.async {
                self.showLoadingAlert = false
            }
        }
    }
    
    func saveData() {
        
        let id = user.id
        let userRef = Fire.base.users.document(id)
        
        let data = user.toDictionary()
        
        Task {
            try? await userRef.setData(data)
        }
        
    }
    
  
    func signOut(completion: ()->()) {
        try? Auth.auth().signOut()
        if let user = Auth.auth().currentUser {
            print(user.email!)
        } else {
            print("no user")
            completion()
        }
    }
    
 
    func uploadImage(imageData: Data) {
        self.showLoadingAlert = true
        Task {
            self.avatarUrl = try await photoManager.uploadAvatar(imageData: imageData)
            self.fullSizeImage = nil
            self.showLoadingAlert = false
        }
    }
    
    func getThumbnaliAvatarUrl() {
        Task {
            self.avatarUrl = try await photoManager.loadAvatar()
        }        
    }
    
    func getFullAvatarUrlFrom() {
        if fullSizeImage != nil {
            self.isShowingFullScreen = true
            return
        }
        if let url = avatarUrl {
            self.showLoadingAlert = true
            Task {
                self.avatarUrl = try await photoManager.getFullAvatarUrlFrom(url: url)
                self.fullSizeImage = self.avatarUrl
                self.showLoadingAlert = false
                self.isShowingFullScreen = true
            }
        }
    }
    
  
}

struct ResidentProfileView: View {
    
    @StateObject var model: ResidentProfileModel
    @EnvironmentObject var userEnv: UserEnv
    @State private var isPickerPresented = false
    @State var showAlert: Bool = false
    
    @State private var avatarItem: PhotosPickerItem?
    
    var editble: Bool
    
    var body: some View {

        if model.user.id.isEmpty == false {
            List {
                HStack(alignment: .center) {
                    Spacer()
                    HStack (alignment: .center, spacing: 20) {
                        
                        KFImage.url(model.avatarUrl)
                            .placeholder({ Image("default-avatar") })
                            .loadDiskFileSynchronously()
                            .cacheMemoryOnly()
                            .fade(duration: 0.25)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .cornerRadius(50)
                            .onTapGesture {
                                self.model.getFullAvatarUrlFrom()
                            }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(model.user.userName).font(.title3).bold()
                            Text(model.user.id)
                                .multilineTextAlignment(.leading)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.gray)
                        }
                    }
                    Spacer()
                }.listRowBackground(Color.clear)
                
                Section("Address") {
                    VStack(alignment: .leading, spacing: 12) {
                        AddressListItemView(address: model.address)
                        LivingSpaceListItem(livingSpace: model.livingSpace)
                    }
                }
                
                Section("Person") {
                    
                    TextInput(text: $model.user.userName,
                              title: "Name: ",
                              systemImage: "pencil").disabled(!editble)
                   
                    
                    TextInput(text: $model.user.socialSecurityNumber,
                              title: "Security №: ",
                              systemImage: "exclamationmark.shield.fill").disabled(!editble)
          
                    TextInput(text: $model.user.mobilePhone,
                              title: "Phone: ",
                              systemImage: "phone.fill").disabled(!editble)
                    
                    
                    
                    //  Text("Date is \(birthDate.formatted(date: .long, time: .omitted))")
                    if editble {
                        HStack {
                            Image(systemName: "birthday.cake.fill")
                            DatePicker(selection: $model.user.dateOfBirth, in: ...Date.now, displayedComponents: .date) {
                                Text("Birthday")
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "birthday.cake.fill")
                            Text("Birthday is \(model.user.dateOfBirth.formatted(date: .long, time: .omitted))")
                           
                        }
                    }
                    
                    if editble {
                        Button {
                            model.saveData()
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            self.showAlert.toggle()
                        } label: {
                            Label("Save", systemImage: "icloud.and.arrow.up.fill")
                        }
                    }
                }
                if editble {
                    Section("Files") {
                        NavigationLink {
                            DocumentsView(model: .init(id: model.user.id), editble: editble)
                        } label: {
                            Label("Documents", systemImage: "doc.on.doc.fill")
                        }.foregroundColor(Color(UIColor.label))
                        
                        NavigationLink {
                            UserNotesView(model: .init(id: model.user.id), editble: editble)
                        } label: {
                            Label("Notes", systemImage: "note.text")
                        }.foregroundColor(Color(UIColor.label))
                    }
                }
                
                if editble {
                    Section("Login info") {
                        TextInput(text: model.user.email,
                                  title: "Email: ",
                                  systemImage: "envelope.fill")
                        
                        TextInput(text: model.user.password,
                                  title: "Password: ",
                                  systemImage: "lock.fill")
                    }
                }
                
                Section() {
                    PhotosPicker("Change avatar", selection: $avatarItem, matching: .images)
                        //.disabled(!editble)
                        .onChange(of: avatarItem)  {
                            Task {
                                if let loaded = try? await avatarItem?.loadTransferable(type: Image.self) {
                                    let renderer = ImageRenderer(content: loaded)
                                    let compression = UserDefaults.standard.bool(forKey: "extremeImageCompressionEnabled") ? 0.0 : 0.7
                                    if let data = renderer.uiImage?.jpegData(compressionQuality: compression) {
                                        model.uploadImage(imageData: data)
                                    } else {
                                        print("Failed 1")
                                    }
                                } else {
                                    print("Failed 2")
                                }
                            }
                        }
                }
                
                if userEnv.id == model.user.id {
                    Section {
                        Button {
                            model.signOut {
                                userEnv.isLogged = false
                            }
                        } label: {
                            Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right.fill")
                        }
                    }
                }
                
            }
            
            .navigationTitle("Profile")
            .onAppear {
                model.getThumbnaliAvatarUrl()
            }
            .sheet(isPresented: $model.isShowingFullScreen) {
                VStack {
                    if let url = model.fullSizeImage {
                        FullScreenImageView(url: url)
                    } else {
                        Text("invalid url")
                    }
                }
            }
            .refreshable(action: {
                self.model.fetchLinkedUserDate()
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
            
        }
        
    }
    
    
    
}
//
//#Preview {
//    ResidentProfileView(model: .init(user: Remote.User.init(id: "", userName: "Denis Kotelnikov")))
//}
