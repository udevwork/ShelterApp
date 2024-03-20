//
//  RemoteAddress.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 07.03.2024.
//

import Foundation
extension Remote {
    class Address: ObservableObject, Codable, Identifiable, Equatable {
        static func == (lhs: Remote.Address, rhs: Remote.Address) -> Bool {
            lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
        }
        
        
        @Published var id : String
        @Published var title: String = ""
        @Published var subtitle: String = ""
        
        enum CodingKeys: String, CodingKey {
            case id  = "id"
            case title  = "title"
            case subtitle  = "subtitle"
        }
        
        init() {
            self.id = UUID().uuidString
        }
        
        init(title: String, subtitle: String) {
            self.id = UUID().uuidString
            self.title = title
            self.subtitle = subtitle
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            title = try container.decode(String.self, forKey: .title)
            subtitle = try container.decode(String.self, forKey: .subtitle)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(title, forKey: .title)
            try container.encode(subtitle, forKey: .subtitle)
        }
        
        func fullAddress() -> String {
            var arr: [String] = []
            if !title.isEmpty {
                arr.append(title)
            }
            if !subtitle.isEmpty {
                arr.append(subtitle)
            }
         
            return arr.joined(separator: ", ")
        }
        
        func shortAddress() -> String {
            return title
        }
        
        func isEmpty() -> Bool {
            return fullAddress().isEmpty
        }
    }
}
