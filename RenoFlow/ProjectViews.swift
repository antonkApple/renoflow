import SwiftUI

struct ProjectView: View {
    @EnvironmentObject private var store: RenoFlowStore
    let project: ProjectEntity
    @State private var selection = 0
    @State private var showingAddRoom = false
    @State private var newRoomName = ""

    private var liveProject: ProjectEntity { store.projects.first(where: { $0.id == project.id }) ?? project }

    var body: some View {
        VStack(spacing: 0) {
            ProjectHeader(project: liveProject)
            Picker("View", selection: $selection) {
                Text("Rooms").tag(0)
                Text("To Buy").tag(1)
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            if selection == 0 {
                List {
                    ForEach(liveProject.rooms) { room in
                        NavigationLink {
                            RoomView(projectID: liveProject.id, room: room)
                        } label: {
                            RoomRow(room: room)
                        }
                    }
                }
            } else {
                ShoppingListView(project: liveProject)
            }
        }
        .navigationTitle(liveProject.name)
        .toolbar {
            Button {
                showingAddRoom = true
            } label: {
                Label("Add Room", systemImage: "plus")
            }
        }
        .alert("Add Room", isPresented: $showingAddRoom) {
            TextField("Room name", text: $newRoomName)
            Button("Cancel", role: .cancel) { newRoomName = "" }
            Button("Save") {
                let name = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
                store.addRoom(to: liveProject.id, named: name.isEmpty ? "New Room" : name)
                newRoomName = ""
            }
        }
    }
}

struct ProjectHeader: View {
    let project: ProjectEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                MetricBlock(title: "Progress", value: project.progress.formatted(.percent.precision(.fractionLength(0))))
                MetricBlock(title: "Spent", value: project.totalSpent.formatted(.currency(code: "USD")))
                MetricBlock(title: "Budget", value: project.totalBudget.formatted(.currency(code: "USD")))
            }
            ProgressView(value: project.progress)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(room.name).font(.headline)
                Spacer()
                Text("\(room.installedItems)/\(room.totalItems) installed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: room.progress)
        }
        .padding(.vertical, 4)
    }
}

struct ShoppingListView: View {
    let project: ProjectEntity
    @State private var filter: ShoppingFilter = .missing

    private var rows: [(room: RoomEntity, item: ItemEntity)] {
        project.toBuyItems.filter { _, item in
            switch filter {
            case .missing: item.quantityPurchased == 0
            case .partial: item.quantityPurchased > 0 && item.quantityPurchased < item.quantityNeeded
            case .allNeeded: item.quantityPurchased < item.quantityNeeded
            case .fullyPurchased: item.isFullyPurchased
            }
        }.sorted { $0.room.name == $1.room.name ? $0.item.title < $1.item.title : $0.room.name < $1.room.name }
    }

    var body: some View {
        List {
            Picker("Filter", selection: $filter) {
                ForEach(ShoppingFilter.allCases) { filter in Text(filter.label).tag(filter) }
            }
            .pickerStyle(.segmented)

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
