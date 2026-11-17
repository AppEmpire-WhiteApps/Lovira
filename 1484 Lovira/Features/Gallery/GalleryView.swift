import SwiftData
import SwiftUI

struct GalleryView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \CollectedMedia.createdAt, order: .reverse) private var media: [CollectedMedia]

    @State private var selectedCompanionID: String?
    @State private var viewerSelection: GalleryViewerSelection?

    private let columns = [GridItem(.adaptive(minimum: 108, maximum: 220), spacing: 8)]

    var body: some View {
        let companions = resolvedCompanions
        let items = visibleItems(companions: companions)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header(count: items.count)

                if media.isEmpty || companions.isEmpty {
                    EmptyStateView(
                        icon: "photo.on.rectangle.angled",
                        title: "No photos yet",
                        message: "Photos and videos she sends you will appear here",
                        actionTitle: "Explore girls"
                    ) {
                        model.selectedTab = .explore
                    }
                    .padding(.top, 60)
                } else {
                    filterChips(companions: companions)
                    grid(items: items, companions: companions)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $viewerSelection) { selection in
            GalleryViewer(items: items, startID: selection.id)
        }
        .onAppear {
            prepareGalleryAccess()
        }
        .onChange(of: accessSnapshot) { _, _ in
            prepareGalleryAccess()
            if let selectedCompanionID, !companions.contains(where: { $0.id == selectedCompanionID }) {
                self.selectedCompanionID = nil
            }
        }
    }

    // MARK: Data

    /// Observe group membership and photo changes, not just the total item count.
    private var accessSnapshot: [GalleryAccessSnapshot] {
        media.map {
            GalleryAccessSnapshot(
                id: $0.id,
                companionID: $0.companionId,
                createdAt: $0.createdAt,
                isVideo: $0.isVideo,
                photo: $0.photoSource
            )
        }
    }

    private func prepareGalleryAccess() {
        let groups = Dictionary(grouping: media, by: \.companionId)
        for (companionID, collected) in groups {
            // A generated video's photoSource is its thumbnail, not a free photo.
            let firstPhoto = collected
                .filter { !$0.isVideo && $0.photoSource != nil }
                .sorted {
                    if $0.createdAt == $1.createdAt {
                        return $0.id.uuidString < $1.id.uuidString
                    }
                    return $0.createdAt < $1.createdAt
                }
                .first?.photoSource
            model.prepareGalleryAccess(companionId: companionID, preferred: firstPhoto)
        }
    }

    private func isLocked(_ item: CollectedMedia) -> Bool {
        guard !item.isVideo, let photo = item.photoSource else {
            return false
        }
        return model.isGalleryPhotoLocked(photo, companionId: item.companionId)
    }

    /// Companions that have collected media, in order of the most recent item.
    private var resolvedCompanions: [Companion] {
        var seen = Set<String>()
        var result: [Companion] = []
        for item in media where !seen.contains(item.companionId) {
            seen.insert(item.companionId)
            if let companion = model.companion(id: item.companionId) {
                result.append(companion)
            }
        }
        return result
    }

    private func visibleItems(companions: [Companion]) -> [CollectedMedia] {
        let known = Set(companions.map(\.id))
        return media.filter { item in
            guard known.contains(item.companionId) else {
                return false
            }
            guard let selectedCompanionID else {
                return true
            }
            return item.companionId == selectedCompanionID
        }
    }

    // MARK: Sections

    private func header(count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Gallery")
                .font(.appTitle)
                .foregroundStyle(.white)
            Spacer()
            if count > 0 {
                Text(verbatim: "\(count)")
                    .font(.poppins(14, .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Theme.surfaceHigh, in: Capsule())
            }
        }
    }

    private func filterChips(companions: [Companion]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                Button {
                    select(nil)
                } label: {
                    ChipView(
                        title: LocalizedText("All", ru: "Все").value,
                        icon: "square.grid.2x2.fill",
                        isSelected: selectedCompanionID == nil
                    )
                }
                .buttonStyle(PressableButtonStyle())

                ForEach(companions) { companion in
                    Button {
                        select(companion.id)
                    } label: {
                        GalleryCompanionChip(
                            companion: companion,
                            isSelected: selectedCompanionID == companion.id
                        )
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -16)
    }

    private func grid(items: [CollectedMedia], companions: [Companion]) -> some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items) { item in
                Button {
                    Haptics.tap()
                    if isLocked(item) {
                        model.showPaywall(.main)
                    } else {
                        viewerSelection = GalleryViewerSelection(id: item.id)
                    }
                } label: {
                    GalleryTile(
                        item: item,
                        companion: companions.first { $0.id == item.companionId }
                    )
                }
                .buttonStyle(PressableButtonStyle())
                .premiumLocked(isLocked(item)) {
                    model.showPaywall(.main)
                }
            }
        }
    }

    private func select(_ companionID: String?) {
        Haptics.tap()
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedCompanionID = companionID
        }
    }
}

private struct GalleryAccessSnapshot: Hashable {
    let id: UUID
    let companionID: String
    let createdAt: Date
    let isVideo: Bool
    let photo: PhotoSource?
}

struct GalleryViewerSelection: Identifiable {
    let id: UUID
}

private struct GalleryCompanionChip: View {
    let companion: Companion
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            AvatarView(source: companion.avatar, size: 26)
            Text(companion.name)
                .font(.appCallout)
                .lineLimit(1)
        }
        .foregroundStyle(isSelected ? .white : Theme.textSecondary)
        .padding(.leading, 5)
        .padding(.trailing, 14)
        .frame(height: 36)
        .background(isSelected ? Theme.pinkBackground : Theme.surfaceHigh, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(isSelected ? Theme.pink : .clear, lineWidth: 1.5)
        }
    }
}

private struct GalleryTile: View {
    @Environment(AppModel.self) private var model

    let item: CollectedMedia
    let companion: Companion?

    private var isVideo: Bool {
        item.isVideo
    }

    private var source: PhotoSource? {
        let thumbnail: PhotoSource?
        if item.videoResource != nil {
            thumbnail = companion?.cover
        } else {
            thumbnail = item.photoSource
        }
        if isVideo, let thumbnail,
           model.isGalleryPhotoLocked(thumbnail, companionId: item.companionId) {
            return nil
        }
        return thumbnail
    }

    var body: some View {
        Color.clear
            .aspectRatio(0.75, contentMode: .fit)
            .overlay {
                if let source {
                    PhotoView(source: source, maxPixelSize: 600)
                        .id(source)
                } else {
                    Theme.surfaceHigh
                }
            }
            .overlay {
                if isVideo {
                    ZStack {
                        Color.black.opacity(0.25)
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
            }
            .overlay(alignment: .bottomLeading) {
                if let companion {
                    Text(companion.name)
                        .font(.appCaptionBold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardFade)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
