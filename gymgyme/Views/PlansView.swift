import SwiftUI
import SwiftData

struct PlansView: View {
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]

    var body: some View {
        NavigationStack {
            List {
                if plans.isEmpty {
                    ContentUnavailableView(
                        "No plans yet",
                        systemImage: "list.clipboard",
                        description: Text("Create a plan from your exercises")
                    )
                } else {
                    ForEach(plans) { plan in
                        PlanRow(plan: plan)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DoodleTheme.background)
            .navigationTitle("Plans")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct PlanRow: View {
    let plan: WorkoutPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(plan.name)
                .font(DoodleTheme.handwritten(17))
                .foregroundStyle(DoodleTheme.ink)

            HStack(spacing: 8) {
                Text(plan.goal.rawValue)
                Text("·")
                Text(plan.duration.rawValue)
            }
            .font(DoodleTheme.caption())
            .foregroundStyle(DoodleTheme.inkLight)
        }
        .listRowBackground(DoodleTheme.cardBackground)
    }
}

#Preview {
    PlansView()
        .modelContainer(for: WorkoutPlan.self, inMemory: true)
}
