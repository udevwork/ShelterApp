//
//  FullScreenImageModifier.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 09.03.2024.
//

import SwiftUI
import Kingfisher

struct FullScreenModifier: ViewModifier {
    @State private var isShowingFullScreen = false
    let image: Image
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                self.isShowingFullScreen.toggle()
            }
            .sheet(isPresented: $isShowingFullScreen) {
                VStack {
                    Spacer()
                    self.image
                        .resizable()
                        .scaledToFit()
                        .edgesIgnoringSafeArea(.all)
                    Spacer()
                    Button("Close") {
                        self.isShowingFullScreen.toggle()
                    }
                    .padding()
                }
            }
    }
}

struct FullScreenURLModifier: ViewModifier {
    @State private var isShowingFullScreen = false

    let url: URL?
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                self.isShowingFullScreen.toggle()
            }
            .sheet(isPresented: $isShowingFullScreen) {
                VStack {
                    if let url = url {
                        FullScreenImageView(url: url)
                    } else {
                        Text("invalid url")
                    }
                    Button("Close") {
                        self.isShowingFullScreen.toggle()
                    }
                    .padding()
                }
            }
    }
}




extension View {
    func fullScreenableImage(_ image: Image) -> some View {
        self.modifier(FullScreenModifier(image: image))
    }
    
    func fullScreenableImage(_ url: URL?) -> some View {
        self.modifier(FullScreenURLModifier(url: url))
    }
}
