//
//  RemoteBuilding.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 07.03.2024.
//

import Foundation
extension Remote {
    class Building: ObservableObject, Codable, Identifiable {
        
        @Published var id : String = ""
        @Published var customName : String = ""
        @Published var address: Remote.Address?
        @Published var linkedLivingspacesIDs: [String]? = []
        @Published var linkedUsersIDs: [String]? = []

    
        // CULCULATBLE
        @Published var livingSpaceCount : Int = 0
        @Published var max : Int = 0
        @Published var total : Int = 0
        
        
        enum CodingKeys: String, CodingKey {
            case id  = "id"
            case customName  = "customName"
            case address  = "address"
            case linkedLivingspacesIDs  = "linkedLivingspacesIDs"
            case linkedUsersIDs  = "linkedUsersIDs"
        }
        
        init() {
            self.id = UUID().uuidString
            self.customName = "New building"
        }
        
        init(id: String, customName: String) {
            self.id = id
            self.customName = customName
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            customName = try container.decode(String.self, forKey: .customName)
            address = try? container.decode(Remote.Address.self, forKey: .address)
            linkedLivingspacesIDs = try? container.decode([String]?.self, forKey: .linkedLivingspacesIDs) ?? []
            linkedUsersIDs = try? container.decode([String]?.self, forKey: .linkedUsersIDs) ?? []
            livingSpaceCount = linkedLivingspacesIDs?.count ?? 0
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(customName, forKey: .customName)
            try? container.encode(address, forKey: .address)
            try? container.encode(linkedLivingspacesIDs, forKey: .linkedLivingspacesIDs)
            try? container.encode(linkedUsersIDs, forKey: .linkedUsersIDs)
        }
    }
}
