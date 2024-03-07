//
//  Profile.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 19.02.2024.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import AlertToast

struct SignInView: View {
    
    @EnvironmentObject var user: UserEnv
    
    @State var email = ""
    @State var password = ""
    
    @State var alertText = ""
    @State var toast = false
    
    var body: some View {
        NavigationStack {
            List {
                
                if Auth.auth().currentUser == nil {
                    Section("Sign in") {
                        HStack {
                            Image(systemName: "envelope.fill")
                            TextField("Email", text: $email)
                        }
                        HStack {
                            Image(systemName: "lock.fill")
                            SecureField("Password", text: $password)
                        }
                    }
                }
                
                Section {
                    Button(action: login) {
                        Label("Sign in", systemImage: "figure.child.and.lock.open.fill")
                    }
                }
                
                UserIDTextView(id: "Shelter App (v0.3 beta). udevwork@gmail.com")
                
                
            }.navigationTitle("Shelter")
        }.onAppear {
            let defaults = UserDefaults.standard
            email = defaults.string(forKey: "lastEmail") ?? ""
            password = defaults.string(forKey: "lastPassword") ?? ""
        }
        .toast(isPresenting: $toast) {
            AlertToast(displayMode: .alert, type: .regular, title: self.alertText)
        }
    }
    
    func login() {
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
                user.checkUpdate()
                
                let defaults = UserDefaults.standard
                defaults.set(email, forKey: "lastEmail")
                defaults.set(password, forKey: "lastPassword")
                
            }
        }
    }
    
   
   
}

#Preview {
    SignInView()
}
