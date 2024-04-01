import SwiftUI
import RealmSwift
import Kingfisher

class ResidentListItemViewModel: ObservableObject {
    
    var photo: PhotoUploaderManager
    @Published var url: URL? = nil
    
    init(residentID: String) {
        self.photo = PhotoUploaderManager(id: residentID)
        if UserDefaults.standard.bool(forKey: "userPhotoEnabled") {
            Task {
                let tempurl = try await photo.loadAvatar()
                DispatchQueue.main.async {
                    self.url = tempurl
                }
            }
        }
    }    
}

struct ResidentListItemView: View {
    
    @ObservedObject var model: ResidentListItemViewModel
    @Binding var resident: Remote.User

    var body: some View {
        VStack(alignment: .leading) {
            if resident.isEmpty()  {
                Text("New resident")
            } else {
                HStack(spacing: 14) {
                    
                    if UserDefaults.standard.bool(forKey: "userPhotoEnabled") {
                        KFImage.url(model.url)
                            .placeholder({  Image(systemName: "person.circle.fill") })
                            .loadDiskFileSynchronously()
                            .cacheMemoryOnly()
                            .fade(duration: 0.25)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 30, height: 30)
                            .cornerRadius(15)
                    } else {
                        Image(systemName: "person.circle.fill")
                    }
                    
                    VStack(alignment: .leading) {
                        Text(resident.fullName()).bold()
                        HStack {
                            if let top = resident.shortLivingSpaceLabel, !top.isEmpty {
                                Text(top)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            if let shortAddressLabel = resident.shortAddressLabel, !shortAddressLabel.isEmpty {
                                Text(shortAddressLabel)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
    }
}
