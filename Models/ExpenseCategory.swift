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
    static let coffee = ExpenseCategory(displayName: "Coffee", symbolName: "cup.and.saucer.fill", keywords: ["coffee", "cafe", "café", "latte", "espresso", "brew", "starbucks"])
    static let food = ExpenseCategory(displayName: "Food", symbolName: "fork.knife", keywords: ["food", "meal", "lunch", "dinner", "breakfast", "restaurant", "comida"])
    static let transport = ExpenseCategory(displayName: "Transport", symbolName: "car.fill", keywords: ["uber", "didi", "taxi", "ride", "metro", "bus", "cab"])
    static let convenience = ExpenseCategory(displayName: "Convenience", symbolName: "bag.fill", keywords: ["convenience", "oxxo", "7-eleven", "store", "mini super", "minisuper"])
    static let snacks = ExpenseCategory(displayName: "Snacks", symbolName: "birthday.cake.fill", keywords: ["snack", "chips", "cookie", "biscuit", "snacks"])
    static let entertainment = ExpenseCategory(displayName: "Entertainment", symbolName: "play.tv.fill", keywords: ["movie", "cinema", "concert", "game", "bar", "club", "entertainment"])
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
}
