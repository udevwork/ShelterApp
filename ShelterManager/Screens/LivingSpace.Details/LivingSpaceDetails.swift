import SwiftUI
import RealmSwift

class LivingSpaceDetailsModel: ObservableObject {
    
    @ObservedRealmObject var livingSpace: LivingSpace
  
    init(livingSpace: LivingSpace) {
        self.livingSpace = livingSpace
    }
    
    func update() {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
            withAnimation {
                self.objectWillChange.send()
            }
        })
    }
}

struct LivingSpaceDetails: View {
    @StateObject var model: LivingSpaceDetailsModel
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Room").foregroundColor(Color(UIColor.secondaryLabel))
                    TextField("№", text: $model.livingSpace.number)
                }
                HStack {
                    Text("Floor").foregroundColor(Color(UIColor.secondaryLabel))
                    TextField("Number", text: $model.livingSpace.floor)
                }
                HStack {
                    Text("Max").foregroundColor(Color(UIColor.secondaryLabel))
                    TextField("Residents", text: $model.livingSpace.maxResident)
                }
            }
            
            Section("Residents") {
                ForEach(model.livingSpace.assigneeResidents) { obj in
                    ResidentListItemView(resident: obj)
                }
            }
        }.navigationTitle("Living space")
       
    }
}

//#Preview {
//    LivingSpaceDetails()
//}
