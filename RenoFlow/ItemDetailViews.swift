import SwiftUI

struct ItemDetailView: View {
    @EnvironmentObject private var store: RenoFlowStore
    @Environment(\.dismiss) private var dismiss
    let projectID: UUID
    let roomID: UUID
    @State private var item: ItemEntity
    @State private var showingAddOption = false

    init(projectID: UUID, roomID: UUID, item: ItemEntity) {
        self.projectID = projectID
        self.roomID = roomID
        _item = State(initialValue: item)
    }

    var body: some View {
        Form {
            Section {
                KFImage(URL(string: item.imageURL ?? ""))
                    .placeholder { Color(.tertiarySystemFill).overlay(Image(systemName: "photo")) }
                    .fade(duration: 0.2)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Section("Item") {
                TextField("Title", text: $item.title)
                TextField("Price", value: $item.price, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Quantity needed", value: $item.quantityNeeded, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Quantity purchased", value: $item.quantityPurchased, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Unit", text: $item.unit)
                Picker("Status", selection: $item.status) {
                    ForEach(ItemStatus.allCases) { status in Text(status.label).tag(status) }
                }
                TextField("Notes", text: $item.notes, axis: .vertical)
            }
            Section("Purchase Progress") {
                LabeledContent("Purchased", value: "\(item.quantityPurchased.clean) / \(item.quantityNeeded.clean) \(item.unit)")
                LabeledContent("Remaining", value: "\(item.quantityRemaining.clean) \(item.unit)")
                ProgressView(value: item.quantityNeeded == 0 ? 0 : min(item.quantityPurchased, item.quantityNeeded) / item.quantityNeeded)
            }
            Section("Buying Options") {
                ForEach(item.buyingOptions) { option in
                    BuyingOptionRow(option: option)
                }
                Button("Add Buying Option") { showingAddOption = true }
            }
        }
        .navigationTitle("Item Details")
        .toolbar {
            Button("Save") {
                item.clampQuantities()
                store.saveItem(item, projectID: projectID, roomID: roomID)
                dismiss()
            }
        }
        .sheet(isPresented: $showingAddOption) {
            NavigationStack {
                BuyingOptionEditor { option in
                    item.buyingOptions.append(option)
                    showingAddOption = false
                }
            }
        }
    }
}

struct BuyingOptionRow: View {
    let option: BuyingOptionEntity

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(option.storeName).font(.headline)
                Text(option.price, format: .currency(code: option.currency ?? "USD"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let url = URL(string: option.productURL) {
                Link(destination: url) { Label("View", systemImage: "safari") }
            }
        }
    }
}

struct BuyingOptionEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storeName = ""
    @State private var productURL = ""
    @State private var price = 0.0
    @State private var currency = "USD"
    let onSave: (BuyingOptionEntity) -> Void

    var body: some View {
        Form {
            TextField("Store name", text: $storeName)
            TextField("Product URL", text: $productURL)
                .textInputAutocapitalization(.never)
            TextField("Price", value: $price, format: .number)
                .keyboardType(.decimalPad)
            TextField("Currency", text: $currency)
        }
        .navigationTitle("Buying Option")
        .toolbar {
            Button("Cancel") { dismiss() }
            Button("Save") {
                onSave(BuyingOptionEntity(storeName: storeName, productURL: productURL, price: price, currency: currency.isEmpty ? nil : currency))
            }
            .disabled(storeName.isEmpty || productURL.isEmpty)
        }
    }
}
