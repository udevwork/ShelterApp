//
//  AddressRow.swift
//  AddressAutocomplete
//
//  Created by Maksim Kalik on 11/30/22.
//

import SwiftUI



struct AddressListItemWithMapView: View {
      
    @Binding var address: Remote.Address?

    var body: some View {
        if let address = address {
            if address.isEmpty() == false {
                NavigationLink {
                    MapView(address: address)
                } label: {
                    AddressListItemView(address: address)
                        .foregroundColor(Color(uiColor: UIColor.label))
                }
               
            } else {
                Text("Press to choose address")
            }
        } else {
            Text("Press to choose address")
        }
    }
}

struct AddressListItemView: View {
    
    var address: Remote.Address?
    
    var body: some View {
        if let address = address {
            
            VStack(alignment: .leading,spacing: 10) {
                HStack(spacing: 15 ) {
                    Image(systemName: "map.fill")
                    HStack(spacing:2) {
                        Text(address.title).bold()
                    }
                }
                Text(address.subtitle).font(.footnote).foregroundStyle(.secondary).bold()
            }
    
        } else {
            Text("No address").foregroundColor(Color(UIColor.secondaryLabel))
        }
    }
}

struct AddressListItemSmallView: View {
    
    var address: Remote.Address?
    
    var body: some View {
        if let address = address {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 15 ) {
                    Image(systemName: "map.fill")
                    Text(address.title)
                        .multilineTextAlignment(.leading)
                        .bold()
                    Spacer()
                }
            }
        } else {
            HStack(spacing: 15 ) {
                Image(systemName: "map.fill").opacity(0.5)
                Text("Search and select address")
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                   Spacer()
            }
        }
    }
}
