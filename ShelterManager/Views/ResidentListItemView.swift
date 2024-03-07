import SwiftUI
import RealmSwift

struct ResidentListItemView: View {
    @ObservedRealmObject var resident: Resident
    
    var body: some View {
            
            VStack(alignment: .leading) {
                
                if resident.isEmpty()  {
                    Text("New resident")
                } else {
                    HStack(spacing: 14) {
                        Image(systemName: "person.circle.fill").frame(width: 10, height: 10, alignment: .center)
                        Text(resident.fullName()).bold()
                        if resident.isFavorite {
                            Image(systemName: "heart.fill").foregroundColor(.red).font(.footnote)
                        }
                    }.offset(x: 3)
                }
                
                if let room = resident.livingSpace {
                    Text("Room № \(room.number) (floor \(room.floor))").font(.footnote).foregroundStyle(.gray)
                } else {
                    Text("No livingspace").font(.footnote).foregroundStyle(.gray)
                }
            }
        
    }
}

#Preview {
    ResidentListItemView(resident: .init(firstName: "Denis", secondName: "Kotelnikov"))
}
