//
//  RemoteLivingSpace.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 07.03.2024.
//

import Foundation
extension Remote {
    class LivingSpace: ObservableObject, Codable, Identifiable {
        
        @Published var id : String = ""
        
        @Published var number: String = ""
        @Published var linkedBuildingID: String = ""
        @Published var linkedUserIDs: [String] = []

        @Published var maxUsersCount: Int = 0
        @Published var floor: String = "0"
        @Published var roomsCount: Int = 0
        @Published var squareMeters: Float = 0.0

        enum CodingKeys: String, CodingKey {
            case id  = "id"
            case number  = "number"
            case linkedBuildingID  = "linkedBuildingID"
            case linkedUserIDs  = "linkedUserIDs"
            case currentUsersCount  = "currentUsersCount"
            case maxUsersCount  = "maxUsersCount"
            case floor = "floor"
            case squareMeters = "squareMeters"
        }
        
        init() {
            self.id = UUID().uuidString
        }
        
        init(number: String = "",
             linkedBuildingID: String = "",
             linkedUserIDs: [String] = [],
             currentUsersCount: Int = 0,
             maxUsersCount: Int = 0) {
            
            self.id = UUID().uuidString
            self.number = number
            self.linkedBuildingID = linkedBuildingID
            self.linkedUserIDs = linkedUserIDs
            self.maxUsersCount = maxUsersCount
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            if let data = try? container.decode(String.self, forKey: .number) {
                number = data
            }
            if let data = try? container.decode(String.self, forKey: .linkedBuildingID) {
                linkedBuildingID = data
            }
            if let data = try? container.decode([String].self, forKey: .linkedUserIDs) {
                linkedUserIDs = data
            }
            if let data = try? container.decode(Int.self, forKey: .maxUsersCount) {
                maxUsersCount = data
            }
            
            if let data = try? container.decode(String.self, forKey: .floor) {
                floor = data
            } else if let data = try? container.decode(Int.self, forKey: .floor) {
                floor = String(data)
            }
            
            if let data = try? container.decode(Int.self, forKey: .squareMeters) {
                roomsCount = data
            }
            
            if let data = try? container.decode(Float.self, forKey: .squareMeters) {
                squareMeters = data
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(number, forKey: .number)
            try container.encode(linkedBuildingID, forKey: .linkedBuildingID)
            try container.encode(linkedUserIDs, forKey: .linkedUserIDs)
            try container.encode(maxUsersCount, forKey: .maxUsersCount)
            try container.encode(floor, forKey: .floor)
            try container.encode(squareMeters, forKey: .squareMeters)
        }
    }
}

extension Array where Element: Remote.LivingSpace {
    func sortingWith(filter: BuildingDetailModel.Filter) -> [Element] {
        switch filter {
            case .roomNumber:
               return self.sorted(by: { $0.number < $1.number })
            case .fullFirst:
                return self.sorted(by: { $0.linkedUserIDs.count > $1.linkedUserIDs.count })
            case .emptyFirst:
                return self.sorted(by: {  $0.linkedUserIDs.count < $1.linkedUserIDs.count })
            case .floor:
                return self.sorted(by: { $0.floor < $1.floor })
        }
    }
}
