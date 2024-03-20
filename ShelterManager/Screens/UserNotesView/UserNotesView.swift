//
//  UserNotesView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 17.03.2024.
//


import SwiftUI
import FirebaseStorage
import Firebase
import AlertToast

class UserNotesViewModel: ObservableObject {
    
    @Published var showLoadingAlert: Bool = false
    @Published var listOfNotes: [Remote.Note] = []
    @Published var isPresenting: Bool = false
    @Published var showErrorAlert: Bool = false
    
    var errorAlertText: String = ""

    var id: String
    
    init(id: String) {
        self.id = id
    }
    
    func getListOfNotes() {
        Task {
            let notesDocuments = try await Fire.base.notes.whereField("linkedUserID", isEqualTo: id).getDocuments()
            

            let decoded: [Remote.Note] = try notesDocuments.decode()
            DispatchQueue.main.async { [decoded] in
                self.listOfNotes = decoded
            }
        }
    }
    
    func deleteFile(id: String) {
        Fire.base.notes.document(id).delete()
        // delete from ui
        if let indexToDelete = self.listOfNotes.firstIndex(where: { $0.id == id }) {
            self.listOfNotes.remove(at: indexToDelete)
        }
    }
 
    
    func uploadNote(text: String) {
        let new = Remote.Note()
        new.title = text
        new.date = Date()
        new.linkedUserID = id
        listOfNotes.append(new)
        Task {
            Fire.base.notes
                .document(new.id)
                .setData(new.toDictionary())
        }
    }
    
}

struct UserNotesView: View {
    
    @StateObject var model: UserNotesViewModel
    var editble: Bool
    
    var body: some View {
        List {
            if editble {
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    model.isPresenting = true
                } label: {
                    Label("Write new note", systemImage: "note.text.badge.plus")
                }
            }
            
            ForEach(model.listOfNotes, id: \.id) { item in
                Section("\(item.date.formatted(date: .long, time:  Date.FormatStyle.TimeStyle.shortened ))") {
                    Text(item.title)
                }.contextMenu{
                    Button {
                        model.deleteFile(id: item.id)
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }.disabled(!editble)
                }
            }
            
        }.sheet(isPresented: $model.isPresenting) {
            NewNoteView(onSave: model.uploadNote)
        }
        .toast(isPresenting: $model.showLoadingAlert) {
            AlertToast(type: .loading, title: "Loading", subTitle: "Notes")
        }
        .onAppear {
            model.getListOfNotes()
        }
        .navigationTitle("Notes")
    }
}



struct NewNoteView: View {
    var onSave: (String) -> Void
    @State private var text = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $text)
                    .font(.title3)
                    .padding()
                    .focused($isFocused)
                    .navigationTitle("New note")
                    .toolbar {
                        Button("Save") {
                            onSave(text)
                            dismiss()
                        }
                    }
            }.onAppear {
                isFocused = true
            }
        }
    }
}
