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
    
    init() {
        
    }
    
    func saveData(user: UserEnv) {
        // Получаем ссылку на хранилище Firestore
        let db = Firestore.firestore()
        
        // Ссылка на конкретный документ пользователя по ID
        let id = UserEnv.current?.uid ?? ""
        let userRef = db.collection("Users").document(id)
        
        // Создаем словарь из обновленных данных пользователя
        let updatedUserData: [String: Any] = [
            "userName": user.userName
        ]
        
        // Обновляем данные пользователя
        userRef.updateData(updatedUserData) { error in
            if let error = error {
                print("Ошибка при обновлении пользователя: \(error.localizedDescription)")
            } else {
                print("Данные пользователя успешно обновлены")
            }
        }
    }
 
    
}

struct AdministratorProfileView: View {
    
    @EnvironmentObject var user: UserEnv
    @StateObject var model: AdministratorProfileModel = AdministratorProfileModel()
    
    var body: some View {
        NavigationStack {
            List {
                Section("Person") {
                    HStack {
                        Text("User").foregroundColor(Color(UIColor.secondaryLabel))
                        TextField("Name", text: $user.userName)
                    }
                  
                    Button {
                        model.saveData(user: user)
                    } label: {
                        Label("Save", systemImage: "icloud.and.arrow.up")
                    }
                }
                
                Section("Remote") {
                    NavigationLink {
                        ResidentsRemoteList() .navigationTitle("Remote users")
                    } label: {
                        Label("Open remote user list", systemImage: "person.icloud.fill")
                    }
                    NavigationLink {
                        CreateNewRemoteUserView()
                    } label: {
                        Label("Create new remote user", systemImage: "person.fill.badge.plus")
                    }
                }
           
                
                Section {
                    Button(action: signOut) {
                        Label("Sign out", systemImage: "rectangle.portrait.and.arrow.forward")
                    }
                }
                            
                NavigationLink {
                    DebugView()
                } label: {
                    Label("Development menu", systemImage: "command.circle.fill")
                }.frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .font(.footnote)
                    .listRowBackground(Color.clear)
                    .opacity(0.5)
                
            }.navigationTitle("Administrator")
                .refreshable {
                    user.checkUpdate()
                }
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
