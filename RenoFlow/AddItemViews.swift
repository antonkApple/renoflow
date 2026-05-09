import SwiftUI

struct AddItemSearchView: View {
    @EnvironmentObject private var store: RenoFlowStore
    @Environment(\.dismiss) private var dismiss
    let projectID: UUID
    let room: RoomEntity
    @State private var query = ""
    @State private var selectedStore: Store?
    @State private var browserURL: URL?
    @State private var draft: ParsedItemDraft?
    @State private var isParsing = false

    var body: some View {
        List {
            Section("Search") {
                TextField("Search Google or selected store", text: $query)
                    .textInputAutocapitalization(.never)
                Button("Open Search") { openSearch() }
                    .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section("Suggestions") {
                ForEach(room.defaultSearchQueries, id: \.self) { suggestion in
                    Button(suggestion) {
                        query = suggestion
                        openSearch()
                    }
                }
            }
            Section("Stores") {
                Button("Google") { selectedStore = nil }
                    .fontWeight(selectedStore == nil ? .semibold : .regular)
                ForEach(store.stores) { option in
                    Button(option.name) { selectedStore = option }
                        .fontWeight(selectedStore?.id == option.id ? .semibold : .regular)
                }
            }
        }
        .navigationTitle("Add Item")
        .toolbar { Button("Done") { dismiss() } }
        .sheet(item: $browserURL) { url in
            NavigationStack {
                ProductWebView(url: url) { selectedURL in
                    Task { await parse(selectedURL) }
                }
            }
        }
        .sheet(item: $draft) { draft in
            NavigationStack {
                AddItemConfirmationView(projectID: projectID, roomID: room.id, draft: draft)
            }
        }
        .overlay {
            if isParsing { ProgressView("Reading product page").padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8)) }
        }
    }

    private func openSearch() {
        if let selectedStore {
            browserURL = selectedStore.searchURL(for: query)
        } else {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            browserURL = URL(string: "https://www.google.com/search?q=\(encoded)")
        }
    }

    private func parse(_ url: URL) async {
        isParsing = true
        let storeName = store.storeName(for: url)
        draft = await ItemParser.parse(url: url, storeName: storeName)
        isParsing = false
    }
}

struct AddItemConfirmationView: View {
    @EnvironmentObject private var store: RenoFlowStore
    @Environment(\.dismiss) private var dismiss
    let projectID: UUID
    let roomID: UUID
    let draft: ParsedItemDraft
    @State private var mode: ConfirmationMode = .newItem
    @State private var title: String
    @State private var price: Double
    @State private var quantityNeeded = 1.0
    @State private var unit = "pcs"
    @State private var notes = ""
    @State private var selectedItemID: UUID?

    init(projectID: UUID, roomID: UUID, draft: ParsedItemDraft) {
        self.projectID = projectID
        self.roomID = roomID
        self.draft = draft
        _title = State(initialValue: draft.title)
        _price = State(initialValue: draft.price ?? 0)
    }

    private var existingItems: [ItemEntity] {
        store.projects.first(where: { $0.id == projectID })?.rooms.first(where: { $0.id == roomID })?.items ?? []
    }

    var body: some View {
        Form {
            Picker("Save as", selection: $mode) {
                Text("New Item").tag(ConfirmationMode.newItem)
                Text("Buying Option").tag(ConfirmationMode.buyingOption)
            }
            .pickerStyle(.segmented)

            if mode == .newItem {
                Section("Item") {
                    TextField("Title", text: $title)
                    TextField("Price", value: $price, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Quantity needed", value: $quantityNeeded, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Unit", text: $unit)
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            } else {
                Section("Existing Item") {
                    Picker("Item", selection: $selectedItemID) {
                        Text("Choose item").tag(Optional<UUID>.none)
                        ForEach(existingItems) { item in Text(item.title).tag(Optional(item.id)) }
                    }
                }
                Section("Buying Option") {
                    LabeledContent("Store", value: draft.storeName)
                    TextField("Price", value: $price, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
        }
        .navigationTitle("Confirm Item")
        .toolbar {
            Button("Cancel") { dismiss() }
            Button("Save") { save() }
                .disabled(mode == .buyingOption && selectedItemID == nil)
        }
    }

    private func save() {
        var option = draft.buyingOption
        option.price = price
        if mode == .newItem {
            var item = ItemEntity(title: title, price: price, quantityNeeded: quantityNeeded, quantityPurchased: 0, unit: unit, url: draft.productURL, imageURL: draft.imageURL, localImagePath: nil, notes: notes, status: .planned, buyingOptions: [option])
            item.clampQuantities()
            store.saveItem(item, projectID: projectID, roomID: roomID)
        } else if let selectedItemID {
            store.attachBuyingOption(option, to: selectedItemID, projectID: projectID, roomID: roomID)
        }
        dismiss()
    }
}
