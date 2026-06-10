import SwiftUI

enum SmartInsightType: String, CaseIterable, Identifiable, Codable {
    case spendingIncrease
    case spendingDecrease
    case topCategory
    case dailyAverage
    case goalRisk
    case positiveTrend
    case neutral

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .spendingIncrease:
            return "arrow.up.right"
        case .spendingDecrease:
            return "arrow.down.right"
        case .topCategory:
            return "chart.pie.fill"
        case .dailyAverage:
            return "calendar"
        case .goalRisk:
            return "exclamationmark.triangle.fill"
        case .positiveTrend:
            return "checkmark.seal.fill"
        case .neutral:
            return "sparkles"
        }
    }

    var accentColor: Color {
        switch self {
        case .spendingIncrease:
            return .red
        case .spendingDecrease:
            return .green
        case .topCategory:
            return .blue
        case .dailyAverage:
            return .orange
        case .goalRisk:
            return .red
        case .positiveTrend:
            return .green
        case .neutral:
            return .gray
        }
    }
}

struct SmartInsight: Identifiable, Equatable {
    let id: UUID
    let title: String
    let message: String
    let type: SmartInsightType
    let priority: Int
    let category: ExpenseCategory?
    let amount: Double?
    let percentChange: Double?

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        type: SmartInsightType,
        priority: Int,
        category: ExpenseCategory? = nil,
        amount: Double? = nil,
        percentChange: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.priority = priority
        self.category = category
        self.amount = amount
        self.percentChange = percentChange
    }
}
