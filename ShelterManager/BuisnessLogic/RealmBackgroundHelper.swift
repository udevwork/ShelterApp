//
//  RealmBackgroundHelper.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 23.02.2024.
//

import Foundation
import RealmSwift

class RealmBackgroundHelper {
    func deleteAllMarkedDeletedObjects() {
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
