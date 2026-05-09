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
        RenoPage(title: liveRoom.name, subtitle: roomSubtitle) {
            if liveRoom.items.isEmpty {
                RenoEmptyState(
                    icon: "cart.badge.plus",
                    title: "Collect products for this room",
                    message: "Search stores, save product pages, and compare buying options before purchasing.",
                    buttonTitle: "Add Item"
                ) {
                    showingAddItem = true
                }
            } else {
                RenoSection(title: "Products", actionTitle: "Add Item", action: { showingAddItem = true }) {
                    VStack(spacing: RenoTheme.Spacing.md) {
                        ForEach(liveRoom.items) { item in
                            NavigationLink {
                                ItemDetailView(projectID: projectID, roomID: liveRoom.id, item: item)
                            } label: {
                                ItemCard(projectID: projectID, roomID: liveRoom.id, item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingAddItem = true
            } label: {
                Image(systemName: "cart.badge.plus")
            }
            .buttonStyle(RenoIconButtonStyle())
        }
        .sheet(isPresented: $showingAddItem) {
            NavigationStack {
                AddItemSearchView(projectID: projectID, room: liveRoom)
            }
            .presentationDetents([.large])
        }
        .tint(RenoTheme.ColorToken.accent)
    }

    private var roomSubtitle: String {
        if liveRoom.items.isEmpty { return "No products saved yet" }
        return "\(liveRoom.items.count) products · \(liveRoom.installedItems) installed"
    }
}

struct ItemCard: View {
    @EnvironmentObject private var store: RenoFlowStore
    let projectID: UUID
    let roomID: UUID
    let item: ItemEntity

    private var purchaseProgress: Double {
        item.quantityNeeded == 0 ? 0 : min(item.quantityPurchased, item.quantityNeeded) / item.quantityNeeded
    }

    var body: some View {
        RenoCard(padding: RenoTheme.Spacing.md) {
            HStack(alignment: .top, spacing: RenoTheme.Spacing.md) {
                ProductImage(urlString: item.imageURL, size: 86)

                VStack(alignment: .leading, spacing: RenoTheme.Spacing.sm) {
                    HStack(alignment: .top, spacing: RenoTheme.Spacing.sm) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.system(.headline, design: .rounded).weight(.semibold))
                                .foregroundStyle(RenoTheme.ColorToken.text)
                                .lineLimit(2)
                            Text("\(item.price, format: .currency(code: "USD")) each · \(item.quantityNeeded.clean) \(item.unit)")
                                .font(.caption)
                                .foregroundStyle(RenoTheme.ColorToken.secondaryText)
                        }
                        Spacer()
                        RenoStatusChip(status: item.status)
                    }

                    VStack(alignment: .leading, spacing: RenoTheme.Spacing.xs) {
                        HStack {
                            Text("\(item.quantityPurchased.clean) / \(item.quantityNeeded.clean) purchased")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RenoTheme.ColorToken.text)
                            Spacer()
                            PurchaseStepper(
                                canDecrement: item.quantityPurchased > 0,
                                canIncrement: item.quantityPurchased < item.quantityNeeded,
                                decrement: { store.updatePurchased(projectID: projectID, roomID: roomID, itemID: item.id, delta: -1) },
                                increment: { store.updatePurchased(projectID: projectID, roomID: roomID, itemID: item.id, delta: 1) }
                            )
                        }
                        RenoProgressBar(value: purchaseProgress, height: 7)
                    }
                }
            }
        }
    }
}

struct ProductImage: View {
    let urlString: String?
    let size: CGFloat

    var body: some View {
        KFImage(URL(string: urlString ?? ""))
            .placeholder {
                RenoTheme.ColorToken.secondarySurface
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(RenoTheme.ColorToken.tertiaryText)
                    }
            }
            .fade(duration: 0.2)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: RenoTheme.Radius.md, style: .continuous))
    }
}

struct PurchaseStepper: View {
    let canDecrement: Bool
    let canIncrement: Bool
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: decrement) {
                Image(systemName: "minus")
                    .frame(width: 28, height: 28)
            }
            .disabled(!canDecrement)
            Button(action: increment) {
                Image(systemName: "plus")
                    .frame(width: 28, height: 28)
            }
            .disabled(!canIncrement)
        }
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(RenoTheme.ColorToken.text)
        .background(RenoTheme.ColorToken.secondarySurface, in: Capsule())
        .opacity(canDecrement || canIncrement ? 1 : 0.45)
    }
}

struct StatusBadge: View {
    let status: ItemStatus

    var body: some View {
        RenoStatusChip(status: status)
    }
}
