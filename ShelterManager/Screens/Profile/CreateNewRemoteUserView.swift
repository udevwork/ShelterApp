//
//  CreateNewRemoteUserView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 25.02.2024.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import AlertToast

struct CreateNewRemoteUserView: View {
    
    @EnvironmentObject var user: UserEnv
    
    @State var email = ""
    @State var password = ""
    
    @State var alertText = ""
    @State var toast = false
    
    var body: some View {
        NavigationStack {
            List {
                
                Section {
                    HStack {
                        Image(systemName: "envelope.fill")
                        TextField("Email", text: $email)
                    }
                    HStack {
                        Image(systemName: "lock.fill")
                        SecureField("Password", text: $password)
                    }
                } footer: {
                    Text("Account credentials")
                }
                
                
                Section {
                    Button(action: create) {
                        Label("Create account", systemImage: "person.crop.circle.badge.plus.fill")
                    }
                }
                
            }.navigationTitle("Create account")
        }
        .toast(isPresenting: $toast) {
            AlertToast(displayMode: .alert, type: .regular, title: self.alertText)
        }
    }

    func create() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            if error != nil {
                print(error?.localizedDescription ?? "")
            } else {
                
                let db = Firestore.firestore()
                let customDocumentID = result?.user.uid ?? "nouuidfromuser"
                let documentReference = db.collection("Users").document(customDocumentID)

                documentReference.setData([
                    "id": result?.user.uid ?? "",
                    "userName": "New",
                    "admin": false
                ]) { err in
                    if let err = err {
                        print("Ошибка при добавлении документа: \(err)")
                        self.alertText = "Error"
                        self.toast.toggle()
                    } else {
                        loginBack()
                        print("Документ успешно добавлен с кастомным ID: \(customDocumentID)")
                        
                
                    }
                }
            }
        }
    }
    
    func loginBack() {
        let defaults = UserDefaults.standard
        let email = defaults.string(forKey: "lastEmail") ?? ""
        let password = defaults.string(forKey: "lastPassword") ?? ""
        print(email, password, "Logged ad admin back")
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            if error != nil {
                print(error?.localizedDescription ?? "")
                self.alertText = error?.localizedDescription ?? ""
                self.toast.toggle()
            } else {
                print("success")
                self.alertText = "Success"
                self.toast.toggle()
                user.isLogged = true
            }
        }
    }
}

#Preview {
    SignInView()
}
