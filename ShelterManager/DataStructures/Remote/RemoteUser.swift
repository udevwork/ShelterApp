//
//  RemoteUser.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 07.03.2024.
//

import Firebase
import Foundation

extension Remote {
    class User: ObservableObject, Codable, Identifiable {
    
        @Published var foreachid    : String    = UUID().uuidString
        @Published var id           : String    = ""
        @Published var isAdmin      : Bool?     = false
        @Published var userName     : String    = ""
        @Published var email        : String? = ""
        @Published var password     : String? = ""
        @Published var dateOfBirth: Date = Date()
        @Published var socialSecurityNumber: String = ""
        @Published var mobilePhone: String = ""
        
        @Published var linkedLivingspaceID: String? = ""
        @Published var linkedAddressID: String? = ""
        @Published var linkedBuildingID: String? = ""
        
        @Published var shortAddressLabel: String? = ""
        @Published var shortLivingSpaceLabel: String? = ""
        
        enum CodingKeys: String, CodingKey {
            case id         = "id"
            case userName   = "userName"
            case admin      = "admin"
            case dateOfBirth = "dateOfBirth"
            case socialSecurityNumber = "socialSecurityNumber"
            case mobilePhone = "mobilePhone"
            case email = "email"
            case password = "password"
            
            case linkedLivingspaceID = "linkedLivingspaceID"
            case linkedAddressID = "linkedAddressID"
            case linkedBuildingID = "linkedBuildingID"
            
            case shortAddressLabel = "shortAddressLabel"
            case shortLivingSpaceLabel = "shortLivingSpaceLabel"
        }
        
        init() {
            self.id = UUID().uuidString
        }
        
        init(id: String) {
            self.id = id
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            userName = try container.decode(String.self, forKey: .userName)
            isAdmin = try? container.decode(Bool?.self, forKey: .admin) ?? false
            linkedLivingspaceID = try? container.decode(String?.self, forKey: .linkedLivingspaceID)
            linkedAddressID = try? container.decode(String?.self, forKey: .linkedAddressID)
            linkedBuildingID = try? container.decode(String?.self, forKey: .linkedBuildingID)
            if let data = try? container.decode(Timestamp?.self, forKey: .dateOfBirth)?.dateValue() {
                dateOfBirth = data
            }
            if let data = try? container.decode(String?.self, forKey: .socialSecurityNumber) {
                socialSecurityNumber = data
            }
            if let data = try? container.decode(String?.self, forKey: .mobilePhone) {
                mobilePhone = data
            }
            
            if let data = try? container.decode(String?.self, forKey: .email) {
                email = data
            }
            if let data = try? container.decode(String?.self, forKey: .password) {
                password = data
            }    
            if let data = try? container.decode(String?.self, forKey: .shortAddressLabel) {
                shortAddressLabel = data
            } 
            if let data = try? container.decode(String?.self, forKey: .shortLivingSpaceLabel) {
                shortLivingSpaceLabel = data
            }
           
           
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(userName, forKey: .userName)
            try container.encode(isAdmin, forKey: .admin)
            try container.encode(linkedLivingspaceID, forKey: .linkedLivingspaceID)
            try container.encode(linkedAddressID, forKey: .linkedAddressID)
            try container.encode(linkedBuildingID, forKey: .linkedBuildingID)
            try container.encode(Timestamp(date: dateOfBirth), forKey: .dateOfBirth)
            try container.encode(socialSecurityNumber, forKey: .socialSecurityNumber)
            try container.encode(mobilePhone, forKey: .mobilePhone)
            try container.encode(email, forKey: .email)
            try container.encode(password, forKey: .password)
            try container.encode(shortAddressLabel, forKey: .shortAddressLabel)
            try container.encode(shortLivingSpaceLabel, forKey: .shortLivingSpaceLabel)
        }
            
        func fullName() -> String {
            return userName
        }
        func isEmpty() -> Bool {
            return fullName().isEmpty
        }
    }
}
