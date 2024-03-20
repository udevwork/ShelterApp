import Foundation
import RealmSwift

class LivingSpace: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    
    // The room number
    @Persisted var number : String = "0"
    
    // Floor of the building where the room is located
    @Persisted var floor : String = "1"
    
    // Floor of the building where the room is located
    @Persisted var maxResident : String = "1"
        
    //backlink to building
    @Persisted(originProperty: "livingSpaces") var assigneeBuilding: LinkingObjects<Building>
    
    //backlink to residents
    @Persisted(originProperty: "livingSpace") var assigneeResidents: LinkingObjects<Resident>
    
    convenience init(number: String) {
        self.init()
        self.number = number
    }
}

extension RealmSwift.List where Element: LivingSpace {
    func sortingWith(filter: BuildingDetailModel.Filter) -> [Element] {
        switch filter {
            case .roomNumber:
               return self.sorted(by: { $0.number < $1.number })
            case .fullFirst:
                return self.sorted(by: { $0.assigneeResidents.count > $1.assigneeResidents.count })
            case .emptyFirst:
                return self.sorted(by: {  $0.assigneeResidents.count < $1.assigneeResidents.count })
            case .floor:
                return self.sorted(by: { $0.floor < $1.floor })
        }
    }
}

extension RealmSwift.Results where Element: LivingSpace {
    func find(with searchText: String) -> [Element]  {
        self.filter { item in
           
            let findedResident = item.assigneeResidents.first { resident in
                resident.fullName().contains(searchText)
            }
            return findedResident != nil
        }
    }
}
