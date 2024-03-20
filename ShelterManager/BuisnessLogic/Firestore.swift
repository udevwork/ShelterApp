//
//  Firestore.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 08.03.2024.
//

import Foundation
import FirebaseFirestore

class Fire {
    
    static var base = Fire()
    
    let db = Firestore.firestore()
    
    lazy var addresses = db.collection("Addresses")
    lazy var livingSpaces = db.collection("LivingSpaces")
    lazy var buildings = db.collection("Buildings")
    lazy var users = db.collection("Users")
    lazy var notes = db.collection("Notes")
    lazy var deletedUsers = db.collection("DeletedUsers")

    private init() {
        
    }
    
}
