import SwiftUI
import SwiftData

struct PlansView: View {
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    @Environment(\.modelContext) private var modelContext
    @State private var showCreatePlan = false
    @State private var showSettings = false
    @State private var planToDelete: WorkoutPlan?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("programs")
                            .font(.custom("Menlo-Bold", size: 28))
                            .foregroundStyle(DoodleTheme.purple)
                        Spacer()
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(DoodleTheme.dim)
                        }
                        Button { showCreatePlan = true } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(DoodleTheme.purple)
                                .padding(.leading, 12)
                        }
                    }
                    .padding(.bottom, 8)

                    if plans.isEmpty {
                        HStack(spacing: 0) {
                            Text("~ ")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.dim)
                            Text("no programs yet")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.dim)
                        }
                        Text("  create a program from your exercises")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                        Text("  and plan your workout routine")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                        Text("").frame(height: 8)
                        Button { showCreatePlan = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("create your first program")
                            }
                            .font(DoodleTheme.monoBold)
                            .foregroundStyle(DoodleTheme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(DoodleTheme.purple)
                            .cornerRadius(8)
                        }
                    } else {
                        ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 0) {
                                    Text("● ")
                                        .font(DoodleTheme.mono)
                                        .foregroundStyle(plan.isActive ? DoodleTheme.green : DoodleTheme.color(for: index))
                                    Text(plan.name)
                                        .font(DoodleTheme.monoBold)
                                        .foregroundStyle(DoodleTheme.fg)
                                    if plan.isActive {
                                        Text(" [active]")
                                            .font(DoodleTheme.monoSmall)
                                            .foregroundStyle(DoodleTheme.green)
                                    }
                                }
                                HStack(spacing: 0) {
                                    Text("  ")
                                    Text("\(plan.goal.rawValue) · \(plan.duration.rawValue) · \(plan.exerciseNames.count) exercises")
                                        .font(DoodleTheme.monoSmall)
                                        .foregroundStyle(DoodleTheme.dim)
                                }
                                Text("").frame(height: 6)
                            }
                            .contextMenu {
                                Button {
                                    activatePlan(plan)
                                } label: {
                                    Label(plan.isActive ? "deactivate" : "activate", systemImage: plan.isActive ? "star.slash" : "star")
                                }
                                Button(role: .destructive) {
                                    planToDelete = plan
                                } label: {
                                    Label("delete", systemImage: "trash")
                                }
                            }
                        }
                    }

                    // premium section
                    Text("").frame(height: 24)
                    Text("premium programs")
                        .font(DoodleTheme.monoBold)
                        .foregroundStyle(DoodleTheme.purple)
                        .padding(.bottom, 8)

                    premiumCard("ai program builder", desc: "balanced programs generated for your goals", icon: "sparkles")
                    premiumCard("expert templates", desc: "programs designed by certified trainers", icon: "star")
                    premiumCard("periodization", desc: "auto-adjusting progressive overload plans", icon: "chart.line.uptrend.xyaxis")

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .background(DoodleTheme.bg.ignoresSafeArea(.all))
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreatePlan) { CreatePlanView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .alert("delete program?", isPresented: Binding(
                get: { planToDelete != nil },
                set: { if !$0 { planToDelete = nil } }
            )) {
                Button("cancel", role: .cancel) { planToDelete = nil }
                Button("delete", role: .destructive) {
                    if let p = planToDelete {
                        modelContext.delete(p)
                        WidgetSync.sync(context: modelContext)
                    }
                    planToDelete = nil
                }
            } message: {
                Text("this program will be permanently deleted")
            }
        }
    }

    private func premiumCard(_ title: String, desc: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DoodleTheme.purple)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DoodleTheme.monoBold)
                    .foregroundStyle(DoodleTheme.fg)
                Text(desc)
                    .font(DoodleTheme.monoSmall)
                    .foregroundStyle(DoodleTheme.dim)
            }
            Spacer()
            Text("soon")
                .font(DoodleTheme.monoSmall)
                .foregroundStyle(DoodleTheme.purple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DoodleTheme.purple.opacity(0.15))
                .cornerRadius(6)
        }
        .padding(12)
        .background(DoodleTheme.surface)
        .cornerRadius(8)
    }

    private func activatePlan(_ plan: WorkoutPlan) {
        if plan.isActive {
            plan.isActive = false
        } else {
            for p in plans { p.isActive = false }
            plan.isActive = true
        }
        WidgetSync.sync(context: modelContext)
    }
}

#Preview {
    PlansView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self], inMemory: true)
}
