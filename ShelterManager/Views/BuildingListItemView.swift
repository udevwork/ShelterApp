import Foundation
import SwiftUI
import RealmSwift
import SkeletonUI
import Kingfisher

class BuildingListItemViewModel: ObservableObject {
    
    var photo: PhotoUploaderManager
    @Published var url: URL? = nil
    
    init(buildingID: String) {
        self.photo = PhotoUploaderManager(id: buildingID)
        if UserDefaults.standard.bool(forKey: "buildingPhotoEnabled") {
            Task {
                let tempurl = try await photo.loadAvatar()
                DispatchQueue.main.async {
                    self.url = tempurl
                }
            }
        }
    }
}


struct BuildingListItemView: View {
    
    @StateObject var model: BuildingListItemViewModel
    @Binding var building: Remote.Building
    
    var body: some View {
        HStack(spacing: 16) {
            
            VStack(alignment: .leading,spacing: 22) {
                HStack (spacing: 20) {
                    if UserDefaults.standard.bool(forKey: "buildingPhotoEnabled") {
                        KFImage.url(model.url)
                            .placeholder({ Image(systemName: "house.fill") })
                            .loadDiskFileSynchronously()
                            .cacheMemoryOnly()
                            .fade(duration: 0.25)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .cornerRadius(10)
                    } else {
                        Image(systemName: "house.fill")
                    }
                    VStack(alignment:.leading) {
                        Text(building.customName).font(.title2).bold()
                        HStack(spacing: 10) {
                            HStack (spacing: 5) {
                                Image(systemName: "door.left.hand.open").imageScale(.small)
                                Text("\(building.livingSpaceCount)")
                            }
                            HStack (spacing: 5) {
                                Image(systemName: "person.2.fill").imageScale(.small)
                                Text("\(building.max) / \(building.total)")
                            }
                        }
                    }
                }
                if let address = building.address {
                    AddressListItemView(address: address)
                       
                }
               
            }
            
        }.padding(.vertical, 16)
    }
}

//#Preview {
   // BuildingListItemView(building: .init(address: Address()))
//}
