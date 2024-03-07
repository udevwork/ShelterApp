import SwiftUI
import RealmSwift

struct LivingSpaceListItem: View {
    
    @ObservedRealmObject var livingSpace: LivingSpace
    
    var body: some View {
        HStack(spacing: 16) {
            
            VStack(alignment: .leading) {
                HStack(spacing:13) {
                    Image(systemName: "door.left.hand.open").frame(width: 10, height: 10, alignment: .center)
                    HStack(spacing:2) {
                        Text("№")
                        Text(livingSpace.number).bold()
                    }
                }.offset(x:2)
                Text("Floor: \(livingSpace.floor)").font(.footnote).foregroundStyle(.secondary).bold()
            }
            Spacer()
            HStack {
                Image(systemName: "person.2.fill").foregroundColor(self.indicatorColor(current: Int(livingSpace.assigneeResidents.count) , max: Int(livingSpace.maxResident) ?? 0))
                Text("\(livingSpace.assigneeResidents.count) / \(livingSpace.maxResident)").bold()
            }
            
        }
    }
    
    func indicatorColor(current: Int, max: Int) -> Color {
        switch current {
            case let x where x > max:
                return .red
            case let x where x == max:
                return .yellow
            case let x where x < max:
                return .green
            default:
                return .gray
        }
    }
    
}

#Preview {
    LivingSpaceListItem(livingSpace: .init(number: "83"))
}
