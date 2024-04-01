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
    @State var name = ""
    
    @State var alertText = ""
    @State var toast = false
    
    @State var showUserEditor: Bool? = nil
    @State var newUser: Remote.User? = nil
    
    @State var isLoading: Bool = false
    
    var onUserCreate: (Remote.User)->()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "pencil.line")
                        TextField("Name", text: $name)
                    }
                    HStack {
                        Image(systemName: "envelope.fill")
                        TextField("Email", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    HStack {
                        Image(systemName: "lock.fill")
                        TextField("Password", text: $password)
                    }
                } footer: {
                    Text("Account credentials")
                }

                Section {
                    if isLoading == false {
                        Button(action: {
                            Task {
                                await self.create()
                            }
                        }) {
                            Label("Create account", systemImage: "person.crop.circle.badge.plus.fill")
                        }
                    } else {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
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
            AlertToast(displayMode: .alert, type: .error(.red), title: self.alertText)
        }
    }

 
    func create() async {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        isLoading = true
        
        if email.isValidEmail() == false {
            self.alertText = "invalid email"
            self.toast = true
            self.isLoading = false
            return
        }
        
        if password.isValidPassword() == false  {
            self.alertText = "invalid password"
            self.toast = true
            self.isLoading = false
            return
        }
        
        if name.isValidName() == false  {
            self.alertText = "invalid name"
            self.toast = true
            self.isLoading = false
            return
        }
        
        if await name.isUniqUsername() == false {
            self.alertText = "User is already created!"
            self.toast = true
            self.isLoading = false
            return
        }
        
        if await email.isUniqEmail() == false {
            self.alertText = "Email is already taken!"
            self.toast = true
            self.isLoading = false
            return
        }
        
        let newUser = Remote.User()
        newUser.isAdmin = false
        newUser.userName = name
        newUser.email = email
        newUser.password = password
        
        let documentReference = Fire.base.users.document(newUser.id)
        do {
            try await documentReference.setData(newUser.toDictionary())
            self.isLoading = false
            print("Документ успешно добавлен с кастомным ID: \(newUser.id)")
            self.newUser = newUser
            onUserCreate(newUser)
            self.showUserEditor = true
        } catch let err {
            self.isLoading = false
            print("Ошибка при добавлении документа: \(err.localizedDescription)")
            self.alertText = "Error"
            self.toast.toggle()
        }
    }
}

#Preview {
    SignInView()
}
