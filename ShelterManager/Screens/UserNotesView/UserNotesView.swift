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
    
    enum NotesType {
        case user, admin
    }
    
    @Published var showLoadingAlert: Bool = false
    @Published var showCopyAlert: Bool = false
    @Published var listOfNotes: [Remote.Note] = []
    @Published var isPresenting: Bool = false
    @Published var isPresentingEditor: Bool = false
    @Published var showErrorAlert: Bool = false
    var notesType: NotesType
    var authorName: String
    var errorAlertText: String = ""

    var id: String
    
    init(id: String, type: NotesType, authorName: String) {
        self.notesType = type
        self.id = id
        self.authorName = authorName
        if type == .user {
            self.id += "-user"
        }
    }
    
    func getListOfNotes() {
        Task {
            let notesDocuments = try await Fire.base.notes.whereField("linkedUserID", isEqualTo: id).getDocuments()

            do {
                let decoded: [Remote.Note] = try notesDocuments.decode()
                DispatchQueue.main.async { [decoded] in
                    self.listOfNotes = decoded
                }
            } catch let err {
                print(err)
                
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
 
    
    func uploadNote(_ note: Remote.Note) {
        note.linkedUserID = id
        if notesType == .user {
            note.new = true
        }
        note.authorName = self.authorName
        listOfNotes.append(note)
        Task {
            Fire.base.notes
                .document(note.id)
                .setData(note.toDictionary())
        }
    }
    
    func updateNote(_ note: Remote.Note) {
        note.editedDate = Date()
        Task {
            Fire.base.notes
                .document(note.id)
                .setData(note.toDictionary())
        }
    }
    
}

struct UserNotesView: View {
    
    @StateObject var model: UserNotesViewModel
    @State var noteToEdit: Remote.Note? = nil
    
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
                Section() {
                    Button {
                        self.noteToEdit = item
                        model.isPresentingEditor.toggle()
                    } label: {
                        VStack(alignment: .leading, spacing: 13) {
                            VStack(alignment: .leading, spacing: 4) {
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
                        } .foregroundStyle(Color(UIColor.label))
                    }.disabled(!editble)
                   
                }.contextMenu{
                    Button {
                        model.deleteFile(id: item.id)
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }.disabled(!editble)
                    
                    Button {
                        item.copyArtilceToClipboard()
                        self.model.showCopyAlert.toggle()
                    } label: {
                        Label("Copy to Clipboard", systemImage: "doc.viewfinder")
                    }.disabled(!editble)
                    
                    
                }
            }
            
        }.sheet(isPresented: $model.isPresenting) {
            
            NewNoteView(onSave: model.uploadNote)
            
        }
        .sheet(isPresented: $model.isPresentingEditor) {
      
        } content: {
            if let copy = noteToEdit?.copyNote() {
                EditNoteView(onSave: model.updateNote, note: $noteToEdit ?? Remote.Note(), noteCopy: copy)
            }
        }
        
        .toast(isPresenting: $model.showLoadingAlert) {
            AlertToast(type: .loading, title: "Loading", subTitle: "Notes")
        }
        .toast(isPresenting: $model.showCopyAlert) {
            AlertToast(displayMode: .alert, type: .complete(.yellow), title: "Copied")
        }
        .onAppear {
            model.getListOfNotes()
        }
        .navigationTitle("Notes")
    }
}



struct NewNoteView: View {

    var onSave: (Remote.Note) -> Void
    var note: Remote.Note?
    
    @State private var title = ""
    @State private var text = ""
    @State private var hideDate: Bool = false
    
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) var dismiss

    init(onSave: @escaping (Remote.Note) -> Void, note: Remote.Note? = nil) {
        self.onSave = onSave
        self.note = note
        
        if note != nil {
            self.title = note?.title ?? ""
            self.text = note?.text ?? ""
            self.hideDate = note?.hideDate ?? true
        }
    }
    
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Title:")
                TextEditor(text: $title)
                    .font(.title)
                    .focused($isFocused)
                    .frame(height: 40)
                    .lineLimit(1)
                Text("Article:")
                TextEditor(text: $text)
                    .font(.title3)
                    .navigationTitle("New note")
                    .toolbar {
                        Button("Save") {
                            
                            let new = Remote.Note()
                            new.title = title
                            new.text = text
                            new.hideDate = hideDate
                            new.date = Date()
                            onSave(new)
                            
                            dismiss()
                        }
                    }
                
                Toggle(isOn: $hideDate) {
                    Label {
                        Text("Hide date")
                    } icon: {
                        Image(systemName: "calendar.badge.exclamationmark")
                    }

                }.padding(10)
                
            }.padding(20)
            .onAppear {
                isFocused = true
            }
        }
    }
}

struct EditNoteView: View {

    var onSave: (Remote.Note) -> Void
    @Binding var note: Remote.Note
  
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) var dismiss

    @State var noteCopy: Remote.Note
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Title:")
                TextEditor(text: $note.title)
                    .font(.title)
                    .focused($isFocused)
                    .frame(height: 40)
                    .lineLimit(1)
                Text("Article:")
                TextEditor(text: $note.text)
                    .font(.title3)
                    .navigationTitle("Edit note")
                Toggle(isOn: $note.hideDate) {
                    Label {
                        Text("Hide date")
                    } icon: {
                        Image(systemName: "calendar.badge.exclamationmark")
                    }

                }.padding(10)
                
            }.padding(20)
            .onAppear {
                isFocused = true
            }.onDisappear {
                if noteCopy != note {
                    onSave(note)
                }
            }
        }
    }
}
