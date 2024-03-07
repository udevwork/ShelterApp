//
//  InAppClipboard.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 17.02.2024.
//

import Foundation
import RealmSwift
import Combine

class InAppClipboard: ObservableObject {
    @Published var resident: Resident?
    
}
