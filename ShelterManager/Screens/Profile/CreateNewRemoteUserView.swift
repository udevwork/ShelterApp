//
//  CreateNewRemoteUserView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 25.02.2024.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseFirestore
import AlertToast

struct CreateNewRemoteUserView: View {
    
    @EnvironmentObject var user: UserEnv
    
    @State var email = ""
    @State var password = ""
    
    @State var alertText = ""
    @State var toast = false
    
    @State var showUserEditor: Bool? = nil
    @State var newUser: Remote.User? = nil
    
    var onUserCreate: (Remote.User)->()
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "envelope.fill")
                        TextField("Email", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
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
            }
            .navigationTitle("Create account")
            .navigationDestination(item: $showUserEditor) { h in
                if let user = self.newUser {
                    ResidentProfileView(model: .init(user: user), editble: true)
                }
            }
        }
        .toast(isPresenting: $toast) {
            AlertToast(displayMode: .alert, type: .regular, title: self.alertText)
        }
    }

    func create() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        let newUser = Remote.User()
        newUser.isAdmin = false
        newUser.userName = "New user"
        newUser.email = email
        newUser.password = password
        
        let documentReference = Fire.base.users.document(newUser.id)
        
        documentReference.setData(newUser.toDictionary()) { err in
            if let err = err {
                print("Ошибка при добавлении документа: \(err)")
                self.alertText = "Error"
                self.toast.toggle()
            } else {
                self.newUser = newUser
                onUserCreate(newUser)
                print("Документ успешно добавлен с кастомным ID: \(newUser.id)")
            }
        }
        
    }

}

#Preview {
    SignInView()
}
