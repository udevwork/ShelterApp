//
//  RemoteNote.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 17.03.2024.
//

import Foundation
import Firebase
import FirebaseFirestore

extension Remote {
    class Note: ObservableObject, Codable, Identifiable, Equatable {
        
        static func == (lhs: Remote.Note, rhs: Remote.Note) -> Bool {
            lhs.title == rhs.title &&
            lhs.text == rhs.text &&
            lhs.hideDate == rhs.hideDate &&
            lhs.id == rhs.id
        }
        
        @Published var id : String
        @Published var authorName : String = ""
        @Published var date: Date = Date()
        @Published var editedDate: Date? = nil
        @Published var title: String = ""
        @Published var text: String = ""
        @Published var hideDate: Bool = false
        @Published var linkedUserID: String = ""
        @Published var new: Bool = false

        
        enum CodingKeys: String, CodingKey {
            case id  = "id"
            case authorName  = "authorName"
            case title  = "title"
            case text  = "text"
            case date  = "date"
            case editedDate  = "editedDate"
            case hideDate  = "hideDate"
            case linkedUserID  = "linkedUserID"
            case new  = "new"
        }
        
        init() {
            self.id = UUID().uuidString
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            title = try container.decode(String.self, forKey: .title)
            
            if let data = try? container.decode(String.self, forKey: .text) {
                text = data
            }
            if let data = try? container.decode(String.self, forKey: .authorName) {
                authorName = data
            }
            
            if let data = try? container.decode(Bool.self, forKey: .hideDate) {
                hideDate = data
            } 
            if let data = try? container.decode(Bool.self, forKey: .new) {
                new = new
            }
            
            linkedUserID = try container.decode(String.self, forKey: .linkedUserID)
            if let data = try? container.decode(Timestamp?.self, forKey: .date)?.dateValue() {
                date = data
            }
            if let data = try? container.decode(Timestamp?.self, forKey: .editedDate)?.dateValue() {
                editedDate = data
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(authorName, forKey: .authorName)
            try container.encode(title, forKey: .title)
            try container.encode(text, forKey: .text)
            try container.encode(hideDate, forKey: .hideDate)
            try container.encode(new, forKey: .new)
            try container.encode(linkedUserID, forKey: .linkedUserID)
            try container.encode(Timestamp(date: date), forKey: .date)
            if let editedDate = editedDate {
                try container.encode(Timestamp(date: editedDate), forKey: .editedDate)
            }
        }
        
       static func deleteNotes(for userID: String) async {
            
            let notesCollection = Fire.base.notes
            let db = Firestore.firestore()
            
            do {
                // Получаем все заметки, у которых id совпадает с userID
                let querySnapshot = try await notesCollection.whereField("linkedUserID", isEqualTo: userID).getDocuments()
                
                // Начинаем пакетную операцию
                let batch = db.batch()
                
                for document in querySnapshot.documents {
                    // Добавляем каждое удаление в пакет
                    batch.deleteDocument(document.reference)
                }
                
                // Выполняем пакетную операцию
                try await batch.commit()
                print("Все соответствующие документы успешно удалены")
                
            } catch {
                print("Ошибка при получении или удалении документов: \(error)")
            }
        }
        
        func copyNote() -> Note {
            let copy = Note()
            copy.id = self.id
            copy.authorName = self.authorName
            copy.date = self.date
            copy.editedDate = self.editedDate
            copy.title = self.title
            copy.text = self.text
            copy.hideDate = self.hideDate
            copy.linkedUserID = self.linkedUserID
            copy.new = self.new
            return copy
        }
        
        func copyArtilceToClipboard() {
            let pasteboard = UIPasteboard.general
            pasteboard.string = self.text
        }
        
    }
}
