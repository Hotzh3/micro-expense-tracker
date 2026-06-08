import SwiftUI
import WidgetKit

struct PocketLeakWidgetEntry: TimelineEntry {
    let date: Date
    let todayTotal: Double
    let weekTotal: Double
    let monthTotal: Double
    let topCategory: String
    let goalStatus: String
    let categories: [(String, Double)]
}

struct PocketLeakWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PocketLeakWidgetEntry {
        demoEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (PocketLeakWidgetEntry) -> Void) {
        completion(demoEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PocketLeakWidgetEntry>) -> Void) {
        completion(Timeline(entries: [demoEntry()], policy: .after(.now.addingTimeInterval(60 * 30))))
    }

    private func demoEntry() -> PocketLeakWidgetEntry {
        PocketLeakWidgetEntry(
            date: .now,
            todayTotal: 12.4,
            weekTotal: 84.1,
            monthTotal: 184.1,
            topCategory: "Food",
            goalStatus: "On track",
            categories: [("Food", 84.1), ("Coffee", 42.2), ("Transport", 31.6)]
        )
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
        VStack(alignment: .leading, spacing: 10) {
            Text("Pocket Leak")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.72))

            VStack(alignment: .leading, spacing: 4) {
                Text(currency(entry.todayTotal))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.68))
            }

            Spacer(minLength: 0)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.goalStatus)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white)
                    Text("Top: \(entry.topCategory)")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.68))
                }
                Spacer()
            }
        }
        .padding(16)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            HStack(alignment: .top, spacing: 12) {
                metric(title: "Today", value: currency(entry.todayTotal))
                metric(title: "This Week", value: currency(entry.weekTotal))
                metric(title: "This Month", value: currency(entry.monthTotal))
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Top category")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.68))
                    Text(entry.topCategory)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Goal")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.68))
                    Text(entry.goalStatus)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(16)
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            HStack(alignment: .top, spacing: 12) {
                metric(title: "Today", value: currency(entry.todayTotal))
                metric(title: "This Week", value: currency(entry.weekTotal))
                metric(title: "This Month", value: currency(entry.monthTotal))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Category summary")
                    .font(.headline)
                    .foregroundStyle(.white)

                ForEach(entry.categories, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.0)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text(currency(item.1))
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
                                    .frame(width: max(10, geometry.size.width * progress(for: item.1)), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pocket Leak")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.72))
            Text("Local snapshot")
                .font(.headline)
                .foregroundStyle(.white)
        }
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

    private func progress(for amount: Double) -> Double {
        let maxValue = max(entry.categories.map(\.1).max() ?? 1, 1)
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
