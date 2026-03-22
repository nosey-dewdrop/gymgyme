import SwiftUI
import WidgetKit

struct WidgetView: View {
    let entry: WidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall: smallView
        case .systemMedium: mediumView
        default: smallView
        }
    }

    // MARK: - Small Widget

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("gymgyme")
                .font(WidgetColors.monoBold)
                .foregroundStyle(WidgetColors.green)

            Spacer()

            // streak
            streakBar
            streakCount

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

    private var mediumView: some View {
        HStack(alignment: .top, spacing: 12) {
            // left: streak
            VStack(alignment: .leading, spacing: 4) {
                Text("gymgyme")
                    .font(WidgetColors.monoBold)
                    .foregroundStyle(WidgetColors.green)

                Spacer()

                streakBar
                streakCount
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

    private var streakDays: [Bool] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()
        let workoutDates = Set((entry.streak?.workoutDays ?? []).compactMap { formatter.date(from: $0) }.map { calendar.startOfDay(for: $0) })

        return (0..<21).reversed().map { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return false }
            return workoutDates.contains(date)
        }
    }

    private var currentStreak: Int {
        var s = 0
        for d in streakDays.reversed() {
            if d { s += 1 } else { break }
        }
        return s
    }

    private var streakBar: some View {
        HStack(spacing: 1) {
            ForEach(0..<21, id: \.self) { i in
                Text(streakDays[i] ? "█" : "░")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(streakDays[i] ? WidgetColors.green : WidgetColors.dim.opacity(0.4))
            }
        }
    }

    private var streakCount: some View {
        HStack(spacing: 2) {
            Text("\(currentStreak)")
                .font(WidgetColors.monoBold)
                .foregroundStyle(WidgetColors.green)
            Text("streak")
                .font(WidgetColors.monoSmall)
                .foregroundStyle(WidgetColors.dim)
        }
    }
}
