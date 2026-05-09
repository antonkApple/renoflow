import SwiftUI

struct StoreManagementView: View {
    @EnvironmentObject private var store: RenoFlowStore
    @State private var editingStore: Store?
    @State private var showingAddStore = false

    var body: some View {
        RenoPage(title: "Stores", subtitle: "Choose where RenoFlo searches for products.") {
            RenoSection(title: "Saved Stores", actionTitle: "Add", action: { showingAddStore = true }) {
                VStack(spacing: RenoTheme.Spacing.md) {
                    ForEach(store.stores) { item in
                        StoreRow(store: item) {
                            editingStore = item
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingAddStore = true
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(RenoIconButtonStyle())
        }
        .sheet(isPresented: $showingAddStore) {
            NavigationStack {
                StoreEditor(storeDraft: Store(id: UUID().uuidString, name: "", baseURL: "", searchURLTemplate: nil, isPreset: false)) {
                    store.addStore($0)
                    showingAddStore = false
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $editingStore) { item in
            NavigationStack {
                StoreEditor(storeDraft: item) {
                    store.updateStore($0)
                    editingStore = nil
                }
            }
            .presentationDetents([.medium, .large])
        }
        .tint(RenoTheme.ColorToken.accent)
    }
}

struct StoreRow: View {
    let store: Store
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RenoCard {
                HStack(spacing: RenoTheme.Spacing.md) {
                    Image(systemName: "storefront")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(RenoTheme.ColorToken.accent)
                        .frame(width: 42, height: 42)
                        .background(RenoTheme.ColorToken.accentSoft, in: RoundedRectangle(cornerRadius: RenoTheme.Radius.sm, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(store.name)
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundStyle(RenoTheme.ColorToken.text)
                            if store.isPreset {
                                Text("Preset")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(RenoTheme.ColorToken.secondarySurface, in: Capsule())
                            }
                        }
                        Text(store.baseURL)
                            .font(.caption)
                            .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(RenoTheme.ColorToken.tertiaryText)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct StoreEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var storeDraft: Store
    let onSave: (Store) -> Void

    var body: some View {
        RenoPage(title: "Store", subtitle: "Add a search template for quick product browsing.") {
            RenoCard {
                RenoTextField(title: "Name", text: $storeDraft.name)
                RenoTextField(title: "Base URL", text: $storeDraft.baseURL)
                    .textInputAutocapitalization(.never)
                RenoTextField(title: "Search URL template", text: Binding(get: { storeDraft.searchURLTemplate ?? "" }, set: { storeDraft.searchURLTemplate = $0.isEmpty ? nil : $0 }))
                    .textInputAutocapitalization(.never)
            }
            Button("Save Store") {
                onSave(storeDraft)
            }
            .buttonStyle(RenoPrimaryButtonStyle())
            .disabled(storeDraft.name.isEmpty || storeDraft.baseURL.isEmpty)
            .opacity(storeDraft.name.isEmpty || storeDraft.baseURL.isEmpty ? 0.45 : 1)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Cancel") { dismiss() }
                .foregroundStyle(RenoTheme.ColorToken.accent)
        }
    }
}
