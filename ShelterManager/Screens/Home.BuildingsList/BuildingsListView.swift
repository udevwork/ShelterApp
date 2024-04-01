import SwiftUI
import RealmSwift
import AlertToast
import FirebaseFirestore
import Firebase
import FirebaseStorage

class BuildingsListModel: ObservableObject {
    
    struct infoResult {
        var maxOfResepients: Int
        var totalResepients: Int
    }
    
    @Published var buildings: [Remote.Building] = []
    @Published var users: Int = 0
    @Published var maxUsers: Int = 0
    
    init() {
        fetch()
    }
    
    func fetch() {
        Task {
            let decoded: [Remote.Building] = try await Fire.base.buildings.getDocuments().decode()
            DispatchQueue.main.async {
                self.buildings = decoded
            }
            try await fetchLivingSpases()
        }
    }
    
    func fetchLivingSpases() async throws {
        
        let snap = try await Fire.base.livingSpaces.getDocuments()
        let rooms: [Remote.LivingSpace] = try snap.decode()
        
        var buildingsDict: [String: infoResult] = [:]
        self.buildings.forEach {
            buildingsDict[$0.id] = infoResult(maxOfResepients: 0, totalResepients: 0)
        }
        
        var temp_users: Int = 0
        var temp_maxUsers: Int = 0
        
        rooms.forEach { room in
            temp_users += room.linkedUserIDs.count
            temp_maxUsers += room.maxUsersCount
            
            // findBuilding
            let buildingID = room.linkedBuildingID
            buildingsDict[buildingID]?.maxOfResepients += room.linkedUserIDs.count
            buildingsDict[buildingID]?.totalResepients += room.maxUsersCount
        }
        
        buildingsDict.forEach { (key: String, value: infoResult) in
            
            let building = self.buildings.first {
                $0.id == key
            }
            
            DispatchQueue.main.async {
                building?.max = value.maxOfResepients
                building?.total = value.totalResepients
                self.objectWillChange.send()
            }
        }
        DispatchQueue.main.async { [temp_users, temp_maxUsers] in
            self.users = temp_users
            self.maxUsers = temp_maxUsers
        }
    }
    
    func createBuilding() {
        let newBuilding = Remote.Building()
        let data = newBuilding.toDictionary()
        let ref = Fire.base.buildings.document(newBuilding.id)
        ref.setData(data)
        self.buildings.append(newBuilding)
    }
    
    func search(_ searchableText: String) {
        guard searchableText.isEmpty == false else { return }
    }
    
    func delete(building: Remote.Building){
        
        let deletedBuildingID = building.id
        let batch = Fire.base.db.batch() 
    
        Task {
            batch.deleteDocument(Fire.base.buildings.document(deletedBuildingID))
            
            let usersSnap = try await Fire.base.users.whereField("linkedBuildingID", isEqualTo: deletedBuildingID).getDocuments().documents
            
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
            
            let livingSpacesSnap = try await Fire.base.livingSpaces.whereField("linkedBuildingID", isEqualTo: deletedBuildingID).getDocuments().documents
          
            livingSpacesSnap.forEach { snap in
                batch.deleteDocument(snap.reference)
            }
            
            try await batch.commit()
            
            // delete notes
            await Remote.Note.deleteNotes(for: deletedBuildingID)
            
            // delete from ui
            if let indexToDelete = self.buildings.firstIndex(where: { $0.id == deletedBuildingID }) {
                DispatchQueue.main.async {
                    self.buildings.remove(at: indexToDelete)
                }
            }
     
        }
        
    }
    
    func update() {
        
    }
    
}

struct BuildingsListView: View {
    
    @EnvironmentObject var user: UserEnv

    @StateObject var model = BuildingsListModel()
    @State private var path = NavigationPath()
    @State private var searchIsActive = false
    
    @State private var showToast = false
    
    var body: some View {
        NavigationStack(path: $path) {
            List {                
                Section {
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        model.createBuilding()
                        self.showToast.toggle()
                    } label: {
                        Label("Add building", systemImage: "plus.circle.fill")
                    }.disabled(user.isAdmin == false)
                }
                
                Section  {
                    
                    ForEach($model.buildings, id: \.foreachid) { $obj in
                        NavigationLink {
                            BuildingDetailView(model: .init(building: obj, onUpdate: {}))
                        } label: {
                            BuildingListItemView(model: .init(buildingID: $obj.id), building: $obj)
                                .contextMenu {
                                    Button {
                                        model.delete(building: obj)
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }.disabled(user.isAdmin == false)
                                }
                        }
                    }
                } header: {
                    HStack (spacing: 10) {
                        Image(systemName: "person.2.fill").imageScale(.small)
                        Text("TOTAL: \(model.users) / \(model.maxUsers)")
                        Spacer()
                    }
                }
            }
            .navigationTitle("New Green Home")
            .refreshable {
                model.fetch()
            }
        }
        .toast(isPresenting: $showToast){
            AlertToast(type: .regular, title: "New building created")
        }
        
    }
}

#Preview {
    BuildingsListView()
}
