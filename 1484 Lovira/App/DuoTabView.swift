import SwiftData
import SwiftUI
import UIKit

@available(iOS 18.0, *)
struct DuoTabView<Content: View>: UIViewControllerRepresentable {
    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var modelContext

    let selectedTab: AppTab
    let content: (AppTab) -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeUIViewController(context: Context) -> UITabBarController {
        let controller = UITabBarController()
        controller.delegate = context.coordinator
        controller.view.backgroundColor = UIColor(Theme.background)
        controller.tabBar.tintColor = UIColor(Theme.pink)

        let create = UITab(
            title: String(localized: "Create character"),
            image: UIImage(systemName: "plus.circle.fill")?
                .withTintColor(UIColor(Theme.pink), renderingMode: .alwaysOriginal),
            identifier: Coordinator.createIdentifier
        ) { _ in
            UIViewController()
        }
        create.accessibilityIdentifier = "nav.create"

        controller.tabs = [
            screenTab(.explore, title: String(localized: "Explore"), image: "sparkles"),
            screenTab(.chats, title: String(localized: "Chats"), image: "bubble.left.and.bubble.right.fill"),
            create,
            screenTab(.gallery, title: String(localized: "Gallery"), image: "photo.stack.fill"),
            screenTab(.profile, title: String(localized: "Profile"), image: "person.crop.circle.fill"),
        ]
        controller.selectedTab = controller.tabs.first { $0.identifier == selectedTab.rawValue }

        #if compiler(>=6.4)
            if #available(iOS 27.0, *) {
                controller.prominentTabIdentifier = Coordinator.createIdentifier
            }
        #endif

        return controller
    }

    func updateUIViewController(_ controller: UITabBarController, context: Context) {
        context.coordinator.model = model
        guard controller.selectedTab?.identifier != selectedTab.rawValue else { return }
        controller.selectedTab = controller.tabs.first { $0.identifier == selectedTab.rawValue }
    }

    private func screenTab(_ tab: AppTab, title: String, image: String) -> UITab {
        UITab(title: title, image: UIImage(systemName: image), identifier: tab.rawValue) { _ in
            let root = content(tab)
                .environment(model)
                .environment(\.modelContext, modelContext)
                .preferredColorScheme(.dark)
                .tint(Theme.pink)
            return UIHostingController(rootView: root)
        }
    }

    final class Coordinator: NSObject, UITabBarControllerDelegate {
        static var createIdentifier: String { "create" }

        var model: AppModel

        init(model: AppModel) {
            self.model = model
        }

        func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
            if tab.identifier == Self.createIdentifier {
                Haptics.tap()
                model.requestCreate()
                return false
            }

            guard let appTab = AppTab(rawValue: tab.identifier) else { return false }
            if tabBarController.selectedTab === tab {
                model.path(for: appTab).wrappedValue.removeAll()
                return false
            }

            Haptics.tap()
            return true
        }

        func tabBarController(_ tabBarController: UITabBarController, didSelectTab selectedTab: UITab, previousTab: UITab?) {
            guard let appTab = AppTab(rawValue: selectedTab.identifier) else { return }
            model.selectedTab = appTab
        }
    }
}
