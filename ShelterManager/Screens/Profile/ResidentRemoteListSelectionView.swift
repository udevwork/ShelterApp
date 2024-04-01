//
//  ResidentRemoteListSelectionView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 08.03.2024.
//
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

class ResidentRemoteListSelectionViewModel: ObservableObject {
    
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
            let sorted = decoded.sorted(by: {
                let one_comonents = $0.userName.components(separatedBy: " ")
                let two_comonents = $1.userName.components(separatedBy: " ")
                
                if one_comonents.count < 2 && two_comonents.count < 2 {
                    return false
                }
                
                let one = one_comonents[1]
                let two = two_comonents[1]
                return one < two
            })
            
            DispatchQueue.main.async {
                self.users = sorted
                self.objectWillChange.send()
            }
        }
    }
    
    func search(by text: String) {
        self.searchResultusers = self.users.filter {
            $0.userName.localizedCaseInsensitiveContains(text)
        }
    }
  
}

struct ResidentRemoteListSelectionView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject var model: ResidentRemoteListSelectionViewModel = ResidentRemoteListSelectionViewModel()
    @State private var searchIsActive = true
    var onSelect: (Remote.User)->()
    
    var body: some View {
        NavigationStack {
            List {
            
                Section {
    
                    if model.searchText.isEmpty {
                        ForEach($model.users, id: \.foreachid) { $obj in
                            Button {
                                self.onSelect(obj)
                                dismiss()
                            } label: {
                                ResidentListItemView(model: .init(residentID: obj.id), resident: $obj)
                                    .foregroundColor(Color(uiColor: UIColor.label))
                            }
                        }
                    } else {
                        ForEach($model.searchResultusers) { $obj in
                            Button {
                                self.onSelect(obj)
                                dismiss()
                            } label: {
                                ResidentListItemView(model: .init(residentID: obj.id), resident: $obj)
                                    .foregroundColor(Color(uiColor: UIColor.label))
                            }
                        }
                    }
                    
                    
                } header: {
                    HStack(spacing: 10) {
                        Text("All accounts list. Total: \(model.users.count)")
                       
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

     
            .navigationTitle("Users")
        }
    }
}
