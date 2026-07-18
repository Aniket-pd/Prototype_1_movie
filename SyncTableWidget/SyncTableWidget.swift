import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct SyncTableStatusEntry: TimelineEntry {
    let date: Date
    let hostStatus: String
    let partnerStatus: String
    let predictedDifference: Int
}

struct SyncTableStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> SyncTableStatusEntry {
        .init(
            date: .now,
            hostStatus: "Preparing",
            partnerStatus: "Confirmed",
            predictedDifference: 3
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SyncTableStatusEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SyncTableStatusEntry>) -> Void) {
        let entry = SyncTableStatusEntry(
            date: .now,
            hostStatus: "Preparing",
            partnerStatus: "Confirmed",
            predictedDifference: 3
        )
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct SyncTableStatusWidget: Widget {
    let kind = "SyncTableStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SyncTableStatusProvider()) { entry in
            SyncTableStatusWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.10, green: 0.07, blue: 0.07)
                }
        }
        .configurationDisplayName("Sync Table")
        .description("Follow both linked orders and their shared arrival window.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SyncTableStatusWidgetView: View {
    let entry: SyncTableStatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Sync Table", systemImage: "fork.knife.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.red)
                Spacer()
                Text("Δ \(entry.predictedDifference)m")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }

            statusRow(name: "Aniket", status: entry.hostStatus, tint: .red)
            statusRow(name: "Aisha", status: entry.partnerStatus, tint: .orange)

            Text("Expected within \(entry.predictedDifference) min of each other")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Sync Table. Aniket \(entry.hostStatus). Aisha \(entry.partnerStatus). Expected within \(entry.predictedDifference) minutes of each other."
        )
    }

    private func statusRow(name: String, status: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
            Text(name)
                .font(.caption.bold())
            Spacer()
            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct SyncTableActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let hostStatus: String
        let partnerStatus: String
        let arrivalWindow: String
        let predictedDifference: Int
        let hostProgress: Double
        let partnerProgress: Double
    }

    let tableID: String
    let hostName: String
    let partnerName: String
}

struct ReadyToEatIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "I’m Ready to Eat"
    static let description = IntentDescription("Marks your side of the Sync Table ready for the first bite.")

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct SyncTableLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SyncTableActivityAttributes.self) { context in
            VStack(spacing: 10) {
                HStack {
                    Label("Sync Table", systemImage: "fork.knife.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Spacer()
                    Text(context.attributes.tableID)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                personProgress(name: context.attributes.hostName, status: context.state.hostStatus, value: context.state.hostProgress, tint: .red)
                personProgress(name: context.attributes.partnerName, status: context.state.partnerStatus, value: context.state.partnerProgress, tint: .orange)
                HStack {
                    Text(context.state.arrivalWindow).font(.caption.bold())
                    Spacer()
                    Button(intent: ReadyToEatIntent()) {
                        Image(systemName: "fork.knife")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .accessibilityLabel("I’m ready to eat")
                }
            }
            .padding()
            .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    compactPerson(name: context.attributes.hostName, value: context.state.hostProgress, color: .red)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    compactPerson(name: context.attributes.partnerName, value: context.state.partnerProgress, color: .orange)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Δ \(context.state.predictedDifference) min")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.arrivalWindow)
                        .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "fork.knife").foregroundStyle(.red)
            } compactTrailing: {
                Text("Δ\(context.state.predictedDifference)m").font(.caption2.bold())
            } minimal: {
                Image(systemName: "link").foregroundStyle(.red)
            }
            .keylineTint(.red)
        }
    }

    private func personProgress(name: String, status: String, value: Double, tint: Color) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.caption.bold())
                Text(status).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            ProgressView(value: value).frame(width: 110).tint(tint)
        }
    }

    private func compactPerson(name: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading) {
            Text(name).font(.caption.bold())
            ProgressView(value: value).frame(width: 70).tint(color)
        }
    }
}

@main
struct SyncTableWidgetBundle: WidgetBundle {
    var body: some Widget {
        SyncTableStatusWidget()
        SyncTableLiveActivityWidget()
    }
}
