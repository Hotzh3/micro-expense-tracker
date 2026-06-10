import Foundation

enum SpendingGoalCadence: String, CaseIterable, Identifiable, Codable {
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly:
            return "Weekly limit"
        case .monthly:
            return "Monthly limit"
        }
    }
}

struct SpendingGoal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var cadence: SpendingGoalCadence
    var limit: Double
    var createdAt: Date = .now
    var updatedAt: Date = .now

    var isValid: Bool {
        limit.isFinite && limit > 0
    }
}

struct SpendingGoals: Codable, Equatable {
    var weekly: SpendingGoal?
    var monthly: SpendingGoal?

    static let empty = SpendingGoals(weekly: nil, monthly: nil)

    var isEmpty: Bool {
        weekly == nil && monthly == nil
    }
}

extension SpendingGoals {
    var sanitized: SpendingGoals {
        SpendingGoals(
            weekly: weekly?.isValid == true ? weekly : nil,
            monthly: monthly?.isValid == true ? monthly : nil
        )
    }

    func goal(for cadence: SpendingGoalCadence) -> SpendingGoal? {
        switch cadence {
        case .weekly:
            return weekly
        case .monthly:
            return monthly
        }
    }

    var activeGoals: [SpendingGoal] {
        [weekly, monthly].compactMap { $0 }
    }
}
