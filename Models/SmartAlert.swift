import SwiftUI

enum SmartAlertSeverity: String, CaseIterable, Identifiable, Codable {
    case info
    case warning
    case critical
    case success

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.octagon.fill"
        case .success:
            return "checkmark.seal.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .info:
            return Color(red: 0.18, green: 0.47, blue: 0.88)
        case .warning:
            return Color(red: 0.92, green: 0.69, blue: 0.15)
        case .critical:
            return Color(red: 0.86, green: 0.25, blue: 0.24)
        case .success:
            return Color(red: 0.19, green: 0.64, blue: 0.38)
        }
    }

    var priority: Int {
        switch self {
        case .critical:
            return 3
        case .warning:
            return 2
        case .success:
            return 1
        case .info:
            return 0
        }
    }
}

enum SmartAlertType: String, CaseIterable, Identifiable, Codable {
    case goalRisk
    case overspendToday
    case categorySpike
    case noData
    case positiveTrend

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .goalRisk:
            return "target"
        case .overspendToday:
            return "calendar.badge.exclamationmark"
        case .categorySpike:
            return "chart.line.uptrend.xyaxis"
        case .noData:
            return "sparkles"
        case .positiveTrend:
            return "checkmark.circle.fill"
        }
    }
}

struct SmartAlert: Identifiable, Equatable {
    let id: String
    let title: String
    let message: String
    let severity: SmartAlertSeverity
    let type: SmartAlertType
    let createdAt: Date
    var isDismissed: Bool

    init(
        id: String,
        title: String,
        message: String,
        severity: SmartAlertSeverity,
        type: SmartAlertType,
        createdAt: Date = .now,
        isDismissed: Bool = false
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.type = type
        self.createdAt = createdAt
        self.isDismissed = isDismissed
    }
}
