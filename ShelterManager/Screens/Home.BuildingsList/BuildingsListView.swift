import SwiftUI
import RealmSwift
import AlertToast

class BuildingsListModel: ObservableObject {
    let realm = try! Realm()
    @Published var buildingsList: [Building] = []
    @ObservedResults(Resident.self) var residents
    
    
    @ObservedResults(Resident.self) var findedResidents
    @ObservedResults(LivingSpace.self) var findedLivingSpace
    @ObservedResults(Building.self) var findedBuildings
    
    @Published var searchText = ""
    
    init(){
        update()
    }
    
    func createBuilding() {
     
        let building = Building(address: nil)
        try! realm.write {
            realm.add(building)
        }
        update()
    }
    
    func search(_ searchableText: String) {
        guard searchableText.isEmpty == false else { return }
    }
    
    func delete(building: Building){

        try! realm.write {
            building.thaw()?.deleted = true
            
        }
        
        self.update()
    }
    
    func update() {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
            withAnimation {
                self.buildingsList = Array(self.realm.objects(Building.self).filter("deleted == false"))
                //self.objectWillChange.send()
            }
        })
    }
    
    // can be optimized by create new value for counter and +/- on room created
    
    struct infoResult {
        let maxOfResepients: Int
        let totalResepients: Int
    }
    
    func culcMax() -> infoResult {
        var max: Int = 0
        var total: Int = 0
        buildingsList.forEach { build in
            max += build.culcMax()
            total += build.residents.count
        }
        return infoResult(maxOfResepients: max, totalResepients: total)
    }
}

struct BuildingsListView: View {
    
    @StateObject var model = BuildingsListModel()
    @State private var path = NavigationPath()
    @State private var searchIsActive = false
    
    @State private var showToast = false
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                
                if model.searchText.isEmpty == false {
                    Section("Search results") {
                        ForEach(model.findedBuildings.find(with:model.searchText)) { obj in
                            NavigationLink {
                                BuildingDetailView(model: .init(building: obj, onUpdate: {}))
                            } label: {
                                BuildingListItemView(building: obj)
                            }
                        }
                        
                        ForEach(model.findedResidents.find(with:model.searchText)) { obj in
                            NavigationLink {
                                ResidentDetails(model: .init(resident: obj))
                            } label: {
                                ResidentListItemView(resident: obj)
                            }
                        }
                        
                        ForEach(model.findedLivingSpace.find(with:model.searchText)) { obj in
                            NavigationLink {
                                LivingSpaceDetails(model: .init(livingSpace: obj))
                            } label: {
                                LivingSpaceListItem(livingSpace: obj)
                            }
                        }
                    }
                } else {
                    Section("Residents information for all buildings") {
                        let num = model.culcMax()
                        HStack (spacing: 10) {
                            Text("Maximum residents:")
                            Text("\(num.maxOfResepients)").bold()
                        }
                        
                        HStack (spacing: 10) {
                            Text("Total staing:")
                            Text("\(num.totalResepients)").bold()
                        }
                    }
                    Section("Buildings list") {
                        
                        ForEach(model.buildingsList, id: \._id) { buildingObj in
                            if !buildingObj.isInvalidated {
                                NavigationLink {
                                    BuildingDetailView(model: .init(building: buildingObj, onUpdate: {}))
                                } label: {
                                    BuildingListItemView(building: buildingObj)
                                        .contextMenu {
                                            Button {
                                                model.delete(building: buildingObj)
                                            } label: {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    
                    if model.residents.favorites().count > 0 {
                        Section("Favorites") {
                            ForEach(model.residents.favorites()) { obj in
                                NavigationLink {
                                    ResidentDetails(model: .init(resident: obj))
                                } label: {
                                    ResidentListItemView(resident: obj).contextMenu {
                                        Button {
                                            let realm = try! Realm()
                                            try! realm.write {
                                                obj.thaw()?.isFavorite.toggle()
                                            }
                                        } label: {
                                            if obj.isFavorite {
                                                Label("Remove from Favorites", systemImage: "heart.fill")
                                            } else {
                                                Label("Add to Favorites", systemImage: "heart")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Section("Favorites") {
                            Text("Favorite residents list is empty.").foregroundStyle(Color.gray)
                        }
                    }
                    
                    
                }
                
            }
            .navigationTitle("Buidlings")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        model.createBuilding()
                        self.showToast.toggle()
                    } label: {
                        Label("Add new", systemImage: "plus.circle.fill")
                    }
                }
            }
            .onAppear {
                model.update()
            }
        }.searchable(text: $model.searchText, isPresented: $searchIsActive, placement: .navigationBarDrawer)
        
            .onReceive(model.$searchText.debounce(for: .seconds(1), scheduler: DispatchQueue.main)) {
                model.search($0)
            }
            .toast(isPresenting: $showToast){
                AlertToast(type: .regular, title: "New building created")
            }
        
    }
}

#Preview {
    BuildingsListView()
}
