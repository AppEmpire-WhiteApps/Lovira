import SwiftData
import SwiftUI

enum ExploreFilter: String, CaseIterable, Identifiable {
    case all
    case new
    case popular
    case caring
    case playful
    case mysterious
    case romantic
    case confident

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: LocalizedText("All", ru: "Все").value
        case .new: LocalizedText("New", ru: "Новые").value
        case .popular: LocalizedText("Popular", ru: "Популярные").value
        case .caring: CompanionTrait.caring.title
        case .playful: CompanionTrait.playful.title
        case .mysterious: CompanionTrait.mysterious.title
        case .romantic: CompanionTrait.romantic.title
        case .confident: CompanionTrait.confident.title
        }
    }

    var icon: String? {
        switch self {
        case .all: nil
        case .new: "sparkles"
        case .popular: "flame.fill"
        case .caring: CompanionTrait.caring.icon
        case .playful: CompanionTrait.playful.icon
        case .mysterious: CompanionTrait.mysterious.icon
        case .romantic: CompanionTrait.romantic.icon
        case .confident: CompanionTrait.confident.icon
        }
    }

    func apply(to companions: [Companion]) -> [Companion] {
        switch self {
        case .all:
            return companions
        case .new:
            return companions.filter(\.isNew)
        case .popular:
            return companions.sorted { $0.popularity > $1.popularity }
        case .caring:
            return companions.filter { $0.traits.contains(.caring) }
        case .playful:
            return companions.filter { $0.traits.contains(.playful) }
        case .mysterious:
            return companions.filter { $0.traits.contains(.mysterious) }
        case .romantic:
            return companions.filter { $0.traits.contains(.romantic) }
        case .confident:
            return companions.filter { $0.traits.contains(.confident) }
        }
    }
}

struct ExploreView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \CustomCharacter.createdAt, order: .reverse) private var customCharacters: [CustomCharacter]

    @State private var filter: ExploreFilter = .all

    private var isRegular: Bool {
        sizeClass == .regular
    }

    private var gridColumns: [GridItem] {
        if isRegular {
            return [GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)]
        }
        return [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ]
    }

    private var featured: Companion? {
        let presets = model.presets
        if let newest = presets.filter(\.isNew).max(by: { $0.popularity < $1.popularity }) {
            return newest
        }
        return presets.max { $0.popularity < $1.popularity }
    }

    private var filteredCompanions: [Companion] {
        filter.apply(to: model.presets)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                if let featured {
                    ExploreHeroCard(companion: featured) {
                        guard model.authorizeCharacter(featured.id) else {
                            return
                        }
                        model.openChat(featured.id)
                    }
                    .frame(height: isRegular ? 300 : 230)
                    .premiumLocked(model.isCharacterLocked(featured.id)) {
                        model.showPaywall(.main)
                    }
                    .padding(.horizontal, 20)
                }
                if !customCharacters.isEmpty {
                    myCharacters
                }
                filterChips
                companionsGrid
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text(verbatim: "AI Companion")
                .font(.poppins(26, .bold))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: My characters

    private var myCharacters: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "My characters")
                .padding(.horizontal, 20)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    createTile
                    ForEach(customCharacters) { character in
                        let companion = character.companion
                        Button {
                            openProfile(companion.id)
                        } label: {
                            ExploreMiniCard(companion: companion)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .premiumLocked(model.isCharacterLocked(companion.id)) {
                            model.showPaywall(.main)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var createTile: some View {
        Button {
            Haptics.tap()
            model.requestCreate()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Theme.ctaGradient, in: Circle())
                Text("Create new")
                    .font(.appCaptionBold)
                    .foregroundStyle(.white)
            }
            .frame(width: 120, height: 160)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.pink.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: Filters + grid

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(ExploreFilter.allCases) { item in
                    Button {
                        Haptics.tap()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            filter = item
                        }
                    } label: {
                        ChipView(title: item.title, icon: item.icon, isSelected: filter == item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var companionsGrid: some View {
        let companions = filteredCompanions
        if companions.isEmpty {
            EmptyStateView(
                icon: "heart.slash",
                title: "Nobody here yet",
                message: "Try another filter or create your own character."
            )
        } else {
            LazyVGrid(columns: gridColumns, spacing: isRegular ? 16 : 12) {
                ForEach(companions) { companion in
                    Button {
                        openProfile(companion.id)
                    } label: {
                        ExploreCharacterCard(companion: companion)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .premiumLocked(model.isCharacterLocked(companion.id)) {
                        model.showPaywall(.main)
                    }
                    .accessibilityIdentifier("catalog.\(companion.id)")
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func openProfile(_ companionID: String) {
        guard model.authorizeCharacter(companionID) else {
            return
        }
        model.openProfile(companionID)
    }
}

// MARK: - Hero card

private struct ExploreHeroCard: View {
    let companion: Companion
    let action: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PhotoView(source: companion.cover, maxPixelSize: 1400)
            Theme.cardFade
            LinearGradient(
                colors: [Theme.pink.opacity(0.25), .clear],
                startPoint: .bottomLeading,
                endPoint: .center
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("New girl of the week")
                }
                .font(.appCaptionBold)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.ctaGradient, in: Capsule())

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(verbatim: companion.name)
                        .font(.poppins(28, .bold))
                    Text(verbatim: "\(companion.age)")
                        .font(.poppins(22, .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    OnlineDot(size: 10)
                }
                .foregroundStyle(.white)

                Text(verbatim: companion.occupation)
                    .font(.appSubheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)

                Button(action: action) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.fill")
                        Text("Chat now")
                    }
                    .font(.poppins(14, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 40)
                    .background(Theme.ctaGradient, in: Capsule())
                    .shadow(color: Theme.pink.opacity(0.45), radius: 10, y: 4)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, 4)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
