import PremiumKit
import SwiftData
import SwiftUI

@main
struct LoviraApp: App {
    @UIApplicationDelegateAdaptor(PremiumAppDelegate.self) private var appDelegate
    @ObservedObject private var premium = Premium.shared
    @State private var model: AppModel

    init() {
        PremiumSetup.configureIfReady()
        FontRegistrar.registerFonts()
        Appearance.configure()
        _model = State(initialValue: AppModel(container: Self.makeContainer()))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .modelContainer(model.container)
                .preferredColorScheme(.dark)
                .tint(Theme.pink)
                .allowsHitTesting(!premium.isShowingSplash)
                .accessibilityHidden(premium.isShowingSplash)
                .overlay {
                    if premium.isShowingSplash {
                        SplashScreen()
                    }
                }
        }
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([
            Conversation.self,
            ChatMessage.self,
            MemoryFact.self,
            CollectedMedia.self,
            CustomCharacter.self,
        ])
        let storeURL = MediaStore.rootDirectory.appendingPathComponent("Lovira.store")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        if let container = try? ModelContainer(for: schema, configurations: configuration) {
            return container
        }
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: memory)
        } catch {
            fatalError("Unable to create the data store: \(error)")
        }
    }
}
