import Foundation
import SwiftUI
import RealmSwift

struct BuildingListItemView: View {
    
    @ObservedRealmObject var building: Building
    
    var body: some View {
        HStack(spacing: 16) {
            if let address = building.address, !address.fullAddress().isEmpty {
               
                VStack(alignment: .leading,spacing: 9) {
                    HStack (spacing: 15) {
                        Image(systemName: "house.fill").frame(width: 12, height: 12, alignment: .center)
                        Text(building.customBuildingName).font(.title2).bold()
                    }.offset(x: 5)
                    
                    Text(address.fullAddress()).bold().opacity(0.8)
                    
                    VStack(alignment: .leading) {
                        HStack (spacing: 10) {
                            Text("Livingspaces:")
                            Text("\(building.livingSpaces.count)").bold()
                        }
                        HStack (spacing: 10) {
                            Text("Residents:")
                            Text("\(building.residents.count) / \(building.culcMax())").bold()
                        }
                    }
                }
            } else {
                Image(systemName: "building.2").padding(.horizontal, 4)
                Text("New building").padding()
            }
        }.padding(.vertical, 16)
    }
}

#Preview {
    BuildingListItemView(building: .init(address: Address()))
}
