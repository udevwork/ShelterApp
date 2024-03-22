//
//  PhotoUploaderManager.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 13.03.2024.
//

import Foundation
import UIKit
import FirebaseStorage

class PhotoUploaderManager {
    
    private let store = Storage.storage()
    let id: String
    
    init(id: String) {
        self.id = id
    }
    
    func loadPhotos() async throws -> [URL] {
        let storageRef = store.reference(withPath: "photos/\(id)/thumbnail/")
        
        let images = try await storageRef.listAll()
        var imageUrls: [URL] = []
        for id in images.items {
            let url = try await id.downloadURL()
            imageUrls.append(url)
        }
        return imageUrls
    }
    
    func uploadImage(imageData: Data) async throws -> URL?  {
        let photoName = UUID().uuidString
        let imageRef = store.reference().child("photos/\(id)/full/\(photoName).jpg")
        
        // Загрузка данных
        _ = try await imageRef.putDataAsync(imageData)
        
        // Загрузка данных
        let size = UserDefaults.standard.bool(forKey: "extremeImageCompressionEnabled") ? 100 : 250
        if let miniData = resizeImageData(imageData, targetSize: .init(width: size, height: size)) {
            let miniImageRef = store.reference().child("photos/\(id)/thumbnail/\(photoName).jpg")
            _ = try await miniImageRef.putDataAsync(miniData)
            return try await miniImageRef.downloadURL()
        }
        return nil
    }
    
    func getFullImageUrlFrom(url: URL) async throws -> URL? {
        let photoName = url.lastPathComponent
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let filePath = "photos/\(id)/full/\(photoName)"
        let fileRef = storageRef.child(filePath)
        return try await fileRef.downloadURL()
    }
    
    func deleteImage(url: URL) async throws {
        let photoName = url.lastPathComponent
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        let fullRef = storageRef.child("photos/\(id)/full/\(photoName)")
        let thumbnailRef = storageRef.child("photos/\(id)/thumbnail/\(photoName)")
        
        try await fullRef.delete()
        try await thumbnailRef.delete()
    }
    
    // AVATAR
    
    func uploadAvatar(imageData: Data) async throws -> URL?  {
//        let photoName = UUID().uuidString
        let imageRef = store.reference().child("avatars/\(id)/full/avatar.jpg")
        
     
        // Загрузка данных
        _ = try await imageRef.putDataAsync(imageData)
        
        // Загрузка данных
        let size = UserDefaults.standard.bool(forKey: "extremeImageCompressionEnabled") ? 100 : 250
        if let miniData = resizeImageData(imageData, targetSize: .init(width: size, height: size)) {
            let miniImageRef = store.reference().child("avatars/\(id)/thumbnail/avatar.jpg")
            _ = try await miniImageRef.putDataAsync(miniData)
            return try await miniImageRef.downloadURL()
        }
        return nil
    }
    
    func getFullAvatarUrlFrom(url: URL) async throws -> URL? {
//        let photoName = url.lastPathComponent
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let filePath = "avatars/\(id)/full/avatar.jpg"
        let fileRef = storageRef.child(filePath)
        return try await fileRef.downloadURL()
    }
    
    func loadAvatar() async throws -> URL {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let filePath = "avatars/\(id)/thumbnail/avatar.jpg"
        let fileRef = storageRef.child(filePath)
        return try await fileRef.downloadURL()
    }
    
    
    
    private func resizeImageData(_ data: Data, targetSize: CGSize) -> Data? {
        // Преобразуем данные в UIImage
        guard let image = UIImage(data: data) else {
            return nil
        }
        
        let size = image.size
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // Изменение размера изображения
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()

            // Учитываем ориентацию исходного изображения
            let orientedImage = UIImage(cgImage: newImage.cgImage!, scale: 1.0, orientation: image.imageOrientation)

            // Возвращаем изменённые данные с учётом ориентации
            let compression = UserDefaults.standard.bool(forKey: "extremeImageCompressionEnabled") ? 0.5 : 1.0
            return orientedImage.jpegData(compressionQuality: compression)
        } else {
            UIGraphicsEndImageContext()
            return nil
        }
    }
}
