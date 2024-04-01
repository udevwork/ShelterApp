//
//  AdministratorProfileView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 21.02.2024.
//

import SwiftUI
import AlertToast
import FirebaseFirestore
import FirebaseAuth

class AdministratorProfileModel: ObservableObject {
    
    // Alerts
    @Published var showAlert: Bool = false
    @Published var showLoadingAlert: Bool = false
    @Published var showErrorAlert: Bool = false
    var errorAlertText: String = ""
    
    @Published var buildingPhotoEnabled: Bool {
        didSet {
            UserDefaults.standard.set(buildingPhotoEnabled, forKey: "buildingPhotoEnabled")
        }
    }
    
    @Published var buildingDitailPhotoEnabled: Bool {
        didSet {
            UserDefaults.standard.set(buildingDitailPhotoEnabled, forKey: "buildingDitailPhotoEnabled")
        }
    }
    
    @Published var userPhotoEnabled: Bool {
        didSet {
            UserDefaults.standard.set(userPhotoEnabled, forKey: "userPhotoEnabled")
        }
    }
    @Published var extremeImageCompressionEnabled: Bool {
        didSet {
            UserDefaults.standard.set(extremeImageCompressionEnabled, forKey: "extremeImageCompressionEnabled")
        }
    }
    
    @Published var germanLanguage: Bool {
        didSet {
            var preferredLanguage = "en"
            if germanLanguage {
                preferredLanguage = "de"
            }
            UserDefaults.standard.set(germanLanguage, forKey: "germanLanguage")
            UserDefaults.standard.set([preferredLanguage], forKey: "AppleLanguages")
        }
    }
    
    init() {
        self.buildingPhotoEnabled = UserDefaults.standard.bool(forKey: "buildingPhotoEnabled")
        self.buildingDitailPhotoEnabled = UserDefaults.standard.bool(forKey: "buildingDitailPhotoEnabled")
        self.userPhotoEnabled = UserDefaults.standard.bool(forKey: "userPhotoEnabled")
        self.germanLanguage = UserDefaults.standard.bool(forKey: "germanLanguage")
        self.extremeImageCompressionEnabled = UserDefaults.standard.bool(forKey: "extremeImageCompressionEnabled")
    }
    
    func saveData(user: UserEnv) {
        let id = user.id
        let userRef = Fire.base.users.document(id)
        let updatedUserData: [String: Any] = ["userName": user.userName]
        Task { try await userRef.updateData(updatedUserData) }
        self.showAlert = true
    }
    
    func updateCredits(user: UserEnv) {
        
        let id = user.id
        let userRef = Fire.base.users.document(id)
    
        guard let email = user.email, let password = user.password else {
            errorAlertText = "Filds cannot be empty"
            showErrorAlert = true
            return
        }
        
        Task {
            try? await userRef.updateData(["email":email, "password": password])
        }
        self.showAlert = true
    }

}

struct AdministratorProfileView: View {
    
    @EnvironmentObject var user: UserEnv
    @StateObject var model: AdministratorProfileModel = AdministratorProfileModel()
    
    var body: some View {
        NavigationStack {
            Form {
                
                Section("Person") {
                    HStack {
                        Text("User").foregroundColor(Color(UIColor.secondaryLabel))
                        TextField("Name", text: $user.userName)
                    }
                  
                    Button {
                        model.saveData(user: user)
                    } label: {
                        Label("Save", systemImage: "icloud.and.arrow.up.fill")
                    }
                }
                
                Section {
                    Toggle(isOn: $model.buildingPhotoEnabled) {
                        Text("Building thumbnails")
                    }
                } footer: {
                    Text("A small image used in the list of buildings")
                }

                Section {
                    Toggle(isOn: $model.buildingDitailPhotoEnabled) {
                        Text("Building ditail photo")
                    }
                } footer: {
                    Text("Large image on the detailed view screen of the building")
                }
                    
                Section {
                    Toggle(isOn: $model.userPhotoEnabled) {
                        Text("User thumbnails")
                    }
                } footer: {
                    Text("A small image used in the list of users")
                }
                
                Section {
                    Toggle(isOn: $model.extremeImageCompressionEnabled) {
                        Text("Extreme image compression")
                    }
                } footer: {
                    Text("Adjusting the compression ratio of images before sending to the server")
                }
                
                
                Section {
                    Toggle(isOn: $model.germanLanguage) {
                        Text("Use German Language")
                    }
                } footer: {
                    Text("REQUIRES A REBOOT OF THE APPLICATION")
                }
                
                
                Section("Login info") {
                    TextInput(text: $user.email ?? "",
                              title: "Email: ",
                              systemImage: "envelope.fill")
                    
                    TextInput(text: $user.password ?? "",
                              title: "Password: ",
                              systemImage: "lock.fill")
                    Button {
                        model.updateCredits(user: user)
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        
                    } label: {
                        Label("Update credits", systemImage: "icloud.and.arrow.up.fill")
                    }
                }
                
                
                Section {
                    Button(action: {
                        user.signout()
                    }) {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.forward")
                    }
                }
                
                
            }.navigationTitle(navTitle())
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
    
    func navTitle() -> String {
        if (user.isAdmin ?? false) {
            return "Administrator"
        }       
        
        if (user.isModerator ?? false) {
            return "Moderator"
        }
        
        
        return "Panel"
    }
}

#Preview {
    AdministratorProfileView()
}
