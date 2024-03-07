//
//  DebugView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 14.02.2024.
//

import SwiftUI
import RealmSwift

class DebugViewModel: ObservableObject {
    
    @ObservedResults(Building.self) var buildings
    @ObservedResults(Address.self) var addresses
    @ObservedResults(LivingSpace.self) var rooms
    @ObservedResults(Resident.self) var residents
    
    @Published var filesInTempDir: [String] = []
    @Published var realmSize: String = ""
    
    func update() {
        printAllFilesInTemporaryDirectory()
        getRealmSize()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
            withAnimation {
                self.objectWillChange.send()
            }
        })
    }
    
    func deleteDataBase() {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    func getRealmSize() {
        if let realmURL = Realm.Configuration.defaultConfiguration.fileURL {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: realmURL.path)
                if let fileSize = fileAttributes[.size] as? NSNumber {
                    let sizeInBytes = fileSize.int64Value
                    let sizeInMB = Double(sizeInBytes) / (1024.0 * 1024.0)
                    print("Realm DB Size: \(sizeInMB) MB")
                    self.realmSize = "Realm DB Size: \(sizeInMB) MB"
                }
            } catch {
                print("Error getting Realm file size: \(error)")
            }
        }
    }
    
    func createMockup(){
        
        let firstNames = [
            "Aleksey", "Ivan", "Maksim", "Sergey", "Dmitriy",
            "Andrey", "Aleksandr", "Nikita", "Mikhail", "Pavel",
            "Roman", "Oleg", "Denis", "Kirill", "Egor",
            "Ilya", "Artem", "Vladimir", "Yuriy", "Grigoriy",
            "Viktor", "Petr", "Stepan", "Vasiliy", "Leonid",
            "Valeriy", "Boris", "Nikolay", "Timofey", "Georgiy"
        ]

        let lastNames = [
            "Ivanov", "Smirnov", "Kuznetsov", "Popov", "Vasilev",
            "Petrov"
        ]
        
        
        let buildings = [Building(address: Address(title: "Schneebergstraße 50", subtitle: "Grünbach am Schneeberg, Austria")),
                            Building(address: Address(title: "Schneebergstraße 10", subtitle: "Grünbach am Schneeberg, Austria")),
                            Building(address: Address(title: "789 Pine St", subtitle: "Villagetown"))]
           
           for (index, building) in buildings.enumerated() {
               // Добавление жилых пространств к каждому зданию
               for roomNumber in 1...Int.random(in: 5...10) {
                   let livingSpace = LivingSpace()
                   livingSpace.number = "\(roomNumber)"
                   livingSpace.floor = "\(Int.random(in: 1...5))"
                   livingSpace.maxResident = "\(Int.random(in: 1...5))"
                   
                   building.livingSpaces.append(livingSpace)
               }
               
               // Добавление жильцов к каждому зданию
               for residentIndex in 1...Int.random(in: 2...10) {
                   let resident = Resident(firstName: firstNames.randomElement() ?? "", secondName: lastNames.randomElement() ?? "")
                   if let livingSpace = building.livingSpaces.filter({ $0.assigneeResidents.count < Int($0.maxResident) ?? 1 }).first {
                       resident.livingSpace = livingSpace
                   }
                   building.residents.append(resident)
               }
           }
           
           
            let realm = try! Realm()
            try! realm.write {
                realm.add(buildings, update: .all)
            }
           
    }
    
    
    func printAllFilesInTemporaryDirectory() {
        let fileManager = FileManager.default
        let tempDirURL = fileManager.temporaryDirectory
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: tempDirURL, includingPropertiesForKeys: nil)
            
            if fileURLs.isEmpty {
                print("Временная директория пуста.")
            } else {
                print("Файлы во временной директории:")
                for fileURL in fileURLs {
                    print(fileURL.lastPathComponent)
                    filesInTempDir.append(fileURL.lastPathComponent)
                }
            }
        } catch {
            print("Ошибка при получении содержимого временной директории: \(error)")
        }
    }
    
    func clearTemporaryDirectory() {
        let tempFolderPath = NSTemporaryDirectory()
        let fileManager = FileManager.default
        do {
            let tempFiles = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
            for file in tempFiles {
                let filePath = (tempFolderPath as NSString).appendingPathComponent(file)
                try fileManager.removeItem(atPath: filePath)
            }
            print("Временная директория очищена.")
        } catch {
            print("Ошибка при очистке временной директории: \(error)")
        }
    }
    
}

struct DebugView: View {
    
    @StateObject var model = DebugViewModel()
    
    var body: some View {
        List {
           
            
            Section {
                Button("Create mock data", action: model.createMockup)
            } footer: {
                Text("Fill database with fake data")
            }
            
            Section() {
                ForEach(model.filesInTempDir, id: \.self) { path in
                    Text(path).foregroundStyle(Color.gray)
                }
                Button {
                    model.clearTemporaryDirectory()
                } label: {
                    Text("Clear temp directory")
                }
            } header: {
                Text("Temporary Directory")
            } footer: {
                Text(FileManager.default.temporaryDirectory.absoluteString)
            }

            Section() {
                Button {
                    RealmBackgroundHelper().deleteAllMarkedDeletedObjects()
                } label: {
                    Text("Delete all marked deleted objects")
                }
                Button("Delete RealmDB file",role: .destructive, action: model.deleteDataBase)
            } header: {
                Text("Realm")
            } footer: {
                Text(model.realmSize)
            }

            Section ("buildings") {
                ForEach(model.buildings) { obj in
                    VStack(alignment: .leading) {
                        HStack {
                            if obj.deleted {
                                Image(systemName: "trash.fill").foregroundStyle(Color.red).font(.footnote)
                            }
                            Text(obj.address?.fullAddress() ?? "empty building")
                        }
                        Text("Rooms count: \(obj.livingSpaces.count)")
                    }
                }
            }
            
            Section ("addresses") {
                ForEach(model.addresses) { obj in
                    Text(obj.fullAddress())
                }
            }
            Section ("Rooms") {
                ForEach(model.rooms) { obj in
                    VStack(alignment: .leading) {
                        if let building = obj.assigneeBuilding.first {
                            if let address = building.address {
                                Text(address.fullAddress())
                            } else {
                                Text("no address attached to building")
                            }
                        } else {
                            Text("no building associated")
                        }
                        
                        Text(obj.number)
                    }
                }
            }
            Section ("Residents") {
                ForEach(model.residents) { obj in
                    Text(obj.fullName())
                }
            }
            UserIDTextView(id: UserEnv.current?.uid)
            
        }
        .navigationTitle("Develpment")
        .refreshable {
            model.update()
        }
    }
}

#Preview {
    DebugView()
}
