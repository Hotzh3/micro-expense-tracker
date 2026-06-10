import SwiftUI

enum GoalForecastStatus: String, CaseIterable, Identifiable, Codable {
    case safe
    case watch
    case risk
    case over

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .safe:
            return "checkmark.circle.fill"
        case .watch:
            return "exclamationmark.triangle.fill"
        case .risk:
            return "exclamationmark.circle.fill"
        case .over:
            return "xmark.octagon.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .safe:
            return Color(red: 0.19, green: 0.64, blue: 0.38)
        case .watch:
            return Color(red: 0.92, green: 0.69, blue: 0.15)
        case .risk:
            return Color(red: 0.90, green: 0.54, blue: 0.16)
        case .over:
            return Color(red: 0.86, green: 0.25, blue: 0.24)
        }
    }

    var priority: Int {
        switch self {
        case .over:
            return 3
        case .risk:
            return 2
        case .watch:
            return 1
        case .safe:
            return 0
        }
    }
}

struct GoalForecast: Identifiable, Equatable {
    let goalType: SpendingGoalCadence
    let limit: Double
    let spent: Double
    let remaining: Double
    let daysElapsed: Int
    let daysRemaining: Int
    let averageDailySpend: Double
    let remainingDailyBudget: Double
    let projectedSpend: Double
    let projectedOverLimitAmount: Double
    let status: GoalForecastStatus

    var id: SpendingGoalCadence { goalType }

    var projectedUnderLimitAmount: Double {
        max(limit - projectedSpend, 0)
    }

    var percentUsed: Double {
        guard limit > 0 else { return 0 }
        return min((spent / limit) * 100, 999)
    }
}
