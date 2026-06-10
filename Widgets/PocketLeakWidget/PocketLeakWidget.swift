import SwiftUI
import WidgetKit

struct PocketLeakWidgetEntry: TimelineEntry {
    let date: Date
    let summary: WidgetSummary
    let displayState: WidgetDisplayState
}

enum WidgetDisplayState {
    case live
    case empty
    case demo

    var badgeTitle: String {
        switch self {
        case .live:
            return "Live"
        case .empty:
            return "Waiting for data"
        case .demo:
            return "Preview"
        }
    }

    var helperText: String {
        switch self {
        case .live:
            return "Updated in the app"
        case .empty:
            return "Open Pocket Leak to sync live data"
        case .demo:
            return "Enable App Group for live data"
        }
    }
}

struct PocketLeakWidgetProvider: TimelineProvider {
    private let summaryStore = WidgetSummaryStore()

    func placeholder(in context: Context) -> PocketLeakWidgetEntry {
        demoEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (PocketLeakWidgetEntry) -> Void) {
        completion(loadCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PocketLeakWidgetEntry>) -> Void) {
        let entry = loadCurrentEntry()
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(60 * 30))))
    }

    private func loadCurrentEntry() -> PocketLeakWidgetEntry {
        if !summaryStore.isAvailable {
            return demoEntry()
        }

        if let summary = summaryStore.loadSummary() {
            return PocketLeakWidgetEntry(date: .now, summary: summary, displayState: .live)
        }

        return PocketLeakWidgetEntry(date: .now, summary: .empty(), displayState: .empty)
    }

    private func demoEntry() -> PocketLeakWidgetEntry {
        PocketLeakWidgetEntry(date: .now, summary: .demo(), displayState: .demo)
    }
}

struct PocketLeakWidgetView: View {
    let entry: PocketLeakWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .containerBackground(for: .widget) {
                Color.black
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pocket Leak")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.72))

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.72))

                Text(compactCurrency(entry.summary.todayTotal))
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if let signalText = smallSignalText {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 6, height: 6)
                    Text(signalText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pocket Leak")
        .accessibilityValue("Today \(compactCurrency(entry.summary.todayTotal)). \(smallSignalText ?? entry.displayState.helperText)")
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pocket Leak")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.72))

            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currency(entry.summary.todayTotal))
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.72))
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Top category")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.72))
                    Text(entry.summary.topCategory)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pocket Leak")
        .accessibilityValue("Today \(currency(entry.summary.todayTotal)). Top category \(entry.summary.topCategory).")
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            HStack(alignment: .top, spacing: 12) {
                metric(title: "Today", value: currency(entry.summary.todayTotal))
                metric(title: "This Week", value: currency(entry.summary.weekTotal))
                metric(title: "This Month", value: currency(entry.summary.monthTotal))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Category summary")
                    .font(.headline)
                    .foregroundStyle(.white)

                if entry.summary.categoryTop3.isEmpty {
                    Text(entry.displayState.helperText)
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.68))
                } else {
                    ForEach(entry.summary.categoryTop3) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(item.amountText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule(style: .continuous)
                                        .fill(Color.white.opacity(0.08))
                                        .frame(height: 8)
                                    Capsule(style: .continuous)
                                        .fill(Color.white)
                                        .frame(width: max(10, geometry.size.width * progress(for: item.amount)), height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pocket Leak")
        .accessibilityValue(statusLine + " Category summary available.")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pocket Leak")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.72))
            Text(entry.displayState.badgeTitle)
                .font(.headline)
                .foregroundStyle(.white)
            Text(entry.displayState.helperText)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.68))
        }
    }

    private var statusLine: String {
        let weekly = entry.summary.weeklyGoalStatus.displayTitle
        let monthly = entry.summary.monthlyGoalStatus.displayTitle
        return "Weekly: \(weekly) • Monthly: \(monthly)"
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.68))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func currency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private var smallSignalText: String? {
        let category = entry.summary.topCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        if !category.isEmpty, category != "No spending yet" {
            return category
        }

        switch entry.displayState {
        case .live:
            return entry.summary.weeklyGoalStatus.displayTitle
        case .empty:
            return "No data yet"
        case .demo:
            return "Preview mode"
        }
    }

    private func compactCurrency(_ value: Double) -> String {
        let sign = value < 0 ? "-" : ""
        let absolute = abs(value)
        if absolute >= 1_000_000 {
            return "\(sign)$\(compactNumber(absolute / 1_000_000))M"
        }
        if absolute >= 1_000 {
            return "\(sign)$\(compactNumber(absolute / 1_000))K"
        }
        return "\(sign)$\(Int(absolute.rounded()))"
    }

    private func compactNumber(_ value: Double) -> String {
        if value >= 10 || value.rounded() == value {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private func progress(for amount: Double) -> Double {
        let maxValue = max(entry.summary.categoryTop3.map(\.amount).max() ?? 1, 1)
        return min(amount / maxValue, 1)
    }
}

@main
struct PocketLeakWidgetBundle: WidgetBundle {
    var body: some Widget {
        PocketLeakSummaryWidget()
    }
}

struct PocketLeakSummaryWidget: Widget {
    let kind: String = "PocketLeakSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PocketLeakWidgetProvider()) { entry in
            PocketLeakWidgetView(entry: entry)
        }
        .configurationDisplayName("Pocket Leak")
        .description("A minimal glance at today, this week, and this month.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
