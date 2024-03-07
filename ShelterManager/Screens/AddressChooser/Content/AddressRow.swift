//
//  AddressRow.swift
//  AddressAutocomplete
//
//  Created by Maksim Kalik on 11/30/22.
//

import SwiftUI

struct AddressListItemView: View {
    
    @Binding var address: Address?
    
    var body: some View {
        if let address = address {
            if address.isEmpty() == false {
                NavigationLink {
                    MapView(address: address)
                } label: {
                    VStack(alignment: .leading) {
                        Text(address.title)
                        Text(address.subtitle)
                            .font(.caption)
                    }
                }
                .padding(.bottom, 2)
            } else {
                Text("Press to choose address")
            }
        } else {
            Text("Press to choose address")
        }
    }
}
