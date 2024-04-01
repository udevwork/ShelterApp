import SwiftUI

struct AddressAutocompleteModalView: View {
    
    @StateObject var viewModel: ContentViewModel
    @State private var isFocusedTextField: Bool = false
    @Binding var autocomplete: Remote.Address?
    
    @State var temp_autocomplete: Remote.Address?
    
    @Environment(\.dismiss) var dismiss

    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
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
                
                VStack {
                    Spacer()
                    VStack {
                        VStack(alignment: .leading, spacing: 15) {
                            
                            AddressListItemSmallView(address: temp_autocomplete)
                                .foregroundStyle(Color(uiColor: UIColor.label))
                                .frame(maxWidth: .infinity)
                            if temp_autocomplete != nil {
                                Button {
                                    autocomplete = temp_autocomplete
                                    dismiss()
                                } label: {
                                    
                                    Label("Apply this address", systemImage: "checkmark.circle.fill")
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(.gray.opacity(0.1))
                                        .cornerRadius(17)
                                        .disabled((temp_autocomplete == nil))
                                        .foregroundStyle((temp_autocomplete == nil) ? Color.gray : Color.accentColor)
                                    
                                }
                            }
                        }.padding()
                        
                    }.background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .padding(10)
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
