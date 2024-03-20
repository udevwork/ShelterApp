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
            VStack {
                Image("icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150, alignment: .center)
                Text("New Green Home").font(.title)
                    .foregroundColor(Color.white)
                ProgressView()
                    .controlSize(.large)
            }.offset(y: 40)
         
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color("backcolor"))
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    LoadingView()
}
