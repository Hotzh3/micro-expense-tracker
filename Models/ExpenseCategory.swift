import Foundation

struct ExpenseCategory: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let displayName: String
    let symbolName: String
    let keywords: [String]

    init(
        id: UUID = UUID(),
        displayName: String,
        symbolName: String,
        keywords: [String] = []
    ) {
        self.id = id
        self.displayName = displayName
        self.symbolName = symbolName
        self.keywords = keywords
    }
}

extension ExpenseCategory {
    static let coffee = ExpenseCategory(displayName: "Coffee", symbolName: "cup.and.saucer.fill", keywords: ["coffee", "cafe", "café", "latte", "espresso", "brew", "starbucks", "morning brew"])
    static let food = ExpenseCategory(displayName: "Food", symbolName: "fork.knife", keywords: ["food", "meal", "lunch", "dinner", "breakfast", "restaurant", "restaurante", "comida", "taco", "pizza", "toks"])
    static let transport = ExpenseCategory(displayName: "Transport", symbolName: "car.fill", keywords: ["uber", "didi", "taxi", "ride", "metro", "bus", "cab"])
    static let convenience = ExpenseCategory(displayName: "Convenience", symbolName: "bag.fill", keywords: ["convenience", "oxxo", "7-eleven", "7 eleven", "store", "mini super", "minisuper", "corner store"])
    static let snacks = ExpenseCategory(displayName: "Snacks", symbolName: "birthday.cake.fill", keywords: ["snack", "snacks", "chips", "cookie", "biscuit", "candy"])
    static let entertainment = ExpenseCategory(displayName: "Entertainment", symbolName: "play.tv.fill", keywords: ["movie", "cinema", "cine", "concert", "game", "bar", "club", "entertainment", "spotify", "netflix"])
    static let shopping = ExpenseCategory(displayName: "Shopping", symbolName: "cart.fill", keywords: ["shopping", "purchase", "shop", "amazon", "mall", "clothing"])
    static let other = ExpenseCategory(displayName: "Other", symbolName: "questionmark.circle.fill", keywords: ["other"])

    static let allDefaults: [ExpenseCategory] = [
        .coffee,
        .food,
        .transport,
        .convenience,
        .snacks,
        .entertainment,
        .shopping,
        .other
    ]

    var slug: String {
        displayName
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: " ", with: "-")
    }

    static func category(matching rawValue: String, in categories: [ExpenseCategory] = allDefaults) -> ExpenseCategory? {
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: " ", with: "-")

        return categories.first { category in
            let candidates = [category.slug, category.displayName.lowercased()]
                + category.keywords.map { $0.lowercased().replacingOccurrences(of: " ", with: "-") }
            return candidates.contains(normalized)
                || category.keywords.contains { keyword in
                    keyword.lowercased() == rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                }
        }
    }
}
