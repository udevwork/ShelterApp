import Foundation
import RealmSwift

class Address: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    
    @Persisted var title: String = ""
    @Persisted var subtitle: String = ""
    
    convenience init(title: String, subtitle: String) {
        self.init()
        self.title = title
        self.subtitle = subtitle
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
