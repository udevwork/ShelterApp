//
//  MapView.swift
//  AddressAutocomplete
//
//  Created by Maksim Kalik on 11/27/22.
//

import SwiftUI
import MapKit

struct MapView: View {
    
    @StateObject private var viewModel = MapViewModel()

    var address: Remote.Address?
    
 
    var body: some View {
        Map(
            coordinateRegion: $viewModel.region,
            annotationItems: viewModel.annotationItems,
            annotationContent: { item in
                MapMarker(coordinate: item.coordinate)
            }
        )
        .onAppear {
            if let address = address {
                self.viewModel.getPlace(from: address)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
