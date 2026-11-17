import SwiftUI

struct MainTabView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            ForEach(AppTab.allCases) { tab in
                let isSelected = model.selectedTab == tab
                NavigationStack(path: model.path(for: tab)) {
                    root(for: tab)
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            if isSelected {
                                LoviraTabBar()
                            }
                        }
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                        }
                }
                .opacity(isSelected ? 1 : 0)
                .allowsHitTesting(isSelected)
                .accessibilityHidden(!isSelected)
            }
        }
    }

    @ViewBuilder
    private func root(for tab: AppTab) -> some View {
        switch tab {
        case .explore:
            ExploreView()
        case .chats:
            ChatsListView()
        case .gallery:
            GalleryView()
        case .profile:
            ProfileView()
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .companion(let id):
            CompanionProfileView(companionId: id)
        case .chat(let id):
            ChatView(companionId: id)
        case .scenarios(let id):
            ScenariosView(companionId: id)
        }
    }
}

struct LoviraTabBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 0) {
            item(.explore, icon: "sparkles", title: "Explore")
            item(.chats, icon: "bubble.left.and.bubble.right.fill", title: "Chats")
            createButton
            item(.gallery, icon: "photo.stack.fill", title: "Gallery")
            item(.profile, icon: "person.crop.circle.fill", title: "Profile")
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .background {
            Theme.backgroundSecondary
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Theme.stroke)
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func item(_ tab: AppTab, icon: String, title: LocalizedStringKey) -> some View {
        let isSelected = model.selectedTab == tab
        return Button {
            if model.selectedTab == tab {
                model.path(for: tab).wrappedValue.removeAll()
            } else {
                Haptics.tap()
                model.selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(height: 24)
                Text(title)
                    .font(.poppins(10, .medium))
            }
            .foregroundStyle(isSelected ? AnyShapeStyle(Theme.ctaGradient) : AnyShapeStyle(Theme.textTertiary))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var createButton: some View {
        Button {
            Haptics.tap()
            model.requestCreate()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Theme.ctaGradient, in: Circle())
                .shadow(color: Theme.pink.opacity(0.45), radius: 10, y: 4)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Text("Create character"))
        .accessibilityIdentifier("nav.create")
    }
}
