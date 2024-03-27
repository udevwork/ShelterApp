//
//  Profile.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 19.02.2024.
//

import SwiftUI
import Firebase
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
        
        List {
            HStack(alignment:.center) {
                VStack {
                    Image("icon").resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150, alignment: .center)
                        .cornerRadius(15)
                    Text("New Green Home").font(.title)
                }
            }.listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .frame(maxWidth: .infinity)
            
            
            Section("Sign in") {
                TextInput(text: $email,
                          title: "Email: ",
                          systemImage: "envelope.fill")
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                
                TextInput(text: $password,
                          title: "Password: ",
                          systemImage: "lock.fill")
            }
            
            HStack {
                Spacer()
                Button(action: login) {
                    Label("Sign in", systemImage: "figure.child.and.lock.open.fill")
                        .foregroundColor(Color(uiColor: UIColor.label))
                }
                .buttonStyle(BorderedButtonStyle())
                Spacer()
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
      
            
            Rectangle().frame(width: 0, height: 40, alignment: .center)
                .foregroundColor(Color.clear)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            
            VStack {
                if alertText.isEmpty == false {
                    Text(alertText)
                }
            }.frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .listRowBackground(Color.clear)
                .foregroundStyle(Color.red)
            
            VStack {
                Text("New Green Home App v1.0")
                Text("Copyrighted 2024 by Walter Tremmel")
                Text("udevwork@gmail.com")
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .font(.system(size: 11))
            .listRowBackground(Color.clear)
            .foregroundStyle(Color(uiColor: .secondaryLabel))
            
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
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
        user.checkUpdate(email: email, password: password, completion: { success in
            if success == false {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.3, execute: {
                    self.alertText = "User not found"
                    self.toast = true
                })
             
            }
        })
    }
   
    
    
}

#Preview {
    SignInView()
}
