import SwiftUI
import RealmSwift
import AlertToast

class ResidentDetailsModel: ObservableObject {
    
    @ObservedRealmObject var resident: Resident
    
    
    init(resident: Resident) {
        self.resident = resident
    }
    
    
    func update() {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: {
            withAnimation {
                self.objectWillChange.send()
            }
        })
    }
}

struct ResidentDetails: View {
    
    @EnvironmentObject var clipboard: InAppClipboard
    @StateObject var model: ResidentDetailsModel
    @State private var showingSheet = false
    @State var showAlert: Bool = false
    
    var body: some View {
        List {
            Section("Person") {
                HStack {
                    Text("First name").foregroundColor(Color(UIColor.secondaryLabel))
                    TextField("Name", text: $model.resident.firstName)
                }
                HStack {
                    Text("Second name").foregroundColor(Color(UIColor.secondaryLabel))
                    TextField("Name", text: $model.resident.secondName)
                }
            }
            
            Section("Living place") {
                if let shortAddress = model.resident.assignee.first?.address?.fullAddress() {
                    Text(shortAddress).font(.footnote)
                }
                Button(action: {
                    showingSheet.toggle()
                }, label: {
                    if let room = model.resident.livingSpace {
                        LivingSpaceListItem(livingSpace: room)
                    } else {
                        Text("Choose living space")
                    }
                })
            }
            
   
            Section("Data") {
                Button {
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = "\(self.model.resident.firstName) \(self.model.resident.secondName)"
                    clipboard.resident = model.resident
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    self.showAlert.toggle()
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.arrow.left.square")
                        Text("Copy to replace")
                    }
                }
                
                Button {
                    let pasteboard = UIPasteboard.general
                    let data = """
Name: \(self.model.resident.firstName) \(self.model.resident.secondName)
\(model.resident.assignee.first?.address?.fullAddress() ?? "no address")
Room № \(self.model.resident.livingSpace?.number ?? "no livingspace")
"""
                    pasteboard.string = data
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    self.showAlert.toggle()
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy full information")
                    }
                }
            }
            
        }
        .navigationTitle("Resident")
        .sheet(isPresented: $showingSheet) {
            LivingSpaceListModalView(resident: model.resident, onUpdate: {
                model.update()
            })
        }
        .toast(isPresenting: $showAlert) {
            AlertToast(displayMode: .alert, type: .complete(.green))
        }
    }
}

#Preview {
    ResidentDetails(model: .init(resident: Resident(firstName: "Denis", secondName: "Kotelnikov")))
}
