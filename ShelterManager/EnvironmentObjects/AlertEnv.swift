//
//  AlertEnv.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 21.02.2024.
//

import SwiftUI
import AlertToast

class AlertEnv: ObservableObject {
    
    static var shared: AlertEnv = AlertEnv()
    
    private init(){ }
    
    @Published var showAlert: Bool = false
    @Published var title: String = ""
    @Published var subtitle: String = ""
    @Published var type: AlertToast.AlertType = .loading
    
    func show(title: String, subtitle: String, type: AlertToast.AlertType = .loading){
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.showAlert.toggle()
    }
    
    func hide(){
        self.showAlert = false
    }
}
