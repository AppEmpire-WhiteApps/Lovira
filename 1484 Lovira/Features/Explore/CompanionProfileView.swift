import SwiftData
import SwiftUI

struct CompanionProfileView: View {
    let companionId: String

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    @Query private var facts: [MemoryFact]
    @Query private var conversations: [Conversation]

    @State private var carouselPage = 0
    @State private var viewer: ExplorePhotoViewerItem?
    @State private var videoItem: ExploreVideoItem?
    @State private var isDeleteConfirmationPresented = false

    init(companionId: String) {
        self.companionId = companionId
        _facts = Query(
            filter: #Predicate<MemoryFact> { $0.companionId == companionId },
            sort: \MemoryFact.createdAt
        )
        _conversations = Query(filter: #Predicate<Conversation> { $0.companionId == companionId })
    }

    var body: some View {
        Group {
            if let companion = model.companion(id: companionId) {
                content(for: companion)
            } else {
                missingState
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: Layout

    private func content(for companion: Companion) -> some View {
        let carousel = carouselPhotos(for: companion)
        return ScrollView {
            VStack(spacing: 0) {
                photoCarousel(carousel, companion: companion)
                VStack(alignment: .leading, spacing: 24) {
                    headline(companion)
                    actions(companion)
                    if !companion.bio.isEmpty {
                        about(companion)
                    }
                    traits(companion)
                    interests(companion)
                    gallery(companion)
                    memory(companion)
                }
                .padding(.horizontal, 20)
                .padding(.top, -36)
                .padding(.bottom, 40)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .top) {
            topBar(companion)
        }
        .onAppear {
            model.prepareGalleryAccess(companionId: companion.id, preferred: companion.gallery.first)
        }
        .fullScreenCover(item: $viewer) { item in
            ExplorePhotoViewer(companionId: companion.id, photos: item.photos, startIndex: item.index)
        }
        .fullScreenCover(item: $videoItem) { item in
            ExploreVideoPlayerView(url: item.url)
        }
        .confirmationDialog(
            "Delete this character?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                model.deleteCustomCharacter(id: companion.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Her photos, chat and memories will be removed.")
        }
    }

    private var missingState: some View {
        VStack {
            HStack {
                CircleIconButton(systemName: "chevron.left") {
                    dismiss()
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            Spacer()
            EmptyStateView(
                icon: "person.crop.circle.badge.questionmark",
                title: "Character not found",
                message: "She may have been deleted."
            )
            Spacer()
        }
    }

    private func topBar(_ companion: Companion) -> some View {
        HStack {
            CircleIconButton(systemName: "chevron.left", background: .black.opacity(0.35)) {
                dismiss()
            }
            .accessibilityLabel(Text("Back"))
            Spacer()
            if companion.isCustom {
                Menu {
                    Button {
                        model.requestEdit(companion.id)
                    } label: {
                        Label(
                            LocalizedText("Edit character", ru: "Редактировать персонажа").value,
                            systemImage: "square.and.pencil"
                        )
                    }
                    Button(role: .destructive) {
                        isDeleteConfirmationPresented = true
                    } label: {
                        Label("Delete character", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.black.opacity(0.35), in: Circle())
                }
                .accessibilityLabel(Text("More"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    // MARK: Carousel

    private func carouselPhotos(for companion: Companion) -> [PhotoSource] {
        if companion.gallery.isEmpty {
            return [companion.cover]
        }
        return companion.gallery
    }

    private func photoCarousel(_ photos: [PhotoSource], companion: Companion) -> some View {
        let height: CGFloat = sizeClass == .regular ? 640 : 520
        return ZStack(alignment: .bottom) {
            TabView(selection: $carouselPage) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    PhotoView(source: photo, maxPixelSize: 1600)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            openViewer(photos: photos, index: index, companion: companion)
                        }
                        .premiumLocked(model.isGalleryPhotoLocked(photo, companionId: companion.id)) {
                            model.showPaywall(.main)
                        }
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            Theme.photoFade
                .frame(height: 220)
                .allowsHitTesting(false)

            if photos.count > 1 {
                HStack(spacing: 5) {
                    ForEach(0..<photos.count, id: \.self) { index in
                        Capsule()
                            .fill(index == carouselPage ? Color.white : Color.white.opacity(0.35))
                            .frame(width: index == carouselPage ? 18 : 6, height: 6)
                    }
                }
                .animation(.spring(response: 0.3), value: carouselPage)
                .padding(.bottom, 56)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    // MARK: Sections

    private func headline(_ companion: Companion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(verbatim: companion.name)
                    .font(.poppins(32, .bold))
                    .foregroundStyle(.white)
                Text(verbatim: "\(companion.age)")
                    .font(.poppins(26, .medium))
                    .foregroundStyle(.white.opacity(0.75))
                Spacer(minLength: 0)
            }

            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    OnlineDot(size: 9)
                    Text("Online")
                        .foregroundStyle(Theme.online)
                }
                if !companion.city.isEmpty {
                    Label {
                        Text(verbatim: companion.city)
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
            }
            .font(.appCallout)

            HStack(spacing: 8) {
                Label {
                    Text(verbatim: companion.relationship.title)
                } icon: {
                    Image(systemName: companion.relationship.icon)
                }
                .font(.appCaptionBold)
                .foregroundStyle(Theme.pink)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.pinkBackground, in: Capsule())

                if !companion.occupation.isEmpty && companion.occupation != companion.relationship.title {
                    Text(verbatim: companion.occupation)
                        .font(.appCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
            }

            intimacy
                .padding(.top, 4)
        }
    }

    private var intimacyLevel: Int {
        let count = conversations.first?.userMessageCount ?? 0
        return min(5, count / 15 + 1)
    }

    private var intimacy: some View {
        HStack(spacing: 10) {
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { level in
                    Image(systemName: level <= intimacyLevel ? "heart.fill" : "heart")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(level <= intimacyLevel ? AnyShapeStyle(Theme.ctaGradient) : AnyShapeStyle(Theme.textTertiary))
                }
            }
            Text(LocalizedText("Closeness level \(intimacyLevel)", ru: "Близость: уровень \(intimacyLevel)").value)
                .font(.appCaption)
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func actions(_ companion: Companion) -> some View {
        let chatTitle = LocalizedText("Chat with \(companion.name)", ru: "Написать \(companion.name)").value
        return VStack(spacing: 12) {
            PrimaryButton(
                title: LocalizedStringKey(chatTitle),
                icon: "bubble.left.fill"
            ) {
                guard model.authorizeCharacter(companion.id) else {
                    return
                }
                model.openChat(companion.id)
            }

            HStack(spacing: 12) {
                NavigationLink(value: AppRoute.scenarios(companion.id)) {
                    secondaryLabel(
                        title: "Scenarios",
                        icon: "theatermasks.fill",
                        isLocked: !model.access.isPremium
                    )
                }
                .buttonStyle(PressableButtonStyle())

                if let resource = companion.videoResource {
                    Button {
                        playVideo(resource, companion: companion)
                    } label: {
                        secondaryLabel(title: "Video", icon: "play.fill")
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private func secondaryLabel(title: LocalizedStringKey, icon: String, isLocked: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
            if isLocked {
                Image(systemName: "lock.fill")
                    .accessibilityLabel(Text(LocalizedText("Premium", ru: "По подписке").value))
            }
        }
        .font(.poppins(15, .medium))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(Theme.surfaceHigh, in: Capsule())
    }

    private func about(_ companion: Companion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "About me")
            Text(verbatim: companion.bio)
                .font(.appBody)
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func traits(_ companion: Companion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Personality")
            ExploreFlowLayout(spacing: 8) {
                ForEach(companion.traits) { trait in
                    ChipView(title: trait.title, icon: trait.icon, isSelected: true)
                }
            }
        }
    }

    @ViewBuilder
    private func interests(_ companion: Companion) -> some View {
        if !companion.interests.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Interests")
                ExploreFlowLayout(spacing: 8) {
                    ForEach(companion.interests) { interest in
                        ChipView(title: "\(interest.emoji) \(interest.title)")
                    }
                }
            }
        }
    }

    // MARK: Gallery

    private func gallery(_ companion: Companion) -> some View {
        let columns = [GridItem(.adaptive(minimum: 100, maximum: 220), spacing: 6)]
        let photos = companion.gallery
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Gallery")
                Text(verbatim: "\(photos.count)")
                    .font(.appCallout)
                    .foregroundStyle(Theme.textSecondary)
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    Button {
                        openViewer(photos: photos, index: index, companion: companion)
                    } label: {
                        PhotoView(source: photo, maxPixelSize: 500)
                            .aspectRatio(3 / 4, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .premiumLocked(model.isGalleryPhotoLocked(photo, companionId: companion.id)) {
                        model.showPaywall(.main)
                    }
                    .accessibilityIdentifier("profile.photo.\(index)")
                }
            }
        }
    }

    // MARK: Memory

    private func memory(_ companion: Companion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "What she knows about you")
            if facts.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.violet)
                    Text("Chat more and she will remember the important things about you.")
                        .font(.appSubheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardBackground(cornerRadius: 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(facts) { fact in
                        factRow(fact)
                        if fact.id != facts.last?.id {
                            Divider()
                                .overlay(Theme.stroke)
                                .padding(.leading, 44)
                        }
                    }
                }
                .cardBackground(cornerRadius: 16)
            }
        }
    }

    private func factRow(_ fact: MemoryFact) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 18))
                .foregroundStyle(Theme.pink)
            Text(verbatim: fact.text)
                .font(.appSubheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                delete(fact)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Forget"))
        }
        .padding(14)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                delete(fact)
            } label: {
                Label("Forget this", systemImage: "trash")
            }
        }
    }

    // MARK: Actions

    private func delete(_ fact: MemoryFact) {
        withAnimation {
            model.context.delete(fact)
            try? model.context.save()
        }
    }

    private func openViewer(photos: [PhotoSource], index: Int, companion: Companion) {
        guard photos.indices.contains(index) else {
            return
        }
        let photo = photos[index]
        guard !model.isGalleryPhotoLocked(photo, companionId: companion.id) else {
            model.showPaywall(.main)
            return
        }
        model.collect(photo, companionId: companion.id)
        try? model.context.save()
        viewer = ExplorePhotoViewerItem(photos: photos, index: index)
    }

    private func playVideo(_ resource: String, companion: Companion) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp4") else {
            return
        }
        model.collectVideo(resource, companionId: companion.id)
        try? model.context.save()
        videoItem = ExploreVideoItem(url: url)
    }
}

/// Wrapping layout for chips.
struct ExploreFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews: subviews, maxWidth: proposal.width ?? .infinity)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let proposedWidth = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if proposedWidth > maxWidth && !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}
