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
            lhs.title == rhs.title
        }
        
        @Published var id : String
        @Published var date: Date = Date()
        @Published var title: String = ""
        @Published var linkedUserID: String = ""
        
        enum CodingKeys: String, CodingKey {
            case id  = "id"
            case title  = "title"
            case date  = "date"
            case linkedUserID  = "linkedUserID"
        }
        
        init() {
            self.id = UUID().uuidString
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            title = try container.decode(String.self, forKey: .title)
            linkedUserID = try container.decode(String.self, forKey: .linkedUserID)
            if let data = try? container.decode(Timestamp?.self, forKey: .date)?.dateValue() {
                date = data
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(title, forKey: .title)
            try container.encode(linkedUserID, forKey: .linkedUserID)
            try container.encode(Timestamp(date: date), forKey: .date)
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
    }
}
