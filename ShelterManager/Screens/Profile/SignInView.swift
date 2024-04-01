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

class SignInViewModel: ObservableObject {
    @Published var alertText = ""
    @Published var toast = false
    @Published var email = ""
    @Published var password = ""
    
    init(){
        let defaults = UserDefaults.standard
        email = defaults.string(forKey: "lastEmail") ?? ""
        password = defaults.string(forKey: "lastPassword") ?? ""
    }
    
    func login(user: UserEnv) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        if email.isValidEmail() == false {
            self.alertText = "invalid email"
            self.toast = true
            return
        }
        
        if password.isValidPassword() == false  {
            self.alertText = "invalid password"
            self.toast = true
            return
        }
        
        user.checkUpdate(email: email, password: password, completion: { success in
            if success == false {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.3, execute: {
                    self.alertText = "User not found"
                    self.toast = true
                    self.objectWillChange.send()
                })
            }
        })
    }
   
}

struct SignInView: View {
    
    @StateObject var model: SignInViewModel = SignInViewModel()
    @EnvironmentObject var user: UserEnv
 
    
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
                TextInput(text: $model.email,
                          title: "Email: ",
                          systemImage: "envelope.fill")
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                
                TextInput(text: $model.password,
                          title: "Password: ",
                          systemImage: "lock.fill")
            }
            
            HStack {
                Spacer()
                if user.isLoading == false {
                    Button(action: {
                        model.login(user: user)
                    }) {
                        Label("Sign in", systemImage: "figure.child.and.lock.open.fill")
                            .foregroundColor(Color(uiColor: UIColor.label))
                    }
                    .buttonStyle(BorderedButtonStyle())
                } else {
                    ProgressView()
                }
                Spacer()
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
      
            
            Rectangle().frame(width: 0, height: 40, alignment: .center)
                .foregroundColor(Color.clear)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            
            VStack {
           
                    Text(model.alertText)
                
            }.frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .listRowBackground(Color.clear)
                .foregroundStyle(Color.red)
            
            VStack {
                Text("New Green Home App v1.2")
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

        .toast(isPresenting: $model.toast) {
            AlertToast(displayMode: .alert, type: .regular, title: model.alertText)
        }
    }
}

#Preview {
    SignInView()
}

extension String {
    func isValidEmail() -> Bool {
        return self.contains("@") && self.count > 5
    }
    func isValidPassword() -> Bool {
        return self.count > 5
    }
    func isValidName() -> Bool {
        return self.count > 5
    }
    
    func isUniqUsername() async -> Bool {
        let query = Fire.base.users.whereField("userName", isEqualTo: self)
        if let snap = try? await query.getDocuments(), snap.documents.count > 0 {
            return false
        }
        return true
    }
    
    func isUniqEmail() async -> Bool {
        let query = Fire.base.users.whereField("email", isEqualTo: self)
        if let snap = try? await query.getDocuments(), snap.documents.count > 0 {
            return false
        }
        return true
    }
    
}
