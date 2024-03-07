import SwiftUI
import RealmSwift
import Combine
import AlertToast

class BuildingDetailModel: ObservableObject {
    
    @ObservedRealmObject var building: Building
    
    enum Filter: String, CaseIterable, Identifiable {
        case roomNumber, fullFirst, emptyFirst, floor
        var id: Self { self }
    }
    
    @Published var selectedFlavor: Filter = .roomNumber

    private var cancellable: AnyCancellable?
    var onUpdate: (()->())? = nil
    
    init(building: Building, onUpdate: (()->())?) {
        self.building = building
        
        if self.building.address == nil {
            let realm = try! Realm()
            
            try! realm.write {
                let building = self.building.thaw()
                building?.address = Address()
            }
            
            update()
        }

    }
    
    func createLivingSpace(){
        let realm = try! Realm()
        let room = LivingSpace()
        
        try! realm.write {
            let building = self.building.thaw()
            building?.livingSpaces.append(room)
        }
        
        update()
    }
    
    func createResident() {
        let realm = try! Realm()
        let resident = Resident()
        
        try! realm.write {
            let building = self.building.thaw()
            building?.residents.append(resident)
        }
        
        update()
    }
    
    func copyToClipboard() {
        if let address = self.building.address?.fullAddress() {
            let pasteboard = UIPasteboard.general
            pasteboard.string = address
        }
    }
    
    func makeCopyOfResident(residentToCopy: Resident) {
        
        let realm = try! Realm()
        
        let newResident = Resident()
        newResident.secondName = residentToCopy.secondName
        
        try! realm.write {
            
            if let roomCopy = residentToCopy.livingSpace,
               let room = realm.object(ofType: LivingSpace.self, forPrimaryKey: roomCopy._id) {
                newResident.livingSpace = room
            }
            
            realm.add(newResident)
            let building = self.building.thaw()
            building?.residents.append(newResident)
        }
        
        update()
    }
    
    func addToFavorire(resident: Resident){
        let realm = try! Realm()
        try! realm.write {
            resident.thaw()?.isFavorite.toggle()
        }
    }
    
    func delete(resident: Resident){
        let realm = try! Realm()
        try! realm.write {
            if let objToDelete = realm.object(ofType: Resident.self, forPrimaryKey: resident._id) {
                realm.delete(objToDelete)
            } else {
                print("fuck")
            }
        }
        self.update()
    }

    func delete(livingSpace: LivingSpace){
        let realm = try! Realm()
        try! realm.write {
            if let objToDelete = realm.object(ofType: LivingSpace.self, forPrimaryKey: livingSpace._id) {
                realm.delete(objToDelete)
            } else {
                print("fuck")
            }
        }
        self.update()
    }
    
    func update() {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
            withAnimation {
                self.objectWillChange.send()
            }
        })
    }
}

struct BuildingDetailView: View {
    
    @EnvironmentObject var clipboard: InAppClipboard
   // @Environment(\.dismiss) private var dismiss
    @StateObject var model: BuildingDetailModel
    
    @State private var showToast = false
    
    enum ModelViews: String, Identifiable {
        case  city, optimizer
        
        var id: String { rawValue }
    }
    
    @State private var sheets : ModelViews? = nil

    var body: some View {
        
        List {
            Section("Building name") {
                HStack {
                    Text("Name:").foregroundColor(Color(UIColor.secondaryLabel))
                    TextField("building custom name", text: $model.building.customBuildingName)
                }
            }
            
            Section("Address") {
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        self.sheets = .city
                    } label: {
                        AddressListItemView(address: $model.building.address)
                    }
                }
              
            }
            
            Section("Total info for this building") {
                HStack(spacing: 10) {
                    Text("Living spaces:")
                    Text("\(model.building.livingSpaces.count)").bold()
                }
                HStack(spacing: 10) {
                    Text("Residents:")
                    Text("\(model.building.residents.count)").bold()
                }
            }
            
            Section("Living spaces") {
                
                Picker("Sorting", selection: $model.selectedFlavor) {
                    Text("Room number").tag(BuildingDetailModel.Filter.roomNumber)
                    Text("Full first").tag(BuildingDetailModel.Filter.fullFirst)
                    Text("Empty first").tag(BuildingDetailModel.Filter.emptyFirst)
                    Text("Floor").tag(BuildingDetailModel.Filter.floor)
                }
                
                HStack {
                    Text("Room №")
                    Spacer()
                    Text("current / max")
                }.font(.footnote).foregroundColor(.gray)
                
                ForEach(model.building.livingSpaces.sortingWith(filter: model.selectedFlavor)) { obj in
                    NavigationLink {
                        LivingSpaceDetails(model: .init(livingSpace: obj))
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
                
               
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    self.showToast.toggle()
                    model.createLivingSpace()
                } label: {
                    Label("Create new livingspace", systemImage: "plus.circle.fill")
                }

            }
            
            Section("Residents") {
                if let residentInClipboard = clipboard.resident {
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        self.showToast.toggle()
                        let realm = try! Realm()
                        if let residentInClipboard = residentInClipboard.thaw() {
                            if let oldBuilding = residentInClipboard.assignee.first(where: { b in
                                b.residents.firstIndex(of: residentInClipboard) != nil
                            }) {
                                if let indexToDelete =  oldBuilding.residents.firstIndex(of: residentInClipboard) {
                                    try! realm.write {
                                        oldBuilding.residents.remove(at: indexToDelete)
                                        residentInClipboard.livingSpace = nil
                                        model.building.thaw()?.residents.append(residentInClipboard)
                                        clipboard.resident = nil
                                        self.showToast.toggle()
                                    }
                                }
                            }
                        }
                    } label: {
                        Label("Append from clipboard", systemImage: "paperclip.circle.fill")
                    }
                }
                
                ForEach(model.building.residents.sorted(by: \.secondName)) { obj in
                    NavigationLink {
                        ResidentDetails(model: .init(resident: obj))
                    } label: {
                        ResidentListItemView(resident: obj).contextMenu {
                            Button {
                                model.addToFavorire(resident: obj)
                            } label: {
                                if obj.isFavorite {
                                    Label("Remove from Favorites", systemImage: "heart.fill")
                                } else {
                                    Label("Add to Favorites", systemImage: "heart")
                                }
                            }
                            Button {
                                model.makeCopyOfResident(residentToCopy: obj)
                            } label: {
                                Label("Create copy", systemImage: "doc.on.doc.fill")
                            }
                            
                            Button {
                                model.delete(resident: obj)
                            } label: {
                                Label("Delete", systemImage: "trash.fill").foregroundStyle(Color.red)
                            }
                        }
                    }
                }
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    self.showToast.toggle()
                    model.createResident()
                } label: {
                    Label("Create new resident", systemImage: "plus.circle.fill")
                }
            }
            
            Section("Data") {
                if let address = model.building.address {
                    NavigationLink {
                        MapView(address: address)
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse.circle.fill")
                            Text("Show on map")
                        }
                    }
                }
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    showToast.toggle()
                    model.copyToClipboard()
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy full address")
                    }
                }
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    self.sheets = .optimizer
                } label: {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Optimizer")
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(model.building.customBuildingName)
        .refreshable {
            model.update()
        }
        .onAppear(perform: {
            model.update()
        })
        .sheet(item: $sheets) {
            self.model.update()
            
        } content: { item in
            if item == .city {
                if self.model.building.address != nil {
                    AddressAutocompleteModalView(viewModel: .init(), autocomplete: $model.building.address)
                }
            }
            
            if item == .optimizer {
                BuildingOptimizedModalView(building: self.model.building)
            }
        }
        .toast(isPresenting: $showToast) {
            AlertToast(displayMode: .alert, type: .complete(.green))
        }
        
    }
}

#Preview {
    NavigationStack {
        BuildingDetailView(model: BuildingDetailModel.init(building: Building(address: Address()), onUpdate: {}))
    }
}
