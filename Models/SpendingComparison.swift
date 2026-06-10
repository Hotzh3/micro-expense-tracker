import SwiftUI

enum SpendingComparisonDirection: String, CaseIterable, Identifiable, Codable {
    case up
    case down
    case flat

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .up:
            return "arrow.up.right"
        case .down:
            return "arrow.down.right"
        case .flat:
            return "minus"
        }
    }

    var tintColor: Color {
        switch self {
        case .up:
            return Color(red: 0.90, green: 0.54, blue: 0.16)
        case .down:
            return Color(red: 0.19, green: 0.64, blue: 0.38)
        case .flat:
            return Color.gray
        }
    }
}

enum SpendingComparisonPeriod: String, CaseIterable, Identifiable, Codable {
    case todayVsYesterday
    case weekVsLastWeek
    case monthVsLastMonth
    case weeklyAverageVsLastWeek
    case topCategoryThisWeekVsLastWeek

    var id: String { rawValue }
}

struct SpendingComparison: Identifiable, Equatable {
    let id: UUID
    let title: String
    let currentAmount: Double
    let previousAmount: Double
    let deltaAmount: Double
    let percentChange: Double
    let direction: SpendingComparisonDirection
    let period: SpendingComparisonPeriod

    init(
        id: UUID = UUID(),
        title: String,
        currentAmount: Double,
        previousAmount: Double,
        deltaAmount: Double,
        percentChange: Double,
        direction: SpendingComparisonDirection,
        period: SpendingComparisonPeriod
    ) {
        self.id = id
        self.title = title
        self.currentAmount = currentAmount
        self.previousAmount = previousAmount
        self.deltaAmount = deltaAmount
        self.percentChange = percentChange
        self.direction = direction
        self.period = period
    }

    var hasPreviousData: Bool {
        previousAmount > 0
    }
}
