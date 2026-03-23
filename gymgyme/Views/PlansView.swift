import SwiftUI
import SwiftData

struct PlansView: View {
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    @Environment(\.modelContext) private var modelContext
    @State private var showCreatePlan = false

    var body: some View {
        NavigationStack {
            ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("programs")
                        .font(.custom("Menlo-Bold", size: 28))
                        .foregroundStyle(DoodleTheme.orange)
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
                        HStack(spacing: 0) {
                            Text("  ")
                            Text("tap + to create a program")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.dim)
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
                                    modelContext.delete(plan)
                                    WidgetSync.sync(context: modelContext)
                                } label: {
                                    Label("delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    // premium section - hidden below fold
                    Spacer().frame(height: UIScreen.main.bounds.height * 0.4)
                    termLine(bullet: "─", color: DoodleTheme.dim, text: "premium programs")
                    Text("").frame(height: 8)

                    VStack(alignment: .leading, spacing: 8) {
                        premiumCard("ai program builder", desc: "balanced programs generated for your goals", icon: "sparkles")
                        premiumCard("expert templates", desc: "programs designed by certified trainers", icon: "star")
                        premiumCard("periodization", desc: "auto-adjusting progressive overload plans", icon: "chart.line.uptrend.xyaxis")
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
                ToolbarItem(placement: .primaryAction) {
                    Button { showCreatePlan = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(DoodleTheme.green)
                    }
                }
            }
            .sheet(isPresented: $showCreatePlan) { CreatePlanView() }
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
