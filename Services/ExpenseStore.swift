import Foundation

final class ExpenseStore {
    func sampleExpenses() -> [Expense] {
        [
            Expense(amount: 52, category: .coffee, merchant: "Morning Brew", note: "Cold brew and pastry", date: .now.addingTimeInterval(-1_800), source: .demo, confidence: 1.0),
            Expense(amount: 84, category: .transport, merchant: "Ride share", note: "Trip to office", date: .now.addingTimeInterval(-8_700), source: .demo, confidence: 1.0),
            Expense(amount: 139, category: .food, merchant: "Lunch spot", note: "Quick lunch", date: .now.addingTimeInterval(-86_000), source: .demo, confidence: 1.0)
        ]
    }
}
