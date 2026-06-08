import SwiftUI
import WidgetKit

struct PocketLeakWidgetEntry: TimelineEntry {
    let date: Date
    let todayTotal: String
    let monthTotal: String
    let topCategory: String
}

struct PocketLeakWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PocketLeakWidgetEntry {
        PocketLeakWidgetEntry(
            date: .now,
            todayTotal: "$12.40",
            monthTotal: "$184.10",
            topCategory: "Food"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PocketLeakWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PocketLeakWidgetEntry>) -> Void) {
        let entry = PocketLeakWidgetEntry(
            date: .now,
            todayTotal: "$12.40",
            monthTotal: "$184.10",
            topCategory: "Food"
        )

        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(60 * 30))))
    }
}

struct PocketLeakWidgetView: View {
    let entry: PocketLeakWidgetEntry

    var body: some View {
        ZStack {
            Color.black

            VStack(alignment: .leading, spacing: 10) {
                Text("Pocket Leak")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.72))

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.todayTotal)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Today")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.68))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("This month \(entry.monthTotal)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Top category: \(entry.topCategory)")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.68))
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
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
        .description("A minimal glance at today and this month's spending.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
