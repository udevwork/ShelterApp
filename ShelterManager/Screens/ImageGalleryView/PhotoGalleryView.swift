//
//  PhotoGalleryView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 10.03.2024.
//

import Foundation
import SwiftUI
import FirebaseStorage
import Firebase
import AlertToast
import Combine
import Kingfisher
import PhotosUI

class PhotoGalleryModel: ObservableObject {
    
    @Published var photos: [URL] = []
    @Published var loading: Bool = false
    @Published var fullSizeImage: URL? = nil
    @Published var isShowingFullScreen = false
    
    private let photoManager: PhotoUploaderManager
    
    var id: String
    
    init(id: String) {
        self.id = id
        self.photoManager = PhotoUploaderManager(id: id)
    }
    
    func loadPhotos() {
        loading = true
       
        Task {
            let thumbnailURLs = try await self.photoManager.loadPhotos()
            DispatchQueue.main.async {
                self.photos = thumbnailURLs
            }
            loading = false
        }
    }
    
    func uploadImage(imageData: Data) {
        loading = true
        Task {
            let thumbnailURL = try await self.photoManager.uploadImage(imageData: imageData)
            if let url = thumbnailURL {
                DispatchQueue.main.async {
                    self.photos.append(url)
                }
            }
            loading = false
        }
    }
    
    func getFullImageUrlFrom(url: URL) {
        loading = true
        Task {
            let url = try await self.photoManager.getFullImageUrlFrom(url: url)
            self.fullSizeImage = url
            self.isShowingFullScreen.toggle()
            loading = false
        }
    }
    
    func deleteImage(url: URL){
        loading = true
        if let index = self.photos.firstIndex(of: url) {
            self.photos.remove(at: index)
        }
        Task {
            try await self.photoManager.deleteImage(url: url)
            loading = false
        }
    }
    
}


struct PhotoGalleryView: View {
    @StateObject var model: PhotoGalleryModel
    @State private var avatarItem: PhotosPickerItem?
   // @State private var avatarImage: Image = Image("default-avatar")
    
    let imageSize = UIScreen.main.bounds.width/5
    
    let columns = [
        GridItem(.fixed((UIScreen.main.bounds.width/5))),
        GridItem(.fixed((UIScreen.main.bounds.width/5))),
        GridItem(.fixed((UIScreen.main.bounds.width/5))),
        GridItem(.fixed((UIScreen.main.bounds.width/5)))
    ]
    
    var body: some View {
        
        ScrollView {
            
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(model.photos, id: \.self) { url in
                    
                    KFImage.url(url)
                        .resizing(referenceSize: .init(width: imageSize, height: imageSize), mode: .aspectFill)
                        .placeholder({
                            Image("default-img")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageSize, height: imageSize)
                        })
                        .loadDiskFileSynchronously()
                        .cacheMemoryOnly()
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageSize + 15, height: imageSize)
                    
                        .mask {
                            Rectangle()
                                .frame(width: imageSize, height: imageSize)
                        }

                        .onTapGesture {
                            self.model.getFullImageUrlFrom(url: url)
                        }
                        .contextMenu {
                            Button {
                                model.deleteImage(url: url)
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                        
                }
            }
            .padding(5)
           
        }
        .toolbar(content: {
            HStack {
                Image(systemName: "plus.circle.fill")
                PhotosPicker("Upload photo", selection: $avatarItem, matching: .images)
                    .onChange(of: avatarItem) {
                        Task {
                            if let loaded = try? await avatarItem?.loadTransferable(type: Data.self) {
                                let cont = Image(uiImage: UIImage(data: loaded)!)
                                let renderer = ImageRenderer(content: cont)
                                let compression = UserDefaults.standard.bool(forKey: "extremeImageCompressionEnabled") ? 0.0 : 0.7
                                if let data = renderer.uiImage?.jpegData(compressionQuality: compression) {
                                    model.uploadImage(imageData: data)
                                }
                            } else {
                                print("Failed")
                            }
                        }
                    }
            }
        })
        .sheet(isPresented: $model.isShowingFullScreen) {
            VStack {
                if let url = model.fullSizeImage {
                    FullScreenImageView(url: url)
                } else {
                    Text("invalid url")
                }
            }
        }
        .navigationTitle("Gallery")
        
        .onAppear {
            model.loadPhotos()
        }
        .toast(isPresenting: $model.loading) {
            AlertToast(type: .loading, title: "Photo gallery", subTitle: "Loading")
        }
        
    }
}
