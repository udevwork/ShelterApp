//
//  UserEnv.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 19.02.2024.
//

import Foundation
import RealmSwift
import Combine
import Firebase
import FirebaseCore
import FirebaseFirestore

class UserEnv: ObservableObject, Identifiable {
    
    /// System parametrs
    @Published var isLoading    : Bool      = false
    @Published var isLogged     : Bool      = false
    
    /// User variables
    @Published var id           : String    = ""
    @Published var isAdmin      : Bool?     = false
    @Published var userName     : String    = ""
    @Published var email        : String? = ""
    @Published var password     : String? = ""
    
    let defaults = UserDefaults.standard
    
    init() {
        // Last saved pass and mail
        let email = defaults.string(forKey: "lastEmail") ?? ""
        let password = defaults.string(forKey: "lastPassword") ?? ""
        
        let _logged = defaults.bool(forKey: "isLogged")
        if _logged {
            checkUpdate(email: email, password: password, completion: { _ in })
        }
        
    }
    
    func signout(){
        isLogged = false
        self.defaults.set(false, forKey: "isLogged")
    }
    
    func checkUpdate(email: String, password: String, completion: @escaping (Bool)->()) {
        self.isLoading = true
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        findUserByEmailAndPassword(email: email, password: password) { result in
            switch result {
                case .success(let document):
                    print("Найден пользователь: \(document.data()!)")
                    
                    if let _u: Remote.User = try? document.decode() {
                        self.id = _u.id
                        self.isAdmin = _u.isAdmin
                        self.userName = _u.userName
                        self.email = _u.email
                        self.password = _u.password
                        
                        self.isLogged = true
                        self.isLoading = false
                      
                        self.defaults.set(email, forKey: "lastEmail")
                        self.defaults.set(password, forKey: "lastPassword")
                        self.defaults.set(true, forKey: "isLogged")
                        completion(true)
                    } else {
                        self.isLogged = false
                        self.isLoading = false
                        completion(false)
                    }
                    
                case .failure(let error):
                    print("Ошибка поиска пользователя: \(error.localizedDescription)")
                    print("email: \(email), password: \(password)")
                    self.isLogged = false
                    self.isLoading = false
                    completion(false)
            }
        }
     
    }
    
    func findUserByEmailAndPassword(email: String, password: String, completion: @escaping (Result<DocumentSnapshot, Error>) -> Void) {

        let usersCollection = Fire.base.users
        
        usersCollection.whereField("email", isEqualTo: email).whereField("password", isEqualTo: password).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Find documents: \(snapshot?.documents.count)")
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion(.failure(NSError(domain: "com.example.firestore", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found."])))
                    return
                }
                
                // Предполагается, что email и пароль уникальны, поэтому возвращаем первый найденный документ.
                completion(.success(documents.first!))
            }
        }
    }
}
