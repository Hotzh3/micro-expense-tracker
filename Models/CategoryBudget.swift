import Foundation
import SwiftUI

enum CategoryBudgetStatus: String, CaseIterable, Identifiable, Codable {
    case safe
    case watch
    case over

    var id: String { rawValue }

    var tintColor: Color {
        switch self {
        case .safe:
            return Color(red: 0.19, green: 0.64, blue: 0.38)
        case .watch:
            return Color(red: 0.92, green: 0.69, blue: 0.15)
        case .over:
            return Color(red: 0.86, green: 0.25, blue: 0.24)
        }
    }
}

struct CategoryBudget: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var category: ExpenseCategory
    var cadence: SpendingGoalCadence
    var limit: Double
    var createdAt: Date = .now
    var updatedAt: Date = .now
    var isActive: Bool = true

    var isValid: Bool {
        limit.isFinite
            && limit > 0
            && createdAt.timeIntervalSinceReferenceDate.isFinite
            && updatedAt.timeIntervalSinceReferenceDate.isFinite
            && !category.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var storageKey: String {
        "\(category.id.uuidString)-\(cadence.rawValue)"
    }
}
