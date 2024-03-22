//
//  ContentView.swift
//  AddressAutocomplete
//
//  Created by Maksim Kalik on 11/27/22.
//

import SwiftUI

struct AddressAutocompleteModalView: View {
    
    @StateObject var viewModel: ContentViewModel
    @State private var isFocusedTextField: Bool = false
    @Binding var autocomplete: Remote.Address?
    
    @State var temp_autocomplete: Remote.Address?
    
    @Environment(\.dismiss) var dismiss

    
    var body: some View {
        NavigationStack {
           
            List {
                if autocomplete != nil {
                    Section ("Selected Address:"){
                    Button {
                        if temp_autocomplete == nil {
                            //autocomplete = address
                            temp_autocomplete = .init(title: viewModel.searchableText, subtitle: "")
                        }
                        autocomplete = temp_autocomplete
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            
                            AddressListItemView(address: temp_autocomplete).foregroundStyle(Color(uiColor: UIColor.label))
                            
                            Label("Apply selected address", systemImage: "checkmark.circle.fill")
                                .padding(14).background(.gray.opacity(0.1)).cornerRadius(13)
                        }
                    }
                }
                }
               
                if self.viewModel.results.isEmpty {
                    
                    Text("Search is empty").multilineTextAlignment(.center).frame(maxWidth: .infinity).foregroundStyle(.gray).listRowBackground(Color.clear)
                } else {
                    ForEach(self.viewModel.results) { address in
                        Button {
                            viewModel.searchableText = address.title + " " + address.subtitle
                            temp_autocomplete = address
                        } label: {
                            AddressListItemView(address: address).foregroundStyle(Color(uiColor: UIColor.label))
                        }
                    }
                }
            }.navigationBarTitle("Search", displayMode: .large)
            
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                    }
                }
               
        }
            .searchable(text: $viewModel.searchableText, isPresented: $isFocusedTextField, placement: .navigationBarDrawer(displayMode: .always))
            .onReceive(viewModel.$searchableText.debounce(for: .seconds(1), scheduler: DispatchQueue.main)) {
                viewModel.searchAddress($0)
            }
        
       
    }
    
    var backgroundColor: Color = Color.init(uiColor: .systemGray6)
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AddressAutocompleteModalView(viewModel: ContentViewModel(), autocomplete: .constant(Remote.Address())  )
    }
}
