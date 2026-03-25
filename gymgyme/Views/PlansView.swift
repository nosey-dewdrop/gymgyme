import SwiftUI
import SwiftData

struct PlansView: View {
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var store = StoreManager.shared
    @State private var showCreatePlan = false
    @State private var showSettings = false
    @State private var showPaywall = false
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

                    // pocket pt section
                    Text("").frame(height: 24)

                    if store.isPocketPTActive {
                        // active subscriber
                        HStack(spacing: 0) {
                            Text("★ ")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.yellow)
                            Text("pocket pt active")
                                .font(DoodleTheme.monoBold)
                                .foregroundStyle(DoodleTheme.yellow)
                        }
                        .padding(.bottom, 8)

                        // premium feature buttons hidden until implemented
                        // premiumFeatureButton("ai program builder", icon: "sparkles", color: DoodleTheme.purple) {}
                        // premiumFeatureButton("expert templates", icon: "star", color: DoodleTheme.orange) {}
                        // premiumFeatureButton("progressive overload", icon: "chart.line.uptrend.xyaxis", color: DoodleTheme.green) {}
                        Text("more features coming soon")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)
                            .padding(.top, 4)
                    } else {
                        // not subscribed — show upsell
                        Text("pocket pt")
                            .font(DoodleTheme.monoBold)
                            .foregroundStyle(DoodleTheme.yellow)
                            .padding(.bottom, 4)

                        Text("  let ai build your perfect program")
                            .font(DoodleTheme.monoSmall)
                            .foregroundStyle(DoodleTheme.dim)

                        Text("").frame(height: 8)

                        Button { showPaywall = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                Text("unlock pocket pt")
                            }
                            .font(DoodleTheme.monoBold)
                            .foregroundStyle(DoodleTheme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(DoodleTheme.yellow)
                            .cornerRadius(8)
                        }

                        Text("").frame(height: 12)

                        premiumPreviewCard("ai program builder", desc: "programs built from your exercises and goals", icon: "sparkles")
                        premiumPreviewCard("expert templates", desc: "science-backed programs by real trainers", icon: "star")
                        premiumPreviewCard("progressive overload", desc: "weekly suggestions to keep you growing", icon: "chart.line.uptrend.xyaxis")
                    }

                    if store.programCredits > 0 && !store.isPocketPTActive {
                        Text("").frame(height: 8)
                        HStack(spacing: 0) {
                            Text("● ")
                                .font(DoodleTheme.mono)
                                .foregroundStyle(DoodleTheme.purple)
                            Text("\(store.programCredits) program credit\(store.programCredits == 1 ? "" : "s") available")
                                .font(DoodleTheme.monoSmall)
                                .foregroundStyle(DoodleTheme.fg)
                        }
                    }

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
            .sheet(isPresented: $showPaywall) { PaywallView() }
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

    // MARK: - Active Premium Feature Button

    private func premiumFeatureButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 28)
                Text(title)
                    .font(DoodleTheme.monoBold)
                    .foregroundStyle(DoodleTheme.fg)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(DoodleTheme.dim)
            }
            .padding(12)
            .background(DoodleTheme.surface)
            .cornerRadius(8)
        }
    }

    // MARK: - Preview Card (Locked)

    private func premiumPreviewCard(_ title: String, desc: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DoodleTheme.yellow.opacity(0.5))
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
            Image(systemName: "lock")
                .font(.system(size: 12))
                .foregroundStyle(DoodleTheme.yellow.opacity(0.5))
        }
        .padding(12)
        .background(DoodleTheme.surface)
        .cornerRadius(8)
    }

    private func activatePlan(_ plan: WorkoutPlan) {
        if plan.isActive {
            plan.isActive = false
        } else {
            for p in plans where p.isActive { p.isActive = false }
            plan.isActive = true
        }
        WidgetSync.sync(context: modelContext)
    }
}

#Preview {
    PlansView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self], inMemory: true)
}
