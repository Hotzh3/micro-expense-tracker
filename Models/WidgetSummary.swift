import Foundation

enum WidgetGoalStatus: String, Codable, CaseIterable, Identifiable {
    case none
    case onTrack
    case closeToLimit
    case limitReached

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .none:
            return "No goal"
        case .onTrack:
            return "On track"
        case .closeToLimit:
            return "Close to limit"
        case .limitReached:
            return "Limit reached"
        }
    }
}

struct WidgetCategorySummary: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let amount: Double

    init(name: String, amount: Double) {
        self.id = name.lowercased()
        self.name = name
        self.amount = amount
    }

    var amountText: String {
        String(format: "$%.2f", amount)
    }
}

struct WidgetSummary: Codable, Equatable {
    let date: Date
    let todayTotal: Double
    let weekTotal: Double
    let monthTotal: Double
    let topCategory: String
    let weeklyGoalStatus: WidgetGoalStatus
    let monthlyGoalStatus: WidgetGoalStatus
    let categoryTop3: [WidgetCategorySummary]

    static func demo() -> WidgetSummary {
        WidgetSummary(
            date: .now,
            todayTotal: 12.40,
            weekTotal: 84.10,
            monthTotal: 184.10,
            topCategory: "Food",
            weeklyGoalStatus: .onTrack,
            monthlyGoalStatus: .closeToLimit,
            categoryTop3: [
                WidgetCategorySummary(name: "Food", amount: 84.10),
                WidgetCategorySummary(name: "Coffee", amount: 42.20),
                WidgetCategorySummary(name: "Transport", amount: 31.60)
            ]
        )
    }

    static func empty() -> WidgetSummary {
        WidgetSummary(
            date: .now,
            todayTotal: 0,
            weekTotal: 0,
            monthTotal: 0,
            topCategory: "No shared data yet",
            weeklyGoalStatus: .none,
            monthlyGoalStatus: .none,
            categoryTop3: []
        )
    }
}
