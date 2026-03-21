import SwiftUI
import SwiftData

struct PlansView: View {
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    @Environment(\.modelContext) private var modelContext
    @State private var showCreatePlan = false

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
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(plans[index])
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DoodleTheme.background)
            .navigationTitle("Plans")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreatePlan = true
                    } label: {
                        Image(systemName: "plus")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(plan.name)
                .font(DoodleTheme.handwritten(17))
                .foregroundStyle(DoodleTheme.ink)

            HStack(spacing: 8) {
                Text(plan.goal.rawValue)
                Text("·")
                Text(plan.duration.rawValue)
                Text("·")
                Text("\(plan.exerciseNames.count) exercises")
            }
            .font(DoodleTheme.caption())
            .foregroundStyle(DoodleTheme.inkLight)
        }
        .listRowBackground(DoodleTheme.cardBackground)
    }
}

#Preview {
    PlansView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self], inMemory: true)
}
