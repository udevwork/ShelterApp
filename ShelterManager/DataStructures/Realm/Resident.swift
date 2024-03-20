import Foundation
import RealmSwift

class Resident: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    
    @Persisted var isFavorite: Bool = false
    
    @Persisted var firstName: String
    @Persisted var secondName: String
    @Persisted var midleName: String?
    
    @Persisted var livingSpace: LivingSpace?
    
    //backlink to building
    @Persisted(originProperty: "residents") var assignee: LinkingObjects<Building>
    
    convenience init(firstName: String, secondName: String) {
        self.init()
        self.firstName = firstName
        self.secondName = secondName
    }
    
    func fullName() -> String {
        var arr: [String] = []
        if !firstName.isEmpty {
            arr.append(firstName)
        }
        
        if let midleName = midleName, !midleName.isEmpty {
            arr.append(midleName)
        }
        
        if !secondName.isEmpty {
            arr.append(secondName)
        }
     
        return arr.joined(separator: " ")
    }
    func isEmpty() -> Bool {
        return fullName().isEmpty
    }
}

extension RealmSwift.Results where Element: Resident {
    func find(with searchText: String) -> [Element]  {
        self.filter { item in
            item.fullName().contains(searchText)
        }
    }
}

extension RealmSwift.Results where Element: Resident {
    func favorites() -> [Element]  {
        self.filter { item in
            item.isFavorite
        }
    }
}
