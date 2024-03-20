//
//  RemoteNamespace.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 07.03.2024.
//

import Foundation
import Firebase

class Remote {
    
}

extension Encodable {
    func toDictionary() -> [String: Any] {
        let data = try! JSONEncoder().encode(self)
        let jsonObject = try! JSONSerialization.jsonObject(with: data, options: [])
        let dict = jsonObject as! [String: Any]
        return dict
    }
}

extension QuerySnapshot {
    func decode<T: Decodable>() throws -> [T] {
        var items: [T] = []
        for document in documents {
            do {
                let item = try document.data(as: T.self)
                items.append(item)
            } catch {
                throw error
            }
        }
        return items
    }
}

extension DocumentSnapshot {
    func decode<T: Decodable>() throws -> T {
        var items: T

            do {
                let item = try self.data(as: T.self)
                items = item
            } catch {
                throw error
            }
        
        return items
    }
}

extension ProcessInfo {
   static func isOnPreview() -> Bool {
       return processInfo.processName == "XCPreviewAgent"
   }
}

extension Array where Element: Equatable {
    /// Добавляет элемент в массив, если такого элемента ещё нет.
    mutating func appendIfNotContains(_ element: Element) {
        if !self.contains(element) {
            self.append(element)
        }
    }
}
