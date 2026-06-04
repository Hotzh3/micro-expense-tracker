import Foundation

struct ExpenseCategory: Identifiable, Equatable, Hashable {
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
    static let coffee = ExpenseCategory(displayName: "Coffee", symbolName: "cup.and.saucer.fill", keywords: ["coffee", "cafe", "latte", "espresso"])
    static let food = ExpenseCategory(displayName: "Food", symbolName: "fork.knife", keywords: ["food", "meal", "lunch", "dinner"])
    static let transport = ExpenseCategory(displayName: "Transport", symbolName: "car.fill", keywords: ["uber", "taxi", "metro", "bus"])
    static let snacks = ExpenseCategory(displayName: "Snacks", symbolName: "birthday.cake.fill", keywords: ["snack", "chips", "cookie"])
    static let goingOut = ExpenseCategory(displayName: "Going Out", symbolName: "music.mic", keywords: ["bar", "club", "cinema"])
    static let delivery = ExpenseCategory(displayName: "Delivery", symbolName: "bag.fill", keywords: ["delivery", "rappi", "ubereats"])
    static let smallPurchases = ExpenseCategory(displayName: "Small Purchases", symbolName: "cart.fill", keywords: ["purchase", "store", "shop"])
    static let tips = ExpenseCategory(displayName: "Tips", symbolName: "hand.thumbsup.fill", keywords: ["tip", "tips", "gratuity"])
    static let other = ExpenseCategory(displayName: "Other", symbolName: "questionmark.circle.fill", keywords: ["other"])

    static let allDefaults: [ExpenseCategory] = [
        .coffee,
        .food,
        .transport,
        .snacks,
        .goingOut,
        .delivery,
        .smallPurchases,
        .tips,
        .other
    ]
}
