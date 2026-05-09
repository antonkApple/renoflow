import Combine
import Foundation
import SwiftUI

@MainActor
final class RenoFlowStore: ObservableObject {
    @Published var projects: [ProjectEntity] = [] { didSet { persistProjects() } }
    @Published var stores: [Store] = [] { didSet { persistStores() } }
    @Published var selectedRegion: Region = .ca { didSet { persistRegion() } }

    private let projectsKey = "renoflow.projects.v1"
    private let storesKey = "renoflow.stores.v1"
    private let regionKey = "renoflow.region.v1"
    private let didSeedStoresKey = "renoflow.didSeedStores.v1"

    init() {
        load()
    }

    func addProject(named name: String) {
        let rooms = ["Kitchen", "Bathroom", "Living Room"].map { RoomEntity(name: $0) }
        projects.append(ProjectEntity(name: name, rooms: rooms))
    }

    func addRoom(to projectID: UUID, named name: String) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[projectIndex].rooms.append(RoomEntity(name: name))
    }

    func saveItem(_ item: ItemEntity, projectID: UUID, roomID: UUID) {
        guard let indexes = indexes(projectID: projectID, roomID: roomID) else { return }
        var normalized = item
        normalized.clampQuantities()
        if let itemIndex = projects[indexes.project].rooms[indexes.room].items.firstIndex(where: { $0.id == item.id }) {
            projects[indexes.project].rooms[indexes.room].items[itemIndex] = normalized
        } else {
            projects[indexes.project].rooms[indexes.room].items.append(normalized)
        }
    }

    func attachBuyingOption(_ option: BuyingOptionEntity, to itemID: UUID, projectID: UUID, roomID: UUID) {
        guard let indexes = indexes(projectID: projectID, roomID: roomID),
              let itemIndex = projects[indexes.project].rooms[indexes.room].items.firstIndex(where: { $0.id == itemID }) else { return }
        projects[indexes.project].rooms[indexes.room].items[itemIndex].buyingOptions.append(option)
    }

    func updatePurchased(projectID: UUID, roomID: UUID, itemID: UUID, delta: Double) {
        guard let indexes = indexes(projectID: projectID, roomID: roomID),
              let itemIndex = projects[indexes.project].rooms[indexes.room].items.firstIndex(where: { $0.id == itemID }) else { return }
        var item = projects[indexes.project].rooms[indexes.room].items[itemIndex]
        item.quantityPurchased = min(max(item.quantityPurchased + delta, 0), item.quantityNeeded)
        if item.quantityPurchased > 0, item.status == .planned { item.status = .ordered }
        projects[indexes.project].rooms[indexes.room].items[itemIndex] = item
    }

    func addStore(_ store: Store) {
        guard !stores.contains(where: { $0.id == store.id }) else { return }
        stores.append(store)
    }

    func updateStore(_ store: Store) {
        guard let index = stores.firstIndex(where: { $0.id == store.id }) else { return }
        stores[index] = store
    }

    func deleteStores(at offsets: IndexSet) {
        stores.remove(atOffsets: offsets)
    }

    func storeName(for url: URL) -> String {
        if let match = stores.first(where: { url.hostMatches($0.baseURL) }) {
            return match.name
        }
        let host = url.host?.replacingOccurrences(of: "www.", with: "") ?? "Unknown Store"
        let newStore = Store(id: host, name: host.capitalized, baseURL: "https://\(host)", searchURLTemplate: nil, isPreset: false)
        addStore(newStore)
        return newStore.name
    }

    private func indexes(projectID: UUID, roomID: UUID) -> (project: Int, room: Int)? {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
              let roomIndex = projects[projectIndex].rooms.firstIndex(where: { $0.id == roomID }) else { return nil }
        return (projectIndex, roomIndex)
    }

    private func load() {
        let defaults = UserDefaults.standard
        if let rawRegion = defaults.string(forKey: regionKey), let region = Region(rawValue: rawRegion) {
            selectedRegion = region
        }
        if let data = defaults.data(forKey: projectsKey), let decoded = try? JSONDecoder.renoFlow.decode([ProjectEntity].self, from: data) {
            projects = decoded
        }
        if defaults.bool(forKey: didSeedStoresKey),
           let data = defaults.data(forKey: storesKey),
           let decoded = try? JSONDecoder.renoFlow.decode([Store].self, from: data) {
            stores = decoded
        } else {
            stores = StorePresetProvider.stores(for: selectedRegion)
            defaults.set(true, forKey: didSeedStoresKey)
            persistStores()
        }
        if projects.isEmpty {
            projects = [ProjectEntity(name: "Home Renovation", rooms: [RoomEntity(name: "Kitchen"), RoomEntity(name: "Bathroom"), RoomEntity(name: "Living Room")])]
        }
    }

    private func persistProjects() {
        if let data = try? JSONEncoder.renoFlow.encode(projects) { UserDefaults.standard.set(data, forKey: projectsKey) }
    }

    private func persistStores() {
        if let data = try? JSONEncoder.renoFlow.encode(stores) { UserDefaults.standard.set(data, forKey: storesKey) }
    }

    private func persistRegion() {
        UserDefaults.standard.set(selectedRegion.rawValue, forKey: regionKey)
    }
}
