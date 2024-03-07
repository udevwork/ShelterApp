//
//  LoadingView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 20.02.2024.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            Image("AppIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200, alignment: .center)
            Text("Shelter Manager").font(.title)
        }
    }
}

#Preview {
    LoadingView()
}
