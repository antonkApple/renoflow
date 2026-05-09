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
                ContentUnavailableView("Project not found", systemImage: "folder.badge.questionmark")
            }
        }
        .navigationTitle(project?.name ?? "Project")
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
            }
        }
    }

    @ViewBuilder
    private func projectContent(_ project: ProjectEntity) -> some View {
        VStack(spacing: 0) {
            ProjectHeader(project: project) {
                showingAddItem = true
            }
            Picker("View", selection: $selection) {
                Text("Rooms").tag(0)
                Text("To Buy").tag(1)
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            if selection == 0 {
                if project.rooms.isEmpty {
                    ContentUnavailableView {
                        Label("No rooms yet", systemImage: "square.grid.2x2")
                    } description: {
                        Text("Create a room, then add products to track what you need to buy.")
                    } actions: {
                        Button("Add Room") { showingAddRoom = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section("Rooms") {
                            ForEach(project.rooms) { room in
                                NavigationLink {
                                    RoomView(projectID: project.id, room: room)
                                } label: {
                                    RoomRow(room: room)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                MetricBlock(title: "Progress", value: project.progress.formatted(.percent.precision(.fractionLength(0))))
                MetricBlock(title: "Spent", value: project.totalSpent.formatted(.currency(code: "USD")))
                MetricBlock(title: "Budget", value: project.totalBudget.formatted(.currency(code: "USD")))
            }
            ProgressView(value: project.progress)
            Button {
                onAddItem()
            } label: {
                Label("Add Item", systemImage: "cart.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
}

struct MetricBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RoomRow: View {
    let room: RoomEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(room.name).font(.headline)
                Spacer()
                Text("\(room.items.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("\(room.installedItems)/\(room.totalItems) installed", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if room.items.isEmpty {
                    Text("Tap to add products")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
            ProgressView(value: room.progress)
        }
        .padding(.vertical, 8)
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
        List {
            Section {
                Picker("Filter", selection: $filter) {
                    ForEach(ShoppingFilter.allCases) { filter in Text(filter.label).tag(filter) }
                }
                .pickerStyle(.segmented)
            }

            if rows.isEmpty {
                ContentUnavailableView {
                    Label("Nothing to buy yet", systemImage: "cart")
                } description: {
                    Text("Add items from a room or use the Add Item button on the project screen.")
                }
            } else {
                Section("Items") {
                    ForEach(rows, id: \.item.id) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(row.item.title).font(.headline)
                                Spacer()
                                Text("\(row.item.quantityRemaining.clean) \(row.item.unit) left")
                                    .font(.subheadline.weight(.semibold))
                            }
                            HStack {
                                Text(row.room.name)
                                if let store = row.item.preferredStoreName { Text(store) }
                                Spacer()
                                Text(row.item.price, format: .currency(code: "USD"))
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
