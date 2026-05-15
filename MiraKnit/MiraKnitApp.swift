import SwiftUI
import SwiftData

@main
struct MiraKnitApp: App {
    @State private var deepLinkManager = DeepLinkManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Material.self,
            MaterialTransaction.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(deepLinkManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(sharedModelContainer)

        Settings {
            SettingsView()
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "miraknit",
              url.host == "add",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let urlString = components.queryItems?.first(where: { $0.name == "url" })?.value,
              let videoURL = URL(string: urlString)
        else { return }

        deepLinkManager.pendingURL = videoURL
    }
}
