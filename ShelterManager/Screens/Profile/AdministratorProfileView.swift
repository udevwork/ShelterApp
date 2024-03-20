//
//  AdministratorProfileView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 21.02.2024.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class AdministratorProfileModel: ObservableObject {
    
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
            var preferredLanguage = "en" // Замените "fr" на код языка, который вы хотите использовать
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
        let id = UserEnv.current?.uid ?? ""
        let userRef = Fire.base.users.document(id)
        let updatedUserData: [String: Any] = ["userName": user.userName]
        Task { try await userRef.updateData(updatedUserData) }
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
                
                Section {
                    Button(action: signOut) {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.forward")
                    }
                }
                            
                
            }.navigationTitle("Administrator")
             
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        if let user = Auth.auth().currentUser {
            print(user.email!)
         
        } else {
            print("no user")
            
            user.isLogged = false
        }
    }
    
}

#Preview {
    AdministratorProfileView()
}
