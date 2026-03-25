import SwiftUI
import WidgetKit

struct WidgetView: View {
    let entry: WidgetEntry
    @Environment(\.widgetFamily) var family

    // precompute streak data once per entry, not per render
    private static let isoFormatter = ISO8601DateFormatter()
    private static let calendar = Calendar.current

    private var streakData: (days: [Bool], streak: Int) {
        let calendar = Self.calendar
        let today = calendar.startOfDay(for: Date())
        let workoutDates = Set((entry.streak?.workoutDays ?? []).compactMap { Self.isoFormatter.date(from: $0) }.map { calendar.startOfDay(for: $0) })

        let days = (0..<21).reversed().map { offset -> Bool in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return false }
            return workoutDates.contains(date)
        }

        var s = 0
        for d in days.reversed() {
            if d { s += 1 } else { break }
        }
        return (days, s)
    }

    var body: some View {
        let computed = streakData
        switch family {
        case .systemSmall: smallView(days: computed.days, streak: computed.streak)
        case .systemMedium: mediumView(days: computed.days, streak: computed.streak)
        default: smallView(days: computed.days, streak: computed.streak)
        }
    }

    // MARK: - Small Widget

    private func smallView(days: [Bool], streak: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("gymgyme")
                .font(WidgetColors.monoBold)
                .foregroundStyle(WidgetColors.green)

            Spacer()

            // streak
            streakBar(days: days)
            streakCount(streak: streak)

            Spacer()

            // active program
            if let program = entry.activeProgram {
                Text(program.programName)
                    .font(WidgetColors.monoBold)
                    .foregroundStyle(WidgetColors.orange)
                    .lineLimit(1)
                Text("\(program.exerciseNames.count) exercises")
                    .font(WidgetColors.monoSmall)
                    .foregroundStyle(WidgetColors.dim)
            } else {
                Text("no active program")
                    .font(WidgetColors.monoSmall)
                    .foregroundStyle(WidgetColors.dim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Medium Widget

    private func mediumView(days: [Bool], streak: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // left: streak
            VStack(alignment: .leading, spacing: 4) {
                Text("gymgyme")
                    .font(WidgetColors.monoBold)
                    .foregroundStyle(WidgetColors.green)

                Spacer()

                streakBar(days: days)
                streakCount(streak: streak)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // right: program
            VStack(alignment: .leading, spacing: 2) {
                if let program = entry.activeProgram {
                    HStack(spacing: 0) {
                        Text("● ")
                            .font(WidgetColors.mono)
                            .foregroundStyle(WidgetColors.orange)
                        Text(program.programName)
                            .font(WidgetColors.monoBold)
                            .foregroundStyle(WidgetColors.fg)
                            .lineLimit(1)
                    }

                    ForEach(program.exerciseNames.prefix(5), id: \.self) { name in
                        Text("  \(name)")
                            .font(WidgetColors.monoSmall)
                            .foregroundStyle(WidgetColors.dim)
                            .lineLimit(1)
                    }
                    if program.exerciseNames.count > 5 {
                        Text("  +\(program.exerciseNames.count - 5) more")
                            .font(WidgetColors.monoSmall)
                            .foregroundStyle(WidgetColors.dim)
                    }
                } else {
                    Text("no active program")
                        .font(WidgetColors.monoSmall)
                        .foregroundStyle(WidgetColors.dim)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Streak Components

    private func streakBar(days: [Bool]) -> some View {
        HStack(spacing: 1) {
            ForEach(0..<21, id: \.self) { i in
                Text(days[i] ? "█" : "░")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(days[i] ? WidgetColors.green : WidgetColors.dim.opacity(0.4))
            }
        }
    }

    private func streakCount(streak: Int) -> some View {
        HStack(spacing: 2) {
            Text("\(streak)")
                .font(WidgetColors.monoBold)
                .foregroundStyle(WidgetColors.green)
            Text("streak")
                .font(WidgetColors.monoSmall)
                .foregroundStyle(WidgetColors.dim)
        }
    }
}
