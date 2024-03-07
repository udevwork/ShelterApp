import SwiftUI
import RealmSwift

struct LivingSpaceListModalView: View {
    @ObservedRealmObject var resident: Resident
    
    @Environment(\.dismiss) var dismiss
    var onUpdate: (()->())
    var body: some View {
        NavigationStack {
            List {
                if let building = resident.assignee.first {
                    ForEach(building.livingSpaces) { obj in
                        Button(action: {
                            
                            let realm = try! Realm()
                            let room = realm.object(ofType: LivingSpace.self, forPrimaryKey: obj._id)
                            try! realm.write {
                                resident.thaw()?.livingSpace = room
                                onUpdate()
                                dismiss()
                            }
                            
                            
                        }, label: {
                            LivingSpaceListItem(livingSpace: obj)
                            
                        })
                        
                    }
                    if building.livingSpaces.isEmpty {
                        Text("No living spaces")
                    }
                } else {
                    Text("No living spaces")
                }
            }.navigationTitle("Choose room")
        }
    }
}

#Preview {
    LivingSpaceListModalView(resident: .init(firstName: "Denis", secondName: "Kotelnikov"), onUpdate: {})
}
