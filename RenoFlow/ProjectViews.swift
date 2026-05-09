import SwiftUI

struct ProjectView: View {
    @EnvironmentObject private var store: RenoFlowStore
    let projectID: UUID
    @State private var selection = 0
    @State private var showingAddRoom = false
    @State private var showingAddItem = false
    @State private var newRoomName = ""

    private var project: ProjectEntity? {
        store.projects.first(where: { $0.id == projectID })
    }

    var body: some View {
        Group {
            if let project {
                projectContent(project)
            } else {
                RenoPage(title: "Project") {
                    RenoEmptyState(icon: "folder.badge.questionmark", title: "Project not found", message: "This project is no longer available.")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddItem = true
                    } label: {
                        Label("Add Item", systemImage: "cart.badge.plus")
                    }
                    Button {
                        showingAddRoom = true
                    } label: {
                        Label("Add Room", systemImage: "square.grid.2x2")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(RenoIconButtonStyle())
                .disabled(project == nil)
            }
        }
        .alert("Add Room", isPresented: $showingAddRoom) {
            TextField("Room name", text: $newRoomName)
            Button("Cancel", role: .cancel) { newRoomName = "" }
            Button("Save") {
                let name = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
                store.addRoom(to: projectID, named: name.isEmpty ? "New Room" : name)
                newRoomName = ""
            }
        }
        .sheet(isPresented: $showingAddItem) {
            if let project {
                NavigationStack {
                    AddItemRoomPickerView(project: project)
                }
                .presentationDetents([.large])
            }
        }
        .tint(RenoTheme.ColorToken.accent)
    }

    private func projectContent(_ project: ProjectEntity) -> some View {
        RenoPage(title: project.name) {
            ProjectHeader(project: project) {
                showingAddItem = true
            }

            RenoSegmentedPicker(selection: $selection) {
                Text("Rooms").tag(0)
                Text("To Buy").tag(1)
            }

            if selection == 0 {
                RoomsCollection(project: project, onAddRoom: { showingAddRoom = true })
            } else {
                ShoppingListView(project: project)
            }
        }
    }
}

struct ProjectHeader: View {
    let project: ProjectEntity
    let onAddItem: () -> Void

    var body: some View {
        RenoCard {
            VStack(alignment: .leading, spacing: RenoTheme.Spacing.lg) {
                HStack(spacing: RenoTheme.Spacing.md) {
                    MetricBlock(title: "Progress", value: project.progress.formatted(.percent.precision(.fractionLength(0))))
                    MetricBlock(title: "Spent", value: project.totalSpent.formatted(.currency(code: "USD")))
                    MetricBlock(title: "Budget", value: project.totalBudget.formatted(.currency(code: "USD")))
                }
                RenoProgressBar(value: project.progress)
                Button {
                    onAddItem()
                } label: {
                    Label("Add Item", systemImage: "cart.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RenoPrimaryButtonStyle())
            }
        }
    }
}

struct MetricBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: RenoTheme.Spacing.xs) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RenoTheme.ColorToken.tertiaryText)
            Text(value)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(RenoTheme.ColorToken.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RoomsCollection: View {
    let project: ProjectEntity
    let onAddRoom: () -> Void

    var body: some View {
        RenoSection(title: "Rooms", actionTitle: "Add Room", action: onAddRoom) {
            if project.rooms.isEmpty {
                RenoEmptyState(
                    icon: "square.grid.2x2",
                    title: "No rooms yet",
                    message: "Create a room, then collect products and track purchase progress.",
                    buttonTitle: "Add Room",
                    action: onAddRoom
                )
            } else {
                VStack(spacing: RenoTheme.Spacing.md) {
                    ForEach(project.rooms) { room in
                        NavigationLink {
                            RoomView(projectID: project.id, room: room)
                        } label: {
                            RoomRow(room: room)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct RoomRow: View {
    let room: RoomEntity

    var body: some View {
        RenoCard {
            VStack(alignment: .leading, spacing: RenoTheme.Spacing.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: RenoTheme.Spacing.xs) {
                        Text(room.name)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(RenoTheme.ColorToken.text)
                        Text(room.items.isEmpty ? "Ready for product ideas" : "\(room.items.count) products")
                            .font(.subheadline)
                            .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(RenoTheme.ColorToken.tertiaryText)
                }
                RenoProgressBar(value: room.progress, height: 7)
                HStack {
                    Label("\(room.installedItems)/\(room.totalItems) installed", systemImage: "checkmark.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                    Spacer()
                    if room.items.isEmpty {
                        Text("Add products")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RenoTheme.ColorToken.accent)
                    }
                }
            }
        }
    }
}

struct ShoppingListView: View {
    let project: ProjectEntity
    @State private var filter: ShoppingFilter = .allNeeded

    private var rows: [(room: RoomEntity, item: ItemEntity)] {
        let allRows: [(room: RoomEntity, item: ItemEntity)] = project.rooms.flatMap { room in
            room.items.map { item in (room: room, item: item) }
        }
        let filteredRows = allRows.filter { row in
            switch filter {
            case .missing:
                return row.item.quantityPurchased == 0
            case .partial:
                return row.item.quantityPurchased > 0 && row.item.quantityPurchased < row.item.quantityNeeded
            case .allNeeded:
                return row.item.quantityPurchased < row.item.quantityNeeded
            case .fullyPurchased:
                return row.item.isFullyPurchased
            }
        }
        return filteredRows.sorted { lhs, rhs in
            if lhs.room.name == rhs.room.name {
                return lhs.item.title < rhs.item.title
            }
            return lhs.room.name < rhs.room.name
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RenoTheme.Spacing.lg) {
            RenoSegmentedPicker(selection: $filter) {
                ForEach(ShoppingFilter.allCases) { filter in
                    Text(filter.label).tag(filter)
                }
            }

            if rows.isEmpty {
                RenoEmptyState(
                    icon: "cart",
                    title: "Nothing to buy yet",
                    message: "Save products from stores into rooms, then RenoFlo will show what is still missing."
                )
            } else {
                RenoSection(title: "Items") {
                    VStack(spacing: RenoTheme.Spacing.md) {
                        ForEach(rows, id: \.item.id) { row in
                            ShoppingListRow(room: row.room, item: row.item)
                        }
                    }
                }
            }
        }
    }
}
struct ShoppingListRow: View {
    let room: RoomEntity
    let item: ItemEntity

    var body: some View {
        RenoCard {
            VStack(alignment: .leading, spacing: RenoTheme.Spacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(RenoTheme.ColorToken.text)
                        Text(room.name)
                            .font(.caption)
                            .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                    }
                    Spacer()
                    Text("\(item.quantityRemaining.clean) \(item.unit)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RenoTheme.ColorToken.accent)
                }
                HStack {
                    if let store = item.preferredStoreName {
                        Label(store, systemImage: "storefront")
                    }
                    Spacer()
                    Text(item.price, format: .currency(code: "USD"))
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(RenoTheme.ColorToken.secondaryText)
            }
        }
    }
}

