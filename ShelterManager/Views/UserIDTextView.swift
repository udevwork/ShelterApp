//
//  UserIDTextView.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 22.02.2024.
//

import SwiftUI

struct UserIDTextView: View {
    var id: String? = nil
    var alignment: TextAlignment = .center
    var body: some View {
        Text(id ?? (UserEnv.current?.uid ?? "-"))
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(alignment)
            .font(.system(size: 9))
            .listRowBackground(Color.clear)
            .foregroundStyle(Color.gray)
    }
}

#Preview {
    UserIDTextView()
}
