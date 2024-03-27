import SwiftUI
import _PhotosUI_SwiftUI
import RealmSwift
import Combine
import AlertToast
import Firebase
import Kingfisher

class BuildingDetailModel: ObservableObject {
    
    @Published var building: Remote.Building
    @Published var livingSpaces: [Remote.LivingSpace] = []
    
    @Published var avatarUrl: URL? = nil
    @Published var showLoadingAlert: Bool = false
    @Published var fullSizeImage: URL? = nil
    @Published var isShowingFullScreen = false
    var photoManager: PhotoUploaderManager
    
    private let db = Firestore.firestore()
    
    enum Filter: String, CaseIterable, Identifiable {
        case roomNumber, fullFirst, emptyFirst, floor
        var id: Self { self }
    }
    
    @Published var selectedFlavor: Filter = .roomNumber
    
    private var cancellable: AnyCancellable?
    var onUpdate: (()->())? = nil
    
    init(building: Remote.Building, onUpdate: (()->())?) {
        self.building = building
        photoManager = PhotoUploaderManager(id: building.id)
        fetchLivingSpaces()
    }
    
    func fetchLivingSpaces() {
        let ref = Fire.base.livingSpaces
        
        Task {
            let snap = try! await ref
                .whereField("linkedBuildingID", isEqualTo: building.id)
                .getDocuments()
            
            DispatchQueue.main.async {
                self.livingSpaces = try! snap.decode()
                self.objectWillChange.send()
            }
            
            
        }
    }
    

    
    func createLivingSpace() {
        
        let room = Remote.LivingSpace(number: "0",
                                      linkedBuildingID: building.id,
                                      maxUsersCount: 5)
        
        building.linkedLivingspacesIDs?.append(room.id)
        
        let livingSpacesRef = Fire.base.livingSpaces.document(room.id)
        let buildingRef = Fire.base.buildings.document(building.id)
        
        let livingSpacesData = room.toDictionary()
        let buildingData = building.toDictionary()
        
        Task {
            try? await livingSpacesRef.setData(livingSpacesData)
            try? await buildingRef.setData(buildingData)
            self.livingSpaces.append(room)
        }
    }
  
    func createAndSetupAddress() {
        let batch = db.batch()
        
        guard let address = building.address else { return }
        
        let addressRef = Fire.base.addresses.document(address.id)
        let buildingRef = Fire.base.buildings.document(building.id)
        
        let addressData = address.toDictionary()
        let buildingData = building.toDictionary()
        
        Task {
            try? await addressRef.setData(addressData)
            try? await buildingRef.setData(buildingData)
            
            let users = try? await Fire.base.users.whereField("linkedBuildingID", isEqualTo: building.id).getDocuments()
            
            users?.documents.forEach({ snap in
                batch.updateData(["shortAddressLabel" : building.address?.fullAddress() ?? "",
                                  "linkedAddressID": building.address?.id ?? ""], forDocument: snap.reference)
                
            })
          
            try await batch.commit()
            DispatchQueue.main.async {
             
                self.objectWillChange.send()
            }
            self.update()
        }
    }
    
    func delete(livingSpace: Remote.LivingSpace) {
        
        let deletedLivingspaceID = livingSpace.id
        Fire.base.livingSpaces.document(deletedLivingspaceID).delete()
        let batch = db.batch()
        
        Task {
            let usersSnap = try await Fire.base.users.whereField("linkedLivingspaceID", isEqualTo: deletedLivingspaceID).getDocuments().documents
            let buildingRef = Fire.base.buildings.document(building.id)
            
            var _userIDs: [String] = []
            for userDoc in usersSnap {
                _userIDs.append(userDoc.documentID)
                let doc = Fire.base.users.document(userDoc.documentID)
                
                let dict = ["linkedAddressID": "",
                            "linkedBuildingID": "",
                            "linkedLivingspaceID": "",
                            "shortAddressLabel": "",
                            "shortLivingSpaceLabel": ""]
                
                batch.updateData(dict, forDocument: doc)
            }
            
            batch.updateData(["linkedUsersIDs": FieldValue.arrayRemove(_userIDs)], forDocument: buildingRef)
            batch.updateData(["linkedLivingspacesIDs": FieldValue.arrayRemove([deletedLivingspaceID])], forDocument: buildingRef)
            
            try await batch.commit()
            
            // delete notes
            await Remote.Note.deleteNotes(for: deletedLivingspaceID)
            
            // delete from ui
            if let indexToDelete = self.livingSpaces.firstIndex(where: { $0.id == deletedLivingspaceID }) {
                DispatchQueue.main.async {
                    self.livingSpaces.remove(at: indexToDelete)
                }
            }
       
        }
    }
    
    
    // AVATAR
    func uploadImage(imageData: Data) {
        self.showLoadingAlert = true
        Task {
            self.avatarUrl = try await photoManager.uploadAvatar(imageData: imageData)
            self.fullSizeImage = nil
            self.showLoadingAlert = false
            self.loadFullAvatarUrl()
        }
    }
    
    func getThumbnaliAvatarUrl() {
        if fullSizeImage != nil {
            return
        }
        Task {
            self.avatarUrl = try await photoManager.loadAvatar()
            self.loadFullAvatarUrl()
        }
    }
    
    func getFullAvatarUrlFrom() {
        if fullSizeImage != nil {
            self.isShowingFullScreen = true
            return
        }
        if let url = avatarUrl {
            self.showLoadingAlert = true
            Task {
                self.avatarUrl = try await photoManager.getFullAvatarUrlFrom(url: url)
                self.fullSizeImage = self.avatarUrl
                self.showLoadingAlert = false
                self.isShowingFullScreen = true
            }
        }
    }
    
    func loadFullAvatarUrl() {
        if fullSizeImage != nil {
            return
        }
        if let url = avatarUrl {
            Task {
                self.avatarUrl = try await photoManager.getFullAvatarUrlFrom(url: url)
                self.fullSizeImage = self.avatarUrl
            }
        }
    }
    
    func update() {
        self.fetchLivingSpaces()

    }
}

struct BuildingDetailView: View {
    
    @EnvironmentObject var clipboard: InAppClipboard
    @StateObject var model: BuildingDetailModel
    @State private var avatarItem: PhotosPickerItem?
    @State private var showToast = false
    
    enum ModelViews: String, Identifiable {
        case  city, optimizer
        
        var id: String { rawValue }
    }
    
    @State private var sheets : ModelViews? = nil
    
    var body: some View {
        
        List {
            if UserDefaults.standard.bool(forKey: "buildingDitailPhotoEnabled") {
                KFImage.url(model.avatarUrl)
                    .placeholder({ Image("default-buildingpic") })
                    .loadDiskFileSynchronously()
                    .cacheMemoryOnly()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .onTapGesture {
                        self.model.getFullAvatarUrlFrom()
                    }
            }
            Section("Information") {
                
                TextInput(text: $model.building.customName,
                          title: "Name: ",
                          systemImage: "pencil")
                
                VStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        self.sheets = .city
                    } label: {
                        AddressListItemWithMapView(address: $model.building.address)
                    }
                }
            
                Button {
                    model.createAndSetupAddress()
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    showToast.toggle()
                } label: {
                    Label("Save", systemImage: "icloud.and.arrow.up.fill")
                }
            }
            
            Section() {
                NavigationLink {
                    DocumentsView(model: .init(id: model.building.id), editble: true)
                } label: {
                    Label("Documents", systemImage: "doc.on.doc.fill")
                }.foregroundColor(Color(UIColor.label))
                
                NavigationLink {
                    PhotoGalleryView(model: .init(id: model.building.id))
                } label: {
                    Label("Photos", systemImage: "photo.on.rectangle.angled")
                }.foregroundColor(Color(UIColor.label))
                
                NavigationLink {
                    UserNotesView(model: .init(id: model.building.id), editble: true)
                } label: {
                    Label("Notes", systemImage: "note.text")
                }.foregroundColor(Color(UIColor.label))
                
                NavigationLink {
                    ResidentsRemoteList(model: .init(buildingID: model.building.id))
                } label: {
                    Label("Residents", systemImage: "person.2.fill")
                }.foregroundColor(Color(UIColor.label))
            }
            
            Section("Livingspaces") {
                
                Picker("Sorting", selection: $model.selectedFlavor) {
                    Text("Room number").tag(BuildingDetailModel.Filter.roomNumber)
                    Text("Full first").tag(BuildingDetailModel.Filter.fullFirst)
                    Text("Empty first").tag(BuildingDetailModel.Filter.emptyFirst)
                    Text("Floor").tag(BuildingDetailModel.Filter.floor)
                }.listRowSeparator(.hidden, edges: .all)
                
                
                ForEach(model.livingSpaces.sortingWith(filter: model.selectedFlavor)) { obj in
                    NavigationLink {
                        LivingSpaceDetails(model: .init(livingSpace: obj, building: model.building, onUpdate: { self.model.update() }), buildingModel: model)
                    } label: {
                        LivingSpaceListItem(livingSpace: obj)
                            .contextMenu {
                                Button {
                                    model.delete(livingSpace: obj)
                                } label: {
                                    Label("Delete", systemImage: "trash.fill").foregroundStyle(Color.red)
                                }
                            }
                    }
                }
                
                HStack(spacing: 3) {
                    Text("Total:")
                    Text("\(model.livingSpaces.count)").bold()
                }
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                self.model.createLivingSpace()
            } label: {
                Label("Create livingspace", systemImage: "plus.circle.fill")
            }
       
            
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(model.building.customName)
        .refreshable {
            model.update()
        }
        .sheet(item: $sheets) {

        } content: { item in
            if item == .city {
                AddressAutocompleteModalView(viewModel: .init(), autocomplete: $model.building.address)
            }
        }
        .sheet(isPresented: $model.isShowingFullScreen) {
            VStack {
                if let url = model.fullSizeImage {
                    FullScreenImageView(url: url)
                } else {
                    Text("invalid url")
                }
            }
        }
        .toast(isPresenting: $showToast){
            AlertToast(type: .regular, title: "OK!")
        }
        .toast(isPresenting: $model.showLoadingAlert) {
            AlertToast(type: .loading, title: "Loading")
        }
        .toolbar {
            PhotosPicker("Change picture", selection: $avatarItem, matching: .images)
                .onChange(of: avatarItem)  {
                    Task {
                        if let loaded = try? await avatarItem?.loadTransferable(type: Data.self) {
                            let cont = Image(uiImage: UIImage(data: loaded)!)
                            let renderer = ImageRenderer(content: cont)
                            let compression = UserDefaults.standard.bool(forKey: "extremeImageCompressionEnabled") ? 0.0 : 0.7
                            if let data = renderer.uiImage?.jpegData(compressionQuality: compression) {
                                model.uploadImage(imageData: data)
                            } else {
                                print("Failed 1")
                            }
                        } else {
                            print("Failed 2")
                        }
                    }
                }
            if let address = model.building.address {
                NavigationLink {
                    MapView(address: address)
                } label: {
                    HStack {
                        Image(systemName: "mappin.and.ellipse.circle.fill")
                        Text("Map")
                    }
                }
            }
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "buildingDitailPhotoEnabled") {
                model.getThumbnaliAvatarUrl()
            }
        }
    }
}

//#Preview {
//    NavigationStack {
//        BuildingDetailView(model: BuildingDetailModel.init(building: Building(address: Address()), onUpdate: {}))
//    }
//}
