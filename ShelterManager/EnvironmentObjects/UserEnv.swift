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

class UserEnv: ObservableObject, Codable, Identifiable {
    
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
    
    enum CodingKeys: String, CodingKey {
        case userName    = "userName"
        case admin       = "admin"
        case id          = "id"
    }
    
    init() {
        checkUpdate()
    }
    
    init(id: String,
         userName: String,
         admin: Bool? = false) {
        self.userName = userName
        self.isAdmin = admin
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userName = try container.decode(String.self, forKey: .userName)
        isAdmin = try? container.decode(Bool?.self, forKey: .admin) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userName, forKey: .userName)
        try container.encode(isAdmin, forKey: .admin)
    }
    
    func checkUpdate() {
        self.isLoading = true
        if let user = Self.current {
            isLogged = true
            let db = Firestore.firestore()
            let doc = db.collection("Users").document(user.uid)
            doc.getDocument { snap, error in
                if let snap = snap {
                    if let remoteUser = try? snap.data(as: Self.self) {
                        self.id = remoteUser.id
                        self.userName = remoteUser.userName
                        self.isAdmin = remoteUser.isAdmin
                    }
                }
                self.isLoading = false
            }
        } else {
            self.isLogged = false
            self.isLoading = false
        }
    }
}
