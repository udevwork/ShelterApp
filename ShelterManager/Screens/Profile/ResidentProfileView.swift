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
    
    @Published var user: Remote.User = .init()
    var backupUser: Remote.User = .init()
    @Published var originalUser: Remote.User? = nil
    
    @Published var livingSpace: Remote.LivingSpace? = nil
    @Published var address: Remote.Address? = nil
    
    @Published var avatarUrl: URL? = nil
    
    // alerts
    @Published var showAlert: Bool = false
    @Published var showLoadingAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    var errorAlertText: String = ""
    
    @Published var fullSizeImage: URL? = nil
    @Published var isShowingFullScreen = false
    var photoManager: PhotoUploaderManager
    
    // if loading from users list
    init(user: Remote.User) {
        print("FETCH USER: \(user.userName)")
        self.originalUser = user
        self.user = user.copy()
        self.backupUser = user.copy()
        photoManager = PhotoUploaderManager(id: user.id)
        fetchLinkedUserDate()
    }
    
    // if logged as regular user
    init(userID: String) {
        showLoadingAlert = true
        
        var _id: String = userID
        // Проверяем, есть ли постфикс '-user'
        if userID.hasSuffix("-user") {
            // Удаляем постфикс '-user'
            _id = userID.replacingOccurrences(of: "-user", with: "")

        }
        
        photoManager = PhotoUploaderManager(id: _id)
        let path = Fire.base.users.document(_id)
        
        Task {
            do {
                let doc = try await path.getDocument()
                self.user = try doc.decode()
                self.backupUser = self.user.copy()
                self.fetchLinkedUserDate()
            } catch let error {
                print(error.localizedDescription)
                self.showLoadingAlert = false
                self.errorAlertText = error.localizedDescription
                self.showErrorAlert = true
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
        
        if let orig = originalUser {
            orig.userName = user.userName
        }
        
        let id = user.id
        let userRef = Fire.base.users.document(id)
        
        let data = user.toDictionary()
        
        Task {
            
            if backupUser.userName != (user.userName ?? "") {
                if await user.userName.isUniqUsername() == false {
                    self.errorAlertText = "Name invalid!"
                    self.showErrorAlert = true
                    return
                }
            }
            
            try? await userRef.setData(data)
            self.showAlert = true
        }
       
    }
    
    func updateCredits() {
        Task {
            if (user.email ?? "").isValidEmail() == false {
                self.errorAlertText = "invalid email"
                self.showErrorAlert = true
                self.showAlert = false
                return
            }
            
            if (user.password ?? "").isValidPassword() == false  {
                self.errorAlertText = "invalid password"
                self.showErrorAlert = true
                self.showAlert = false
                return
            }
            
            if backupUser.email != (user.email ?? "") {
                if await (user.email ?? "").isUniqEmail() == false {
                    self.errorAlertText = "Email is already taken!"
                    self.showErrorAlert = true
                    self.showAlert = false
                    return
                }
            }
            
            
            let id = user.id
            let userRef = Fire.base.users.document(id)
            
            guard let email = user.email, let password = user.password else {
                errorAlertText = "Filds cannot be empty"
                showErrorAlert = true
                return
            }
            
            
            try? await userRef.updateData(["email":email, "password": password])
        }
        showAlert.toggle()
        
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
        if avatarUrl != nil {
            return
        }
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
    
    
    @State private var avatarItem: PhotosPickerItem?
    
    //@Binding var user: Remote.User
    
    var editble: Bool
    
    var body: some View {
        
    
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
                    
                    
                    
//                      Text("Date is \(birthDate.formatted(date: .long, time: .omitted))")
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
                    
                    if (userEnv.isAdmin ?? false) || (userEnv.isModerator ?? false) {
                        Toggle(isOn: $model.user.isAdmin ?? false, label:  {
                            Label("Administrator", systemImage: "exclamationmark.circle.fill")
                        }).disabled((userEnv.isAdmin ?? false) == false)
                        Toggle(isOn: $model.user.isModerator ?? false, label:  {
                            Label("Moderator", systemImage: "exclamationmark.circle.fill")
                        }).disabled((userEnv.isAdmin ?? false) == false)
                    }
                    
                    if editble {
                        Button {
                            model.saveData()
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        } label: {
                            Label("Save", systemImage: "icloud.and.arrow.up.fill")
                        }
                    }
                }
                
                Section("Files") {
                    
                    NavigationLink {
                        DocumentsView(model: .init(id: model.user.id),
                                      editble: (userEnv.isAdmin ?? false) || (model.user.id == userEnv.id) )
                    } label: {
                        Label("Documents", systemImage: "doc.on.doc.fill")
                    }.foregroundColor(Color(UIColor.label))
                    
                }
                
                
                if  (userEnv.isAdmin ?? false) ||  (userEnv.isModerator ?? false) {
                    Section("Administration notes") {
                        NavigationLink {
                            UserNotesView(model: .init(id: model.user.id, type: .admin, authorName: userEnv.userName),
                                          editble:  (userEnv.isAdmin ?? false))
                        } label: {
                            Label("Annotations", systemImage: "pencil.and.list.clipboard")
                        }.foregroundColor(Color(UIColor.label))
                    }
                }
                
                Section("User notes") {
                    NavigationLink {
                        UserNotesView(model: .init(id: model.user.id, type: .user, authorName: model.user.userName),
                                      editble: (userEnv.isAdmin ?? false) || (model.user.id == userEnv.id) )
                    } label: {
                        Label("Notes", systemImage: "note.text")
                    }.foregroundColor(Color(UIColor.label))
                }
                
                
                if editble {
                    Section("Login info") {
                        TextInput(text: $model.user.email ?? "",
                                  title: "Email: ",
                                  systemImage: "envelope.fill")
                        
                        TextInput(text: $model.user.password ?? "",
                                  title: "Password: ",
                                  systemImage: "lock.fill")
                        Button {
                            model.updateCredits()
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            
                        } label: {
                            Label("Update credits", systemImage: "icloud.and.arrow.up.fill")
                        }
                    }
                }
                
                
                if userEnv.id == model.user.id {
                    Section {
                        Button {
                            userEnv.signout()
                        } label: {
                            Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right.fill")
                        }
                    }
                }
                
            }
            
            .navigationTitle("Profile")
            .toolbar(content: {
                PhotosPicker("Change avatar", selection: $avatarItem, matching: .images)
                .disabled(!editble)
                    .onChange(of: avatarItem)  {
                        Task {
                            if let loaded = try? await avatarItem?.loadTransferable(type: Data.self) {
                                let cont = Image(uiImage: UIImage(data: loaded)!)
                                let renderer = ImageRenderer(content: cont)
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
            })
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
            .toast(isPresenting: $model.showAlert) {
                AlertToast(displayMode: .alert, type: .complete(.green))
            }
            
            
      
        
    }
    
    
    
}
