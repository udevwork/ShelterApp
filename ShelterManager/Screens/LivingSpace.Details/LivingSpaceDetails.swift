import SwiftUI
import RealmSwift
import AlertToast
import Firebase

class LivingSpaceDetailsModel: ObservableObject {
    
    var livingSpace: Remote.LivingSpace
    var building: Remote.Building
      
    @Published var users: [Remote.User] = []
    
    var onUpdate: ()->()
    
    init(livingSpace: Remote.LivingSpace,
         building: Remote.Building, onUpdate: @escaping ()->()) {
        self.livingSpace = livingSpace
        self.building = building
        self.onUpdate = onUpdate
       
        fetch()
        

//        let fl = Float(String(format:"%.2f", model.livingSpace.squareMeters)) ?? 0.0
//        print(fl)
//        model.livingSpace.squareMeters = fl
        
    }
    
    func fetch() {
        let ref = Fire.base.users
        
        Task {
            let snap = try! await ref.whereField("linkedLivingspaceID", isEqualTo: livingSpace.id).getDocuments()
            DispatchQueue.main.async {
                self.users = try! snap.decode()
            }
        }
    }
    
    func unlinkUser(_ user: Remote.User, completion: @escaping ()->()) {
        self.users.removeAll { _ in
            return false
        }
        
        Task {
            // detatch from old place FIRST!
            if let id = user.linkedBuildingID, !id.isEmpty {
                let oldBuilding = Fire.base.buildings.document(id)
                try? await oldBuilding.updateData(["linkedUsersIDs": FieldValue.arrayRemove([user.id])])
            }
            if let id = user.linkedLivingspaceID, !id.isEmpty {
                let oldLivingSpace = Fire.base.livingSpaces.document(id)
                try? await oldLivingSpace.updateData(["linkedUserIDs": FieldValue.arrayRemove([user.id])])
            }
            
            
            user.linkedAddressID = ""
            user.linkedBuildingID = ""
            user.linkedLivingspaceID = ""
            
            // UPDATE SHORT ADDRESS

            user.shortLivingSpaceLabel = ""
            user.shortAddressLabel = ""
            
            let userRef = Fire.base.users.document(user.id)
            let userData = user.toDictionary()
        
            try? await userRef.setData(userData)
            self.fetch()
            completion()
        }
    }
    
    func updateUser(_ user: Remote.User, completion: @escaping ()->()) {
        self.users.append(user)
        Task {
            // detatch from old place FIRST!
            if let id = user.linkedBuildingID, !id.isEmpty {
                let oldBuilding = Fire.base.buildings.document(id)
                try? await oldBuilding.updateData(["linkedUsersIDs": FieldValue.arrayRemove([user.id])])
            }
            if let id = user.linkedLivingspaceID, !id.isEmpty {
                let oldLivingSpace = Fire.base.livingSpaces.document(id)
                try? await oldLivingSpace.updateData(["linkedUserIDs": FieldValue.arrayRemove([user.id])])
            }
            
            
            user.linkedAddressID = building.address?.id
            user.linkedBuildingID = building.id
            user.linkedLivingspaceID = livingSpace.id
            
            // CREATE SHORT ADDRESS

            user.shortLivingSpaceLabel = "Top \(livingSpace.number)"            
            user.shortAddressLabel = "\(building.address?.shortAddress() ?? "")"
            
            let userRef = Fire.base.users.document(user.id)
            let userData = user.toDictionary()
            
            
            if !livingSpace.linkedUserIDs.contains(user.id) {
                livingSpace.linkedUserIDs.append(user.id)
            }
            
            let roomRef = Fire.base.livingSpaces.document(livingSpace.id)
            let roomData = livingSpace.toDictionary()
            
            if let list = building.linkedUsersIDs {
                if  !list.contains(user.id) {
                    building.linkedUsersIDs?.append(user.id)
                }
            } else {
                building.linkedUsersIDs = [user.id]
            }
            
            let buildingRef = Fire.base.buildings.document(building.id)
            let buildingData = building.toDictionary()

            try? await userRef.setData(userData)
            try? await roomRef.setData(roomData)
            try? await buildingRef.setData(buildingData)
            
            completion()
        }
    }
    
    
    func saveData() {
        let db = Firestore.firestore()
        let id = livingSpace.id
        let ref = Fire.base.livingSpaces.document(id)
        let data = livingSpace.toDictionary()
        let batch = db.batch()
        let users = Fire.base.users.whereField("linkedLivingspaceID", isEqualTo: id)

        Task {
            batch.setData(data, forDocument: ref)
            
            let snaps = try await users.getDocuments().documents
            
            let newShortLS = "Top \(livingSpace.number)"
            snaps.forEach { snap in
                batch.updateData(["shortLivingSpaceLabel" : newShortLS], forDocument: snap.reference)
            }
            
            try await batch.commit()
            
            let usersCopy = self.users
            usersCopy.forEach {
                $0.shortLivingSpaceLabel = newShortLS
            }
            DispatchQueue.main.async {
                self.users = usersCopy
                self.objectWillChange.send()
            }
        }
    }
}

struct LivingSpaceDetails: View {
    @EnvironmentObject var user: UserEnv

    @StateObject var model: LivingSpaceDetailsModel
    @StateObject var buildingModel: BuildingDetailModel
    @State var showModel: Bool = false
    @State var showAlert: Bool = false

    var body: some View {
        List {
            
            Section {
                
                TextInput(text: $model.livingSpace.number,
                          title: "№: ").disabled(user.isAdmin == false)
                TextInput(text: $model.livingSpace.floor,
                          title: "Floor: ").disabled(user.isAdmin == false)
                TextInput(num: $model.livingSpace.maxUsersCount,
                          title: "Max residents: ").disabled(user.isAdmin == false)
                TextInput(num: $model.livingSpace.squareMeters,
                          title: "m2: ").disabled(user.isAdmin == false)
                TextInput(num: $model.livingSpace.roomsCount,
                          title: "Rooms: ").disabled(user.isAdmin == false)
                
                Button {
                    model.saveData()
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    self.showAlert.toggle()
                } label: {
                    Label("Save", systemImage: "icloud.and.arrow.up.fill")
                }.disabled(user.isAdmin == false)
            }
            
            Section("Files") {
                NavigationLink {
                    DocumentsView(model: .init(id: model.livingSpace.id), editble: user.isAdmin ?? false)
                } label: {
                    Label("Documents", systemImage: "doc.on.doc.fill")
                }
                NavigationLink {
                    PhotoGalleryView(model: .init(id: model.livingSpace.id), editble: user.isAdmin ?? false)
                } label: {
                    Label("Photos", systemImage: "photo.on.rectangle.angled")
                }
                NavigationLink {
//                    UserNotesView(model: .init(id: model.livingSpace.id), editble: user.isAdmin ?? false)
                } label: {
                    Label("Notes", systemImage: "note.text")
                }.foregroundColor(Color(UIColor.label))
            }.foregroundColor(Color(UIColor.label))
            
            Section("Residents") {
                ForEach($model.users) { $obj in
                    
                    NavigationLink {
                        ResidentProfileView(model: ResidentProfileModel(user: obj), editble: user.isAdmin ?? false)
                    } label: {
                        ResidentListItemView(model: .init(residentID: obj.id), resident: $obj)
                    }.contextMenu {
                        Button(action: {
                            model.unlinkUser(obj, completion: {
                                buildingModel.update()
                            })
                        }, label: {
                            Label("Unlink user", systemImage: "minus.circle.fill")
                        }).disabled(user.isAdmin == false)
                    }
                    
                }
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    self.showModel.toggle()
                } label: {
                    Label("Link user", systemImage: "plus.circle.fill")
                }.disabled(user.isAdmin == false)
            }
        }
        .navigationTitle("Living space")
        .sheet(isPresented: $showModel) {
            ResidentRemoteListSelectionView { selectedUser in
                self.model.updateUser(selectedUser, completion: {
                    buildingModel.update()
                })
            }
        }
        .toast(isPresenting: $showAlert) {
            AlertToast(displayMode: .alert, type: .complete(.green))
        }
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            model.fetch()
        }
        .onAppear {
            model.objectWillChange.send()
        }

    }
}

//#Preview {
//    LivingSpaceDetails()
//}
