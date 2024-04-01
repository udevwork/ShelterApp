//
//  NewNotesAlerts.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 01.04.2024.
//

import SwiftUI


import SwiftUI
import FirebaseStorage
import Firebase
import AlertToast

class NewNotesAlertsModel: ObservableObject {
    
    @Published var showLoadingAlert: Bool = false
    @Published var showCopyAlert: Bool = false
    @Published var listOfNotes: [Remote.Note] = []
    @Published var isPresenting: Bool = false
    @Published var isPresentingEditor: Bool = false
    @Published var showErrorAlert: Bool = false
    
    var errorAlertText: String = ""
    
    var tabbarBager: TabbarBager
    
    init(tabbarBager: TabbarBager) {
        self.tabbarBager = tabbarBager
        getListOfNotes()
    }
    
    func getListOfNotes() {
        Task {
            let notesDocuments = try await Fire.base.notes.whereField("new", isEqualTo: true).getDocuments()
        
            do {
                let decoded: [Remote.Note] = try notesDocuments.decode()
                DispatchQueue.main.async { [decoded] in
                    self.listOfNotes = decoded
                    self.tabbarBager.newNotesAlertsCount = self.listOfNotes.count
                }
            } catch let err {
                print(err)
                
            }
           
        }
    }

    func markAllAsReaded() {
        withAnimation {
            self.listOfNotes.removeAll()
        }
        tabbarBager.newNotesAlertsCount = 0
        
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        Task {
            let notesDocuments = try await Fire.base.notes.whereField("new", isEqualTo: true).getDocuments()
          
            notesDocuments.documents.forEach { snap in
                batch.updateData(["new" : false], forDocument: snap.reference)
            }
            try await batch.commit()
   
        }
    }
    
    func markAsReaded(_ note: Remote.Note) {
        let index = self.listOfNotes.firstIndex(of: note)
        
        if let index = index {
            withAnimation {
                let val = self.tabbarBager.newNotesAlertsCount
                self.tabbarBager.newNotesAlertsCount = (val - 1)
                self.listOfNotes.remove(at: index)
            }
        }
        
        Task {
            let notesDocument = Fire.base.notes.document(note.id)
            try await notesDocument.updateData(["new" : false])
        }
    }
}

struct NewNotesAlertsView: View {
    
    @StateObject var model: NewNotesAlertsModel
    @EnvironmentObject var user: UserEnv
    @EnvironmentObject var tabbarBager: TabbarBager
    
    var body: some View {
        NavigationStack {
            List {
                
                if model.listOfNotes.count == 0 {
                    Text("No notifications!")
                }
                
                ForEach(model.listOfNotes, id: \.id) { item in
                    
                    NavigationLink {
                        ResidentProfileView(model: ResidentProfileModel(userID: item.linkedUserID), editble: user.isAdmin ?? false)
                    } label: {
                        Section() {
                            VStack(alignment: .leading, spacing: 13) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Author: \(item.authorName)")
                                    Text(item.title).font(.title3)
                                    if item.hideDate == false {
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text("\(item.date.formatted(date: .long, time:  Date.FormatStyle.TimeStyle.shortened ))")
                                            
                                            if let date = item.editedDate {
                                                Text("edited: \(date.formatted(date: .long, time:  Date.FormatStyle.TimeStyle.shortened ))")
                                            }
                                            
                                        } .font(.footnote)
                                            .foregroundStyle(Color(UIColor.secondaryLabel))
                                    }
                                }
                                Text(item.text)
                            }.foregroundStyle(Color(UIColor.label))
                            
                        }.contextMenu{
                            Button {
                                item.copyArtilceToClipboard()
                                self.model.showCopyAlert.toggle()
                            } label: {
                                Label("Copy to Clipboard", systemImage: "doc.viewfinder")
                            }
                        }
                        .swipeActions {
                            Button {
                                self.model.markAsReaded(item)
                            } label: {
                                Label("Read", systemImage: "eye.fill")
                            }
                            .tint(.indigo)
                            .disabled((user.isAdmin ?? false) == false)
                        }
                    }
                }
            }
            .navigationTitle("Alerts")
            .toolbar(content: {
                Button {
                    model.markAllAsReaded()
                } label: {
                    Label {
                        Text("Read all")
                    } icon: {
                        Image(systemName: "eye.fill")
                    }
                }.disabled((user.isAdmin ?? false) == false)
            })
        }
        
        .toast(isPresenting: $model.showLoadingAlert) {
            AlertToast(type: .loading, title: "Loading", subTitle: "Notes")
        }
        .toast(isPresenting: $model.showCopyAlert) {
            AlertToast(displayMode: .alert, type: .complete(.yellow), title: "Copied")
        }
        .refreshable {
            model.getListOfNotes()
        }
        .navigationTitle("Notes")
    }
}
