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
        do {
            let realm = try Realm() // Безопасное получение экземпляра Realm
            
            // Находим все объекты, которые нужно удалить.
            let objectsToDelete = realm.objects(Building.self).filter("deleted == true")

            try realm.write {
                // Удаляем объекты.
                realm.delete(objectsToDelete)
            }
            print("Все обьекты удалены")
        } catch {
            print("Ошибка при работе с базой данных Realm: \(error)")
        }
    }
}
