import SwiftUI
import SwiftData
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let bgColor = UIColor(DoodleTheme.bg)
        for window in windowScene.windows {
            window.backgroundColor = bgColor
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let bgColor = UIColor(DoodleTheme.bg)
        for window in windowScene.windows {
            window.backgroundColor = bgColor
            window.rootViewController?.view.backgroundColor = bgColor
        }
    }
}

@main
struct gymgymeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    let sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for:
                Exercise.self,
                WorkoutSession.self,
                ExerciseSet.self,
                WorkoutPlan.self,
                UserProfile.self,
                Meal.self
            )
        } catch {
            fatalError("failed to create model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(DoodleTheme.bg.ignoresSafeArea(.all))
                .onAppear {
                    for scene in UIApplication.shared.connectedScenes {
                        guard let ws = scene as? UIWindowScene else { continue }
                        let bgColor = UIColor(DoodleTheme.bg)
                        for window in ws.windows {
                            window.backgroundColor = bgColor
                            window.rootViewController?.view.backgroundColor = bgColor
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                WidgetSync.sync(context: sharedModelContainer.mainContext)
            }
        }
    }
}
