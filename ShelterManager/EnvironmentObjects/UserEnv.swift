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
import FirebaseAuth
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
    
    static var current: Firebase.User? {
        get {
            Auth.auth().currentUser
        }
    }
  
    init() {
        checkUpdate()
    }
    
    func checkUpdate() {
        self.isLoading = true
        if let user = Self.current {
            isLogged = true
            let id = user.uid
            let doc = Fire.base.users.document(id)
            
            Task {
                if let doc = try? await doc.getDocument(), let user: Remote.User = try? doc.decode() {
                    
                    self.id = user.id
                    self.isAdmin = user.isAdmin
                    self.userName = user.userName
                } else {
                    try Auth.auth().signOut()
                    self.isLogged = false
                    self.isLoading = false
                }
                self.isLoading = false
            }
            
        } else {
            self.isLogged = false
            self.isLoading = false
        }
    }
}
