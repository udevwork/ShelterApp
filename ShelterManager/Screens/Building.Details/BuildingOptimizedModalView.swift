//
//  BuildingOptimizedModalView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 18.02.2024.
//

import SwiftUI
import RealmSwift

struct BuildingOptimizedModalView: View {
    
    @ObservedRealmObject var building: Building
    @State var results: [String] = []
    var body: some View {
       
        List {
            Section {
                Button {
                    let pasteboard = UIPasteboard.general
                    let data = results.joined(separator: "\n")
                    pasteboard.string = data
                } label: {
                    Text("Copy text")
                }

            }
            ForEach(results, id: \.self) { str in
                Text(str)
            }
        }.onAppear {
            let optimizer = FlatsOptimizer(building: building)
            self.results = optimizer.test()
        }
    }
}

#Preview {
    BuildingOptimizedModalView(building: Building())
}
