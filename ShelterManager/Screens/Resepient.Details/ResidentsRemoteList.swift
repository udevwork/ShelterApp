//
//  ResidentsRemoteList.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 21.02.2024.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift
import Foundation
import RealmSwift
import Combine
import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

class RemoteUser: ObservableObject, Codable, Identifiable {
    
    @Published var id           : String    = ""
    @Published var isAdmin      : Bool?     = false
    @Published var userName     : String    = ""
    
    enum CodingKeys: String, CodingKey {
        case id          = "id"
        case userName   = "userName"
        case admin       = "admin"
    }
    
    init() {
       
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
}


class ResidentsRemoteListModel: ObservableObject {
    
    @Published var users: [RemoteUser] = []
    @Published var searchText: String = ""
    @Published var searchInProgress: Bool = false
    private let db = Firestore.firestore()
    
    func loadUsers() {
        db.collection("Users").whereField("admin", isNotEqualTo: true).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Ошибка при получении пользователей: \(error.localizedDescription)")
            } else {
                self.users = querySnapshot!.documents.map {
                    try! $0.data(as: RemoteUser.self)
                }
            }
            self.searchInProgress = false
        }
    }
    
    func search(by text: String) {
        if text.isEmpty {
            loadUsers()
            return
        }
    
        let endText = text + "\u{f8ff}"
           
           db.collection("Users")
               .whereField("userName", isGreaterThanOrEqualTo: text)
               .whereField("userName", isLessThanOrEqualTo: endText)
               .getDocuments { (querySnapshot, error) in
                   if let error = error {
                       print("Ошибка поиска: \(error)")
                      
                   } else {
                       self.users = querySnapshot!.documents.map {
                           try! $0.data(as: RemoteUser.self)
                       }
                   }
       
                       self.searchInProgress = false
                   
               }
    }
    
    func deleteRemoteUser(id: String){
        db.collection("Users").document(id).delete { err in
                if let err = err {
                    // Обработка ошибки при удалении документа
                    print("Error removing document: \(err)")
                } else {
                    // Документ успешно удален
                    print("Document successfully removed!")
                    self.loadUsers()
                }
            }
    }
    
}

struct ResidentsRemoteList: View {
    
    @StateObject var model: ResidentsRemoteListModel = ResidentsRemoteListModel()
    @State private var searchIsActive = true

    var body: some View {
        List {
            
            Section {
                ForEach(model.users) { item in
                    NavigationLink {
                        ResidentProfileView(model: ResidentProfileModel(user: item))
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text(item.userName)
                        }.contextMenu {
                            Button {
                                model.deleteRemoteUser(id: item.id)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }

                        }
                    }
                }
            } header: {
                HStack(spacing: 10) {
                    Text("All accounts list")
                    if model.searchInProgress {
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                    }
                }
            } footer: {
                Text("List of all users created on the server")
            }
        }
        .searchable(text: $model.searchText, isPresented: $searchIsActive, placement: .navigationBarDrawer(displayMode: .always))
        .onReceive(model.$searchText.debounce(for: .seconds(1), scheduler: DispatchQueue.main)) {
            self.model.search(by: $0)
        }
        .onReceive(model.$searchText.debounce(for: .seconds(0), scheduler: DispatchQueue.main)) { _ in
            if model.searchText.isEmpty == false {
                self.model.searchInProgress = true
            }
        }
        .onAppear {
            model.loadUsers()
        }
        
    }
}

#Preview {
    ResidentsRemoteList()
}
