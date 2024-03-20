//
//  TextInput.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 12.03.2024.
//

import SwiftUI

struct TextInput: View {
    
    private enum InputType {
        case text, number, float, nonEditble
    }
    
    var title: String
    var placeholder: String
    var systemImage: String?
    
    @Binding var text: String
    @Binding var num: Int
    @Binding var num_float: Float
    
    private var type: InputType = .number
    
    // not editble
    init(text: String?, title: String, placeholder: String = "Empty", systemImage: String? = nil) {
        self.title = title
        self.placeholder = placeholder
        self.systemImage = systemImage
        self._num_float = .constant(0)
        self._text = .constant(text ?? "")
        self._num = .constant(0)
        type = .nonEditble
    }
    
    init(text: Binding<String>, title: String, placeholder: String = "Empty", systemImage: String? = nil) {
        self.title = title
        self.placeholder = placeholder
        self.systemImage = systemImage
        self._num_float = .constant(0)
        self._text = text
        self._num = .constant(0)
        type = .text
    }
    
    init(num: Binding<Int>, title: String, placeholder: String = "Empty", systemImage: String? = nil) {
        self.title = title
        self.placeholder = placeholder
        self.systemImage = systemImage
        self._num_float = .constant(0)
        self._num = num
        self._text = .constant("")
        type = .number
    }
    
    init(num: Binding<Float>, title: String, placeholder: String = "Empty", systemImage: String? = nil) {
        self.title = title
        self.placeholder = placeholder
        self.systemImage = systemImage
        self._num_float = num
        self._num = .constant(0)
        self._text = .constant("")
        type = .float
    }
    
    var body: some View {
        HStack {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                 
            }
            Text(title)
            
            if type == .nonEditble {
                TextField(placeholder, text: $text).bold().disabled(true)
            }
            
            if type == .text {
                TextField(placeholder, text: $text).bold()
            }
            
            if type == .number {
                TextField(placeholder, value: $num, format: .number).keyboardType(.decimalPad).bold()
            }
            
            if type == .float {
                TextField(placeholder, value: $num_float, format: .number).keyboardType(.decimalPad).bold()
            }

        }
    }
}