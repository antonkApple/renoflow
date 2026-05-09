import SwiftUI

struct StoreManagementView: View {
    @EnvironmentObject private var store: RenoFlowStore
    @State private var editingStore: Store?
    @State private var showingAddStore = false

    var body: some View {
        List {
            ForEach(store.stores) { item in
                Button {
                    editingStore = item
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.name).font(.headline)
                            if item.isPreset { Text("Preset").font(.caption2).foregroundStyle(.secondary) }
                        }
                        Text(item.baseURL).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete(perform: store.deleteStores)
        }
        .navigationTitle("Stores")
        .toolbar { Button("Add") { showingAddStore = true } }
        .sheet(isPresented: $showingAddStore) {
            NavigationStack {
                StoreEditor(storeDraft: Store(id: UUID().uuidString, name: "", baseURL: "", searchURLTemplate: nil, isPreset: false)) {
                    store.addStore($0)
                    showingAddStore = false
                }
            }
        }
        .sheet(item: $editingStore) { item in
            NavigationStack {
                StoreEditor(storeDraft: item) {
                    store.updateStore($0)
                    editingStore = nil
                }
            }
        }
    }
}

struct StoreEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var storeDraft: Store
    let onSave: (Store) -> Void

    var body: some View {
        Form {
            TextField("Name", text: $storeDraft.name)
            TextField("Base URL", text: $storeDraft.baseURL)
                .textInputAutocapitalization(.never)
            TextField("Search URL template", text: Binding(get: { storeDraft.searchURLTemplate ?? "" }, set: { storeDraft.searchURLTemplate = $0.isEmpty ? nil : $0 }))
                .textInputAutocapitalization(.never)
            Toggle("Preset", isOn: $storeDraft.isPreset)
                .disabled(true)
        }
        .navigationTitle("Store")
        .toolbar {
            Button("Cancel") { dismiss() }
            Button("Save") { onSave(storeDraft) }
                .disabled(storeDraft.name.isEmpty || storeDraft.baseURL.isEmpty)
        }
    }
}
