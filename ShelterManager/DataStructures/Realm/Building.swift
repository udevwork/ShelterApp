import Foundation
import RealmSwift

final class Building: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    
    @Persisted var customBuildingName: String = "Building"
    @Persisted var address: Address?
    @Persisted var livingSpaces = RealmSwift.List<LivingSpace>()
    @Persisted var deleted: Bool = false
    
    // Peoples associated with this building
    @Persisted var residents = RealmSwift.List<Resident>()
    
    convenience init(address: Address?) {
        self.init()
        self.address = address
    }
    
    // can be optimized by create new value for counter and +/- on room created
    func culcMax() -> Int {
        var result: Int = 0
        livingSpaces.forEach { room in
            result += Int(room.maxResident) ?? 0
        }
        return result
    }
}

extension RealmSwift.List where Element: Building {
    func find(with searchText: String) -> [Element]  {
        self.filter { item in
            item.address?.fullAddress().contains(searchText) ?? false
        }
    }
}

extension RealmSwift.Results where Element: Building {
    func find(with searchText: String) -> [Element]  {
        self.filter { item in
            
            let findedAddress = (item.address?.fullAddress().contains(searchText) ?? false) || item.customBuildingName.contains(searchText)
            
            let findedResident = item.residents.first { resident in
                resident.fullName().contains(searchText)
            } != nil
         
            
           return findedAddress || findedResident
        }
    }
}
