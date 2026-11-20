import Foundation

/// What the app tells the widgets. The app writes it to the shared app group; widgets only read it.
struct WidgetSnapshot: Codable {
    struct Item: Codable, Identifiable {
        var name: String
        var spent: Double
        var limit: Double
        var id: String { name }
        var fraction: Double { limit > 0 ? spent / limit : 0 }
    }

    var theme: String
    var mascot: String
    var income: Double
    var currency: String?
    var items: [Item]

    static let groupID = "group.com.mpbunce.Stacks"
    private static let key = "widgetSnapshot"

    static func load() -> WidgetSnapshot? {
        guard let data = UserDefaults(suiteName: groupID)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults(suiteName: Self.groupID)?.set(data, forKey: Self.key)
    }

    // MARK: Derived numbers (same rules as the Home screen)

    var spent: Double { items.reduce(0) { $0 + $1.spent } }
    var totalLimit: Double { items.reduce(0) { $0 + $1.limit } }
    var base: Double { income > 0 ? income : totalLimit }
    var remaining: Double { base - spent }
    var fraction: Double { base > 0 ? spent / base : 0 }
    var isOver: Bool { base > 0 && spent > base }
    var coins: Int { fraction >= 1 ? 0 : max(1, Int(ceil((1 - fraction) * 7))) }

    var mood: MascotMood { isOver ? .crumbled : (fraction > 0.8 ? .worried : .happy) }

    var statusText: String {
        switch mood {
        case .crumbled: "CRUMBLED"
        case .worried: "WOBBLY"
        case .happy: "SAFE"
        }
    }

    var daysLeft: Int {
        let cal = Calendar.current
        let total = cal.range(of: .day, in: .month, for: .now)?.count ?? 30
        return max(total - cal.component(.day, from: .now) + 1, 1)
    }

    var perDay: Double { max(remaining, 0) / Double(daysLeft) }

    static let sample = WidgetSnapshot(
        theme: "neon", mascot: "coin", income: 3000, currency: "USD",
        items: [
            .init(name: "Expenses", spent: 900, limit: 1200),
            .init(name: "Fun Money", spent: 200, limit: 750),
            .init(name: "Savings", spent: 0, limit: 450),
        ]
    )
}
