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
        RenoPage(title: "Item Details", subtitle: item.title) {
            heroCard
            detailsSection
            purchaseSection
            buyingOptionsSection
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Save") {
                item.clampQuantities()
                store.saveItem(item, projectID: projectID, roomID: roomID)
                dismiss()
            }
            .foregroundStyle(RenoTheme.ColorToken.accent)
        }
        .sheet(isPresented: $showingAddOption) {
            NavigationStack {
                BuyingOptionEditor { option in
                    item.buyingOptions.append(option)
                    showingAddOption = false
                }
            }
            .presentationDetents([.medium, .large])
        }
        .tint(RenoTheme.ColorToken.accent)
    }

    private var heroCard: some View {
        RenoCard {
            HStack(alignment: .top, spacing: RenoTheme.Spacing.lg) {
                ProductImage(urlString: item.imageURL, size: 112)
                VStack(alignment: .leading, spacing: RenoTheme.Spacing.sm) {
                    Text(item.title)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(RenoTheme.ColorToken.text)
                    Text("\(item.price, format: .currency(code: "USD")) each · \(item.quantityNeeded.clean) \(item.unit)")
                        .font(.subheadline)
                        .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                    RenoStatusChip(status: item.status)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var detailsSection: some View {
        RenoSection(title: "Details") {
            RenoCard {
                RenoTextField(title: "Title", text: $item.title)
                RenoNumberField(title: "Price", value: $item.price)
                RenoNumberField(title: "Quantity needed", value: $item.quantityNeeded)
                RenoTextField(title: "Unit", text: $item.unit)
                VStack(alignment: .leading, spacing: RenoTheme.Spacing.xs) {
                    Text("Status")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                    Picker("Status", selection: $item.status) {
                        ForEach(ItemStatus.allCases) { status in
                            Text(status.label).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(RenoTheme.ColorToken.accent)
                }
                RenoTextField(title: "Notes", text: $item.notes, axis: .vertical)
            }
        }
    }

    private var purchaseSection: some View {
        RenoSection(title: "Purchase Progress") {
            RenoCard {
                HStack {
                    VStack(alignment: .leading, spacing: RenoTheme.Spacing.xs) {
                        Text("Purchased")
                            .font(.caption)
                            .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                        Text("\(item.quantityPurchased.clean) / \(item.quantityNeeded.clean) \(item.unit)")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(RenoTheme.ColorToken.text)
                    }
                    Spacer()
                    Text("\(item.quantityRemaining.clean) left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RenoTheme.ColorToken.accent)
                }
                RenoProgressBar(value: item.quantityNeeded == 0 ? 0 : min(item.quantityPurchased, item.quantityNeeded) / item.quantityNeeded)
                RenoNumberField(title: "Quantity purchased", value: $item.quantityPurchased)
            }
        }
    }

    private var buyingOptionsSection: some View {
        RenoSection(title: "Buying Options", actionTitle: "Add", action: { showingAddOption = true }) {
            if item.buyingOptions.isEmpty {
                RenoEmptyState(icon: "storefront", title: "No buying options", message: "Add stores or product links to compare prices before buying.", buttonTitle: "Add Option") {
                    showingAddOption = true
                }
            } else {
                VStack(spacing: RenoTheme.Spacing.md) {
                    ForEach(item.buyingOptions) { option in
                        BuyingOptionRow(option: option)
                    }
                }
            }
        }
    }
}

struct BuyingOptionRow: View {
    let option: BuyingOptionEntity

    var body: some View {
        RenoCard {
            HStack(spacing: RenoTheme.Spacing.md) {
                Image(systemName: "storefront")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(RenoTheme.ColorToken.accent)
                    .frame(width: 42, height: 42)
                    .background(RenoTheme.ColorToken.accentSoft, in: RoundedRectangle(cornerRadius: RenoTheme.Radius.sm, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.storeName)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(RenoTheme.ColorToken.text)
                    Text(option.price, format: .currency(code: option.currency ?? "USD"))
                        .font(.subheadline)
                        .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                }
                Spacer()
                if let url = URL(string: option.productURL) {
                    Link(destination: url) {
                        Image(systemName: "arrow.up.right")
                            .frame(width: 36, height: 36)
                            .background(RenoTheme.ColorToken.secondarySurface, in: Circle())
                    }
                    .foregroundStyle(RenoTheme.ColorToken.text)
                }
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
        RenoPage(title: "Buying Option", subtitle: "Add a store link for comparison.") {
            RenoCard {
                RenoTextField(title: "Store name", text: $storeName)
                RenoTextField(title: "Product URL", text: $productURL)
                    .textInputAutocapitalization(.never)
                RenoNumberField(title: "Price", value: $price)
                RenoTextField(title: "Currency", text: $currency)
            }
            Button("Save Option") {
                onSave(BuyingOptionEntity(storeName: storeName, productURL: productURL, price: price, currency: currency.isEmpty ? nil : currency))
            }
            .buttonStyle(RenoPrimaryButtonStyle())
            .disabled(storeName.isEmpty || productURL.isEmpty)
            .opacity(storeName.isEmpty || productURL.isEmpty ? 0.45 : 1)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Cancel") { dismiss() }
                .foregroundStyle(RenoTheme.ColorToken.accent)
        }
    }
}
