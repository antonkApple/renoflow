import SwiftUI

struct ProjectEntity: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var rooms: [RoomEntity]
    var createdAt = Date()

    var items: [ItemEntity] { rooms.flatMap(\.items) }
    var totalItems: Int { items.count }
    var installedItems: Int { items.filter { $0.status == .installed }.count }
    var progress: Double { totalItems == 0 ? 0 : Double(installedItems) / Double(totalItems) }
    var totalBudget: Double { items.reduce(0) { $0 + $1.totalPrice } }
    var totalSpent: Double { items.reduce(0) { $0 + $1.spentPrice } }
    var toBuyItems: [(room: RoomEntity, item: ItemEntity)] {
        rooms.flatMap { room in room.items.filter(\.isMissing).map { (room, $0) } }
    }
}

struct RoomEntity: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var items: [ItemEntity] = []
    var createdAt = Date()

    var defaultSearchQueries: [String] { RoomSearchSuggestions.queries(for: name) }
    var totalItems: Int { items.count }
    var installedItems: Int { items.filter { $0.status == .installed }.count }
    var progress: Double { totalItems == 0 ? 0 : Double(installedItems) / Double(totalItems) }
}

struct ItemEntity: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var price: Double
    var quantityNeeded: Double
    var quantityPurchased: Double
    var unit: String
    var url: String?
    var imageURL: String?
    var localImagePath: String?
    var notes: String
    var status: ItemStatus
    var createdAt = Date()
    var buyingOptions: [BuyingOptionEntity] = []

    var totalPrice: Double { price * quantityNeeded }
    var spentPrice: Double { price * min(quantityPurchased, quantityNeeded) }
    var quantityRemaining: Double { max(quantityNeeded - quantityPurchased, 0) }
    var isFullyPurchased: Bool { quantityPurchased >= quantityNeeded }
    var isMissing: Bool { quantityPurchased < quantityNeeded }
    var preferredStoreName: String? { buyingOptions.sorted { $0.price < $1.price }.first?.storeName }

    mutating func clampQuantities() {
        quantityNeeded = max(quantityNeeded, 0)
        quantityPurchased = min(max(quantityPurchased, 0), quantityNeeded)
    }
}

struct BuyingOptionEntity: Identifiable, Codable, Hashable {
    var id = UUID()
    var storeName: String
    var productURL: String
    var price: Double
    var currency: String?
    var createdAt = Date()
}

enum ItemStatus: String, Codable, CaseIterable, Identifiable {
    case planned
    case ordered
    case delivered
    case installed

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var color: Color {
        switch self {
        case .planned: .secondary
        case .ordered: .blue
        case .delivered: .orange
        case .installed: .green
        }
    }
}

struct Store: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var baseURL: String
    var searchURLTemplate: String?
    var isPreset: Bool

    func searchURL(for query: String) -> URL? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return URL(string: baseURL) }
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        if let searchURLTemplate {
            return URL(string: searchURLTemplate.replacingOccurrences(of: "{query}", with: encoded))
        }
        return URL(string: "https://www.google.com/search?q=\(encoded)")
    }
}

enum Region: String, CaseIterable, Identifiable, Codable {
    case ca = "CA"
    case us = "US"
    case gb = "GB"
    case de = "DE"
    case fr = "FR"
    case au = "AU"
    case nl = "NL"
    case pl = "PL"

    var id: String { rawValue }
}

struct ParsedItemDraft: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var imageURL: String?
    var price: Double?
    var productURL: String
    var storeName: String

    var buyingOption: BuyingOptionEntity {
        BuyingOptionEntity(storeName: storeName, productURL: productURL, price: price ?? 0, currency: nil)
    }
}

enum ShoppingFilter: String, CaseIterable, Identifiable {
    case allNeeded
    case missing
    case partial
    case fullyPurchased

    var id: String { rawValue }
    var label: String {
        switch self {
        case .allNeeded: "To Buy"
        case .missing: "Missing"
        case .partial: "Partial"
        case .fullyPurchased: "Bought"
        }
    }
}

enum ConfirmationMode: String, CaseIterable {
    case newItem
    case buyingOption
}
