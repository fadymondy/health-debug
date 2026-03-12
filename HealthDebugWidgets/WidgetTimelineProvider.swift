import WidgetKit
import Foundation

/// Timeline entry carrying the latest health snapshot for any widget.
struct HealthWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let cardID: String   // which card this widget instance shows

    static func placeholder(cardID: String) -> HealthWidgetEntry {
        HealthWidgetEntry(date: .now, snapshot: WidgetSnapshot(), cardID: cardID)
    }
}

/// Base timeline provider shared by all health widgets.
/// Refreshes every 15 minutes; reads data from the shared App Group UserDefaults.
struct HealthTimelineProvider: TimelineProvider {
    let cardID: String

    func placeholder(in context: Context) -> HealthWidgetEntry {
        .placeholder(cardID: cardID)
    }

    func getSnapshot(in context: Context, completion: @escaping (HealthWidgetEntry) -> Void) {
        let snapshot = WidgetDataStore.shared.read()
        completion(HealthWidgetEntry(date: .now, snapshot: snapshot, cardID: cardID))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthWidgetEntry>) -> Void) {
        let snapshot = WidgetDataStore.shared.read()
        let entry = HealthWidgetEntry(date: .now, snapshot: snapshot, cardID: cardID)
        // Refresh every 15 minutes
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }
}
