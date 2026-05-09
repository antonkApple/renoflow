import SwiftUI

struct RoomView: View {
    @EnvironmentObject private var store: RenoFlowStore
    let projectID: UUID
    let room: RoomEntity
    @State private var showingAddItem = false

    private var liveRoom: RoomEntity {
        store.projects.first(where: { $0.id == projectID })?.rooms.first(where: { $0.id == room.id }) ?? room
    }

    var body: some View {
        List {
            Section {
                ForEach(liveRoom.items) { item in
                    NavigationLink {
                        ItemDetailView(projectID: projectID, roomID: liveRoom.id, item: item)
                    } label: {
                        ItemRow(projectID: projectID, roomID: liveRoom.id, item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(liveRoom.name)
        .toolbar {
            Button {
                showingAddItem = true
            } label: {
                Label("Add Item", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showingAddItem) {
            NavigationStack {
                AddItemSearchView(projectID: projectID, room: liveRoom)
            }
        }
    }
}

struct ItemRow: View {
    @EnvironmentObject private var store: RenoFlowStore
    let projectID: UUID
    let roomID: UUID
    let item: ItemEntity

    var body: some View {
        HStack(spacing: 12) {
            KFImage(URL(string: item.imageURL ?? ""))
                .placeholder { Color(.tertiarySystemFill).overlay(Image(systemName: "photo").foregroundStyle(.secondary)) }
                .fade(duration: 0.2)
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title).font(.headline)
                        Text("\(item.price, format: .currency(code: "USD")) each")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(status: item.status)
                }
                HStack {
                    Text("\(item.quantityPurchased.clean) / \(item.quantityNeeded.clean) purchased")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Button {
                        store.updatePurchased(projectID: projectID, roomID: roomID, itemID: item.id, delta: -1)
                    } label: {
                        Image(systemName: "minus.circle")
                    }
                    .disabled(item.quantityPurchased <= 0)
                    Button {
                        store.updatePurchased(projectID: projectID, roomID: roomID, itemID: item.id, delta: 1)
                    } label: {
                        Label("+1", systemImage: "plus.circle.fill")
                    }
                    .disabled(item.quantityPurchased >= item.quantityNeeded)
                }
                ProgressView(value: item.quantityNeeded == 0 ? 0 : item.quantityPurchased / item.quantityNeeded)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: ItemStatus

    var body: some View {
        Text(status.label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(status.color)
            .background(status.color.opacity(0.12), in: Capsule())
    }
}
