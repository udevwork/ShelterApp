import SwiftUI
import RealmSwift

struct LivingSpaceListItem: View {
    
    var livingSpace: Remote.LivingSpace?
    
    var body: some View {
        if let livingSpace = livingSpace {
            HStack(spacing: 16) {
                
                VStack(alignment: .leading) {
                    HStack() {
                        Image(systemName: "door.left.hand.open")
                        HStack(spacing:3) {
                            Text("№")
                            Text(livingSpace.number).bold()
                        }
                    }
                    Text("Floor: \(livingSpace.floor)").font(.footnote).foregroundStyle(.secondary).bold()
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(
                            self.indicatorColor(current: livingSpace.linkedUserIDs.count
                                                , max: livingSpace.maxUsersCount))
                    Text("\(livingSpace.linkedUserIDs.count) / \(livingSpace.maxUsersCount)").bold()
                }
                
            }
        } else {
            Text("No top linked").foregroundColor(Color(UIColor.secondaryLabel))
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
//
//#Preview {
//    LivingSpaceListItem(livingSpace: .init(number: "83"))
//}
