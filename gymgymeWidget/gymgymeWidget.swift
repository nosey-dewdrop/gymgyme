import WidgetKit
import SwiftUI

struct WidgetEntry: TimelineEntry {
    let date: Date
    let streak: WidgetStreakData?
    let activeProgram: WidgetProgramData?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: .now, streak: nil, activeProgram: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let data = WidgetDataStore.load()
        completion(WidgetEntry(date: .now, streak: data?.streak, activeProgram: data?.activeProgram))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let data = WidgetDataStore.load()
        let entry = WidgetEntry(date: .now, streak: data?.streak, activeProgram: data?.activeProgram)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct gymgymeWidget: Widget {
    let kind: String = "gymgymeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
                .containerBackground(WidgetColors.bg, for: .widget)
        }
        .configurationDisplayName("gymgyme")
        .description("streak & today's program")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
