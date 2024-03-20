import SwiftUI
import Firebase
import FirebaseFirestoreSwift
import Foundation
import RealmSwift
import Combine
import Firebase
import FirebaseAuth

class ResidentsRemoteListModel: ObservableObject {
    
    @Published var users: [Remote.User] = []
    @Published var searchResultusers: [Remote.User] = []
    @Published var searchText: String = ""
      
    var id: String?
    
    init(buildingID: String? = nil) {
        self.id = buildingID
        loadUsers()
    }
    
    func loadUsers() {
       
        var ref: Firebase.Query = Fire.base.users.whereField("admin", isNotEqualTo: true)
        
        if let id = self.id {
            ref = Fire.base.users.whereField("linkedBuildingID", isEqualTo: id)
        }
        
        Task { [ref] in
            let docs = try await ref.getDocuments()
            let decoded : [Remote.User] = try docs.decode()
            DispatchQueue.main.async {
                self.users = decoded
                self.objectWillChange.send()
            }
         
    
        }
        
    }
    
    func search(by text: String) {
        self.searchResultusers = self.users.filter {
            $0.userName.localizedCaseInsensitiveContains(text)
        }
    }
    
    func deleteRemoteUser(user: Remote.User) {
        let id = user.id
        
        Task {
            do {
                // detatch from old place FIRST!
                if let id = user.linkedBuildingID, !id.isEmpty {
                    let oldBuilding = Fire.base.buildings.document(id)
                    try? await oldBuilding.updateData(["linkedUsersIDs": FieldValue.arrayRemove([user.id])])
                }
                if let id = user.linkedLivingspaceID, !id.isEmpty {
                    let oldLivingSpace = Fire.base.livingSpaces.document(id)
                    try? await oldLivingSpace.updateData(["linkedUserIDs": FieldValue.arrayRemove([user.id])])
                }
                
                // Шаг 1: Чтение документа из исходной коллекции
                let oldDocRef = Fire.base.users.document(id)
                let document = try await oldDocRef.getDocument()
                guard document.exists else {
                    print("Документ для перемещения не найден.")
                    return
                }
                let data = document.data() ?? [:]
                
                // Шаг 2: Создание нового документа в целевой коллекции с прочитанными данными
                let newDocRef = Fire.base.deletedUsers.document(id)
                
                try await newDocRef.setData(data)
                try await newDocRef.updateData(["linkedAddressID": "",
                                                "linkedBuildingID": "",
                                                "linkedLivingspaceID": "",
                                                "shortAddressLabel": "",
                                                "shortLivingSpaceLabel": ""])
                // Шаг 3: Удаление исходного документа из его текущей коллекции
                try await oldDocRef.delete()
                
                // delete notes
                await Remote.Note.deleteNotes(for: id)
                
             
                
                print("Документ успешно перемещен")
                self.loadUsers()
            } catch {
                print("Произошла ошибка при перемещении документа: \(error.localizedDescription)")
            }
        }
        
    }
}

struct ResidentsRemoteList: View {
 
    @StateObject var model: ResidentsRemoteListModel
    @State private var searchIsActive = true
    @State private var showCreateUser = false
    
    var body: some View {
        NavigationStack {
            List {
                
                if model.id == nil {
                    Button {
                        showCreateUser = true
                    } label: {
                        Label("Create new User", systemImage: "plus.circle.fill")
                    }
                } else {
                    HStack(spacing: 3) {
                        Label("Residents count: \(model.users.count)", systemImage: "person.3.fill")
                    }
                }
               
                Section {
    
                    if model.searchText.isEmpty {
                        ForEach($model.users, id: \.foreachid) { $obj in
                            NavigationLink {
                                ResidentProfileView(model: ResidentProfileModel(user: obj), editble: true)
                            } label: {
                                ResidentListItemView(model: .init(residentID: obj.id), resident: obj).contextMenu {
                                    Button {
                                        model.deleteRemoteUser(user: obj)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(model.searchResultusers) { obj in
                            NavigationLink {
                                ResidentProfileView(model: ResidentProfileModel(user: obj), editble: true)
                            } label: {
                                ResidentListItemView(model: .init(residentID: obj.id), resident: obj).contextMenu {
                                    Button {
                                        model.deleteRemoteUser(user: obj)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                }
                            }
                        }
                    }
                    
                    
                } header: {
                    HStack(spacing: 10) {
                        Text("All accounts list")
                       
                    }
                } footer: {
                    Text("List of all users created on the server")
                }
            }
            .refreshable {
                model.loadUsers()
            }
            .searchable(text: $model.searchText, isPresented: $searchIsActive, placement: .navigationBarDrawer(displayMode: .always))
            .onReceive(model.$searchText) {
                self.model.search(by: $0)
            }

            .sheet(isPresented: $showCreateUser, onDismiss: {
                model.loadUsers()
            }, content: {
                CreateNewRemoteUserView(onUserCreate: { newUser in
                    model.users.append(newUser)
                })
            })
     
            .navigationTitle("Users")
        }
    }
}
//
//#Preview {
//    ResidentsRemoteList(model: ResidentsRemoteListModel)
//}
