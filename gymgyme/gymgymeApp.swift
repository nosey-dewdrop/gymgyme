import SwiftUI
import SwiftData

@main
struct gymgymeApp: App {
    @Environment(\.scenePhase) private var scenePhase

    let sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for:
                Exercise.self,
                WorkoutSession.self,
                ExerciseSet.self,
                WorkoutPlan.self,
                UserProfile.self,
                Meal.self,
                DayProgram.self
            )
        } catch {
            // if schema migration fails, try deleting and recreating
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let appSupport = urls.first {
                try? FileManager.default.removeItem(at: appSupport.appendingPathComponent("default.store"))
            }
            do {
                return try ModelContainer(for:
                    Exercise.self, WorkoutSession.self, ExerciseSet.self,
                    WorkoutPlan.self, UserProfile.self, Meal.self, DayProgram.self
                )
            } catch {
                fatalError("failed to create model container after reset: \(error)")
            }
        }
    }()

    @AppStorage("dataMigrated") private var dataMigrated = false

    private func migrateExistingData() {
        guard !dataMigrated else { return }
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Exercise>()
        guard let exercises = try? context.fetch(descriptor) else { return }
        for exercise in exercises {
            exercise.name = exercise.name.lowercased()
            exercise.tag = TagSuggester.suggest(for: exercise.tag)
        }
        dataMigrated = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(DoodleTheme.bg.ignoresSafeArea(.all))
                .onAppear {
                    migrateExistingData()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // sync widget in background to avoid blocking UI
                DispatchQueue.global(qos: .utility).async {
                    DispatchQueue.main.async {
                        WidgetSync.sync(context: sharedModelContainer.mainContext)
                    }
                }
            }
        }
    }
}
