//
//  SliderGalleryImageView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 30.03.2024.
//

import SwiftUI

import Foundation
import SwiftUI
import Kingfisher
import AlertToast

public struct SliderItemView: View {
    
    var url: URL
    
    @State var fullurl: URL? = nil
    
    @State var resultImage: UIImage?
    
    func getFullImageUrlFrom() {
        if fullurl != nil {
            return
        }
        Task {
            if let url = try await self.photoManager.getFullImageUrlFrom(url: url){
                DispatchQueue.main.async {
                    self.fullurl = url
                }
            }
        }
    }
    
    let photoManager: PhotoUploaderManager
    
    // Gestures
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGPoint = .zero
    @State private var lastTranslation: CGSize = .zero
    
    var currentImage: (UIImage)->()
    
    init(url: URL, id: String, currentImage: @escaping (UIImage)->()) {
        self.url = url
        self.photoManager = PhotoUploaderManager(id: id)
        self.currentImage = currentImage
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                if fullurl != nil {
                    if scale > 1 {
                        KFImage(fullurl)
                            .loadDiskFileSynchronously()
                            .cacheMemoryOnly()
                            .fade(duration: 0.25)
                            .placeholder({
                                KFImage(url)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            })
                            .onSuccess({ img in
                                print("LOADED FULL IMAGE!")
                                if let cgimg = img.image.cgImage {
                                    self.resultImage = UIImage(cgImage: cgimg)
                                }
                            })
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(x: offset.x, y: offset.y)
                            .gesture(makeDragGesture(size: proxy.size))
         
                    } else {
                        KFImage(fullurl)
                            .loadDiskFileSynchronously()
                            .cacheMemoryOnly()
                            .onSuccess({ img in
                                print("LOADED FULL IMAGE!")
                                if let cgimg = img.image.cgImage {
                                    self.resultImage = UIImage(cgImage: cgimg)
                                }
                            })
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                } else {
                    KFImage(url)
                        .loadDiskFileSynchronously()
                        .cacheMemoryOnly()
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            } .gesture(makeMagnificationGesture(size: proxy.size))
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                self.getFullImageUrlFrom()
                if let img = resultImage {
                    currentImage(img)
                }
            }
        }
    }
    
    
    private func makeMagnificationGesture(size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                
                // To minimize jittering
                if abs(1 - delta) > 0.01 {
                    scale *= delta
                }
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 {
                    withAnimation {
                        scale = 1
                    }
                }
                adjustMaxOffset(size: size)
            }
    }
    
    private func makeDragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
          
                let diff = CGPoint(
                    x: value.translation.width - lastTranslation.width,
                    y: value.translation.height - lastTranslation.height
                )
                offset = .init(x: offset.x + diff.x, y: offset.y + diff.y)
                lastTranslation = value.translation
            }
            .onEnded { _ in
                adjustMaxOffset(size: size)
            }
    }
    
    private func adjustMaxOffset(size: CGSize) {
        let maxOffsetX = (size.width * (scale - 1)) / 2
        let maxOffsetY = (size.height * (scale - 1)) / 2
        
        var newOffsetX = offset.x
        var newOffsetY = offset.y
        
        if abs(newOffsetX) > maxOffsetX {
            newOffsetX = maxOffsetX * (abs(newOffsetX) / newOffsetX)
        }
        if abs(newOffsetY) > maxOffsetY {
            newOffsetY = maxOffsetY * (abs(newOffsetY) / newOffsetY)
        }
        
        let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)
        if newOffset != offset {
            withAnimation {
                offset = newOffset
            }
        }
        self.lastTranslation = .zero
    }
    
}

public struct SliderGalleryImageView: View {
    
    var urls: [URL]
    @State var resultImage: UIImage? = nil
    @Binding var selectedItem: Int
    @Environment(\.dismiss) var dismiss
    @State private var okAlert: Bool = false
    var id: String
    
    public var body: some View {
        NavigationStack {
            
            TabView(selection: $selectedItem) {
                ForEach(Array(urls.enumerated()), id: \.element) {  index, item in
               
                    SliderItemView(url: item, id: self.id, currentImage: { img in
                        self.resultImage = img
                    }).tag(index)
                    
                }
                .tabViewStyle(PageTabViewStyle())
                .padding(.vertical, 20)
                .toast(isPresenting: $okAlert) {
                    AlertToast(displayMode: .alert, type: .complete(.green))
                }
            }
   
            .tabViewStyle(PageTabViewStyle())
            .navigationTitle("Slider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                Button {
                    dismiss()
                } label: {
                    Label {
                        Text("close")
                    } icon: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    
                }
                
                Button {
                    guard let image = resultImage else { return }
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    okAlert.toggle()
                } label: {
                    Label {
                        Text("save")
                    } icon: {
                        Image(systemName: "square.and.arrow.down.fill")
                    }
                    
                }
                
            }
        }
    }
    
    private func convert(image: Image, callback: @escaping ((UIImage?) -> Void)) {
        DispatchQueue.main.async {
            let renderer = ImageRenderer(content: image)
            callback(renderer.uiImage)
        }
    }
 
}
