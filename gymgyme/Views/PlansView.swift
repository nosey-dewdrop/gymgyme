import SwiftUI
import SwiftData

struct PlansView: View {
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    @Environment(\.modelContext) private var modelContext
    @State private var showCreatePlan = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if plans.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 44))
                            .foregroundStyle(DoodleTheme.inkDim)
                        Text("no plans yet")
                            .font(DoodleTheme.handwritten(18))
                            .foregroundStyle(DoodleTheme.inkLight)
                        Text("create a plan from your exercises")
                            .font(DoodleTheme.caption())
                            .foregroundStyle(DoodleTheme.inkDim)
                    }
                    .padding(.top, 80)
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                            PlanRow(plan: plan, colorIndex: index)
                        }
                    }
                    .padding()
                }
            }
            .background(DoodleTheme.background)
            .navigationTitle("Plans")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreatePlan = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(DoodleTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showCreatePlan) {
                CreatePlanView()
            }
        }
    }
}

struct PlanRow: View {
    let plan: WorkoutPlan
    let colorIndex: Int

    private var color: Color {
        DoodleTheme.titleColor(for: colorIndex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: 20)
                Text(plan.name)
                    .font(DoodleTheme.handwritten(17))
                    .foregroundStyle(DoodleTheme.ink)
            }

            HStack(spacing: 8) {
                Text(plan.goal.rawValue)
                Text("·")
                Text(plan.duration.rawValue)
                Text("·")
                Text("\(plan.exerciseNames.count) exercises")
            }
            .font(DoodleTheme.mono(12))
            .foregroundStyle(DoodleTheme.inkLight)
        }
        .glowCard(color: color)
    }
}

#Preview {
    PlansView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self], inMemory: true)
}
