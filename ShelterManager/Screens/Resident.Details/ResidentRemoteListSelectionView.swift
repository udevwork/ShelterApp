//
//  ResidentRemoteListSelectionView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 08.03.2024.
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
    @Published var searchText: String = ""
    @Published var searchInProgress: Bool = false
    private let db = Firestore.firestore()
    
    func loadUsers() {
        db.collection("Users").whereField("admin", isNotEqualTo: true).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Ошибка при получении пользователей: \(error.localizedDescription)")
            } else {
                self.users = querySnapshot!.documents.map {
                    try! $0.data(as: Remote.User.self)
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
                           try! $0.data(as: Remote.User.self)
                       }
                   }
       
                       self.searchInProgress = false
                   
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
                    ForEach(model.users) { obj in
                        Button {
                            self.onSelect(obj)
                            dismiss()
                        } label: {
                            ResidentListItemView(model: .init(residentID: obj.id), resident: obj)
                                .foregroundColor(Color(uiColor: UIColor.label))
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
            .refreshable {
                model.loadUsers()
            }
        }
        .toolbar {
            Button {
                dismiss()
            } label: {
                Text("Close")
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
