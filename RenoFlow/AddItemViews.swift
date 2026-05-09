import SwiftUI

struct AddItemRoomPickerView: View {
    let project: ProjectEntity
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRoomID: UUID?

    private var selectedRoom: RoomEntity? {
        project.rooms.first(where: { $0.id == selectedRoomID }) ?? project.rooms.first
    }

    var body: some View {
        RenoPage(title: "Add Item", subtitle: "Choose where this product should live.") {
            RenoSection(title: "Room") {
                VStack(spacing: RenoTheme.Spacing.sm) {
                    ForEach(project.rooms) { room in
                        Button {
                            selectedRoomID = room.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(room.name)
                                        .font(.system(.headline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(RenoTheme.ColorToken.text)
                                    Text("\(room.items.count) saved products")
                                        .font(.caption)
                                        .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                                }
                                Spacer()
                                if selectedRoom?.id == room.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(RenoTheme.ColorToken.accent)
                                }
                            }
                            .padding(RenoTheme.Spacing.lg)
                            .renoCardStyle()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let selectedRoom {
                NavigationLink {
                    AddItemSearchView(projectID: project.id, room: selectedRoom)
                } label: {
                    Label("Search Products", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RenoPrimaryButtonStyle())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Done") { dismiss() }
                .foregroundStyle(RenoTheme.ColorToken.accent)
        }
        .onAppear {
            selectedRoomID = selectedRoomID ?? project.rooms.first?.id
        }
    }
}

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
        RenoPage(title: "Find Products", subtitle: "Save products from stores into \(room.name).") {
            searchCard
            suggestionsSection
            storesSection
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Done") { dismiss() }
                .foregroundStyle(RenoTheme.ColorToken.accent)
        }
        .sheet(item: $browserURL) { url in
            NavigationStack {
                ProductWebView(url: url) { selectedURL in
                    Task { await parse(selectedURL) }
                }
            }
            .presentationDetents([.large])
        }
        .sheet(item: $draft) { draft in
            NavigationStack {
                AddItemConfirmationView(projectID: projectID, roomID: room.id, draft: draft)
            }
            .presentationDetents([.large])
        }
        .overlay {
            if isParsing {
                ProgressView("Reading product page")
                    .padding(RenoTheme.Spacing.lg)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: RenoTheme.Radius.md, style: .continuous))
            }
        }
    }

    private var searchCard: some View {
        RenoCard {
            VStack(alignment: .leading, spacing: RenoTheme.Spacing.md) {
                HStack(spacing: RenoTheme.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(RenoTheme.ColorToken.tertiaryText)
                    TextField("Search for sink, tile, faucet...", text: $query)
                        .textInputAutocapitalization(.never)
                        .font(.system(.body, design: .rounded))
                }
                .padding(RenoTheme.Spacing.md)
                .background(RenoTheme.ColorToken.secondarySurface, in: RoundedRectangle(cornerRadius: RenoTheme.Radius.md, style: .continuous))

                Button {
                    openSearch()
                } label: {
                    Label(selectedStore == nil ? "Search Google" : "Search \(selectedStore?.name ?? "Store")", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RenoPrimaryButtonStyle())
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            }
        }
    }

    private var suggestionsSection: some View {
        RenoSection(title: "Suggestions") {
            FlowLayout(spacing: RenoTheme.Spacing.sm) {
                ForEach(room.defaultSearchQueries, id: \.self) { suggestion in
                    Button(suggestion) {
                        query = suggestion
                        openSearch()
                    }
                    .buttonStyle(RenoSecondaryButtonStyle())
                }
            }
        }
    }

    private var storesSection: some View {
        RenoSection(title: "Stores") {
            VStack(spacing: RenoTheme.Spacing.sm) {
                StoreChoiceRow(name: "Google", isSelected: selectedStore == nil) {
                    selectedStore = nil
                }
                ForEach(store.stores) { option in
                    StoreChoiceRow(name: option.name, isSelected: selectedStore?.id == option.id) {
                        selectedStore = option
                    }
                }
            }
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

struct StoreChoiceRow: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(name)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(RenoTheme.ColorToken.text)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(RenoTheme.ColorToken.accent)
                }
            }
            .padding(RenoTheme.Spacing.md)
            .background(RenoTheme.ColorToken.surface, in: RoundedRectangle(cornerRadius: RenoTheme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
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
        RenoPage(title: "Save Product", subtitle: draft.storeName) {
            RenoCard {
                ProductImage(urlString: draft.imageURL, size: 120)
                RenoSegmentedPicker(selection: $mode) {
                    Text("New Item").tag(ConfirmationMode.newItem)
                    Text("Option").tag(ConfirmationMode.buyingOption)
                }
            }

            if mode == .newItem {
                itemFields
            } else {
                buyingOptionFields
            }

            Button("Save") { save() }
                .buttonStyle(RenoPrimaryButtonStyle())
                .disabled(mode == .buyingOption && selectedItemID == nil)
                .opacity(mode == .buyingOption && selectedItemID == nil ? 0.45 : 1)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Cancel") { dismiss() }
                .foregroundStyle(RenoTheme.ColorToken.accent)
        }
    }

    private var itemFields: some View {
        RenoSection(title: "Item Details") {
            RenoCard {
                RenoTextField(title: "Title", text: $title)
                RenoNumberField(title: "Price", value: $price)
                RenoNumberField(title: "Quantity needed", value: $quantityNeeded)
                RenoTextField(title: "Unit", text: $unit)
                RenoTextField(title: "Notes", text: $notes, axis: .vertical)
            }
        }
    }

    private var buyingOptionFields: some View {
        RenoSection(title: "Attach to Item") {
            RenoCard {
                Picker("Item", selection: $selectedItemID) {
                    Text("Choose item").tag(Optional<UUID>.none)
                    ForEach(existingItems) { item in
                        Text(item.title).tag(Optional(item.id))
                    }
                }
                .tint(RenoTheme.ColorToken.accent)
                RenoNumberField(title: "Price", value: $price)
            }
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

struct RenoTextField: View {
    let title: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: RenoTheme.Spacing.xs) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RenoTheme.ColorToken.secondaryText)
            TextField(title, text: $text, axis: axis)
                .padding(RenoTheme.Spacing.md)
                .background(RenoTheme.ColorToken.secondarySurface, in: RoundedRectangle(cornerRadius: RenoTheme.Radius.md, style: .continuous))
        }
    }
}

struct RenoNumberField: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: RenoTheme.Spacing.xs) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RenoTheme.ColorToken.secondaryText)
            TextField(title, value: $value, format: .number)
                .keyboardType(.decimalPad)
                .padding(RenoTheme.Spacing.md)
                .background(RenoTheme.ColorToken.secondarySurface, in: RoundedRectangle(cornerRadius: RenoTheme.Radius.md, style: .continuous))
        }
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var rows: [CGFloat] = [0]
        var currentWidth: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > width, currentWidth > 0 {
                totalHeight += (rows.last ?? 0) + spacing
                rows.append(size.height)
                currentWidth = size.width + spacing
            } else {
                rows[rows.count - 1] = max(rows.last ?? 0, size.height)
                currentWidth += size.width + spacing
            }
        }
        totalHeight += rows.last ?? 0
        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x + size.width > bounds.maxX, origin.x > bounds.minX {
                origin.x = bounds.minX
                origin.y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: origin, proposal: ProposedViewSize(size))
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
