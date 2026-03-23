import SwiftUI
import Charts
import SwiftData

struct ProgressChartView: View {
    let exercise: Exercise

    @Environment(\.dismiss) private var dismiss

    private struct DayPoint: Identifiable {
        let id = UUID()
        let date: Date
        let maxWeight: Double
        let totalVolume: Double // sum of (reps × weight) for the day
        let totalSets: Int
        let hasPR: Bool
    }

    private var dataPoints: [DayPoint] {
        let calendar = Calendar.current
        var grouped: [Date: [ExerciseSet]] = [:]
        for set in exercise.sets {
            let day = calendar.startOfDay(for: set.timestamp)
            grouped[day, default: []].append(set)
        }
        return grouped.keys.sorted().map { day in
            let sets = grouped[day] ?? []
            let maxW = sets.map(\.weight).max() ?? 0
            let vol = sets.reduce(0.0) { $0 + Double($1.reps) * $1.weight }
            let hasPR = sets.contains { $0.isPersonalRecord }
            return DayPoint(date: day, maxWeight: maxW, totalVolume: vol, totalSets: sets.count, hasPR: hasPR)
        }
    }

    private var personalBest: Double {
        exercise.sets.map(\.weight).max() ?? 0
    }

    private var totalSessions: Int {
        dataPoints.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // header
                    HStack(spacing: 0) {
                        Text("● ")
                            .font(DoodleTheme.mono)
                            .foregroundStyle(DoodleTheme.teal)
                        Text(exercise.name)
                            .font(DoodleTheme.monoTitle)
                            .foregroundStyle(DoodleTheme.fg)
                        Text(" ")
                        TagChip(tag: exercise.tag)
                    }

                    // stats row
                    HStack(spacing: 16) {
                        statBox("pb", value: String(format: "%.0f", personalBest), unit: "kg", color: DoodleTheme.yellow)
                        statBox("sessions", value: "\(totalSessions)", unit: "", color: DoodleTheme.blue)
                        if let last = dataPoints.last {
                            statBox("last", value: String(format: "%.0f", last.maxWeight), unit: "kg", color: DoodleTheme.green)
                        }
                    }

                    if dataPoints.count < 2 {
                        VStack(spacing: 4) {
                            Text("").frame(height: 20)
                            termLine(bullet: "~", color: DoodleTheme.dim, text: "need at least 2 sessions")
                            termLine(bullet: " ", color: DoodleTheme.dim, text: "to draw progress charts")
                        }
                    } else {
                        // weight chart
                        chartSection(title: "weight progression (kg)", color: DoodleTheme.green) {
                            weightChart
                        }

                        // volume chart
                        chartSection(title: "volume per session", color: DoodleTheme.blue) {
                            volumeChart
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("back")
                                .font(DoodleTheme.monoSmall)
                        }
                        .foregroundStyle(DoodleTheme.teal)
                    }
                }
            }
        }
    }

    // MARK: - Weight Chart

    private var weightChart: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.maxWeight)
                )
                .foregroundStyle(DoodleTheme.green)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.maxWeight)
                )
                .foregroundStyle(point.hasPR ? DoodleTheme.yellow : DoodleTheme.green)
                .symbolSize(point.hasPR ? 60 : 30)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine().foregroundStyle(DoodleTheme.dim.opacity(0.3))
                AxisValueLabel()
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine().foregroundStyle(DoodleTheme.dim.opacity(0.3))
                AxisValueLabel()
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
            }
        }
        .frame(height: 180)
    }

    // MARK: - Volume Chart

    private var volumeChart: some View {
        Chart {
            ForEach(dataPoints) { point in
                BarMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.totalVolume)
                )
                .foregroundStyle(DoodleTheme.blue.opacity(0.7))
                .cornerRadius(2)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine().foregroundStyle(DoodleTheme.dim.opacity(0.3))
                AxisValueLabel()
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine().foregroundStyle(DoodleTheme.dim.opacity(0.3))
                AxisValueLabel()
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
            }
        }
        .frame(height: 140)
    }

    // MARK: - Helpers

    private func chartSection<C: View>(title: String, color: Color, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                Text("─ ")
                    .font(DoodleTheme.mono)
                    .foregroundStyle(DoodleTheme.dim)
                Text(title)
                    .font(DoodleTheme.monoBold)
                    .foregroundStyle(color)
            }
            content()
                .padding(.leading, 4)
        }
    }

    private func statBox(_ label: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(DoodleTheme.monoSmall)
                .foregroundStyle(DoodleTheme.dim)
            HStack(spacing: 2) {
                Text(value)
                    .font(DoodleTheme.monoBold)
                    .foregroundStyle(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(DoodleTheme.monoSmall)
                        .foregroundStyle(DoodleTheme.dim)
                }
            }
        }
    }

    private func termLine(bullet: String, color: Color, text: String) -> some View {
        HStack(spacing: 0) {
            Text("\(bullet) ")
                .font(DoodleTheme.mono)
                .foregroundStyle(color)
            Text(text)
                .font(DoodleTheme.mono)
                .foregroundStyle(DoodleTheme.fg)
        }
    }
}
