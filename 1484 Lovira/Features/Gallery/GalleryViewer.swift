import AVKit
import Photos
import SwiftData
import SwiftUI
import UIKit

/// Full-screen paged viewer for collected photos and videos.
struct GalleryViewer: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var items: [CollectedMedia]
    @State private var currentID: UUID?
    @State private var shareItems: GalleryShareItems?
    @State private var isSaving = false
    @State private var isConfirmingDelete = false
    @State private var isViewerActive = false

    init(items: [CollectedMedia], startID: UUID) {
        _items = State(initialValue: items)
        _currentID = State(initialValue: startID)
    }

    private var accessibleItems: [CollectedMedia] {
        items.filter { canAccess($0) }
    }

    private var currentItem: CollectedMedia? {
        accessibleItems.first { $0.id == currentID }
    }

    private func canAccess(_ item: CollectedMedia) -> Bool {
        if item.isVideo {
            return true
        }
        guard let photo = item.photoSource else {
            return false
        }
        return !model.isGalleryPhotoLocked(photo, companionId: item.companionId)
    }

    private func canShare(_ share: GalleryShareItems) -> Bool {
        guard let mediaID = share.mediaID else {
            return false
        }
        return items.contains { $0.id == mediaID && canAccess($0) }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentID) {
                ForEach(accessibleItems) { item in
                    GalleryViewerPage(item: item, isCurrent: item.id == currentID)
                        .tag(Optional(item.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                bottomBar
            }
        }
        .overlay(alignment: .top) {
            // The root toast overlay is hidden behind this full-screen cover.
            if let toast = model.toast {
                ToastView(text: toast.text, icon: toast.icon)
                    .padding(.top, 64)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .statusBarHidden()
        .sheet(item: $shareItems) { share in
            if canShare(share) {
                GalleryActivityView(items: share.items)
                    .presentationDetents([.medium, .large])
            }
        }
        .onAppear {
            isViewerActive = true
            reconcileAccess()
        }
        .onDisappear {
            isViewerActive = false
            shareItems = nil
        }
        .onChange(of: accessibleItems.map(\.id)) { _, _ in
            reconcileAccess()
        }
        .onChange(of: model.access.isPremium) { _, _ in
            reconcileAccess()
        }
        .confirmationDialog(
            "Delete from gallery?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteCurrent()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: Bars

    private var topBar: some View {
        HStack(spacing: 12) {
            if let item = currentItem, let companion = model.companion(id: item.companionId) {
                AvatarView(source: companion.avatar, size: 36)
                VStack(alignment: .leading, spacing: 0) {
                    Text(companion.name)
                        .font(.poppins(15, .semibold))
                        .foregroundStyle(.white)
                    Text(item.createdAt, format: .dateTime.day().month().hour().minute())
                        .font(.appCaption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            if let index = accessibleItems.firstIndex(where: { $0.id == currentID }), accessibleItems.count > 1 {
                Text(verbatim: "\(index + 1) / \(accessibleItems.count)")
                    .font(.appCaptionBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            CircleIconButton(systemName: "xmark", size: 38, background: Color.white.opacity(0.15)) {
                dismiss()
            }
            .accessibilityLabel(Text("Close"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            actionButton(icon: "square.and.arrow.up", title: "Share") {
                share()
            }
            .disabled(currentItem == nil)
            actionButton(icon: isSaving ? "hourglass" : "arrow.down.to.line", title: "Save") {
                Task {
                    await saveToPhotos()
                }
            }
            .disabled(isSaving || currentItem == nil)
            actionButton(icon: "trash", title: "Delete", tint: Theme.error) {
                isConfirmingDelete = true
            }
            .disabled(currentItem == nil)
        }
        .frame(maxWidth: 480)
        .padding(.horizontal, 16)
        .padding(.top, 28)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private func actionButton(
        icon: String,
        title: LocalizedStringKey,
        tint: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 52, height: 52)
                    .background(Color.white.opacity(0.12), in: Circle())
                Text(title)
                    .font(.appCaption)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: Actions

    private func reconcileAccess() {
        if let shareItems, !canShare(shareItems) {
            self.shareItems = nil
        }
        // Hide the original immediately in body, then close a revoked current page.
        guard currentItem != nil else {
            shareItems = nil
            isConfirmingDelete = false
            currentID = nil
            dismiss()
            return
        }
    }

    private func videoURL(for item: CollectedMedia) -> URL? {
        item.videoURL
    }

    private func fullImage(for item: CollectedMedia) -> UIImage? {
        guard !item.isVideo, canAccess(item), let source = item.photoSource else {
            return nil
        }
        return GalleryImageLoader.fullImage(for: source, maxPixelSize: 3000)
    }

    private func share() {
        guard let item = currentItem, canAccess(item) else {
            return
        }
        Haptics.tap()
        if item.isVideo {
            guard let url = videoURL(for: item) else {
                return
            }
            shareItems = GalleryShareItems(mediaID: item.id, items: [url])
            return
        }
        guard let image = fullImage(for: item),
            let data = image.jpegData(compressionQuality: 0.9)
        else {
            return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "Photo-\(item.id.uuidString.prefix(8)).jpg")
        do {
            try data.write(to: url, options: .atomic)
            guard canAccess(item) else {
                return
            }
            shareItems = GalleryShareItems(mediaID: item.id, items: [url])
        } catch {
            guard canAccess(item) else {
                return
            }
            shareItems = GalleryShareItems(mediaID: item.id, items: [image])
        }
    }

    private func saveToPhotos() async {
        guard isViewerActive, let item = currentItem, canAccess(item), !isSaving else {
            return
        }
        isSaving = true
        defer { isSaving = false }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        // Authorization can suspend while an entitlement expires or the viewer closes.
        guard !Task.isCancelled, isViewerActive, currentID == item.id, canAccess(item) else {
            return
        }
        guard status == .authorized || status == .limited else {
            model.showToast(
                LocalizedText("Allow access to Photos in Settings", ru: "Разреши доступ к Фото в Настройках").value,
                icon: "exclamationmark.triangle.fill"
            )
            return
        }

        let video = videoURL(for: item)
        let image = item.isVideo ? nil : fullImage(for: item)
        guard canAccess(item), video != nil || image != nil else {
            return
        }
        do {
            try await Self.addToLibrary(video: video, image: image)
            Haptics.success()
            model.showToast(
                LocalizedText("Saved to Photos", ru: "Сохранено в Фото").value,
                icon: "checkmark.circle.fill"
            )
        } catch {
            model.showToast(
                LocalizedText("Couldn't save. Try again.", ru: "Не удалось сохранить. Попробуй ещё раз.").value,
                icon: "exclamationmark.triangle.fill"
            )
        }
    }

    /// Runs the Photos change block outside the main actor (Photos calls it on its own queue).
    nonisolated private static func addToLibrary(video: URL?, image: UIImage?) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            if let video {
                _ = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: video)
            } else if let image {
                _ = PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        }
    }

    private func deleteCurrent() {
        guard let item = currentItem,
            let index = items.firstIndex(where: { $0.id == item.id }),
            let visibleIndex = accessibleItems.firstIndex(where: { $0.id == item.id })
        else {
            return
        }
        items.remove(at: index)
        model.context.delete(item)
        try? model.context.save()
        Haptics.tap()

        let remaining = accessibleItems
        if remaining.isEmpty {
            dismiss()
        } else {
            currentID = remaining[min(visibleIndex, remaining.count - 1)].id
        }
    }
}

// MARK: - Page

private struct GalleryViewerPage: View {
    @Environment(AppModel.self) private var model

    let item: CollectedMedia
    let isCurrent: Bool

    var body: some View {
        if item.isVideo {
            if let url = item.videoURL {
                GalleryVideoPage(url: url, isCurrent: isCurrent)
            } else {
                Color.black
            }
        } else if let photo = item.photoSource,
            !model.isGalleryPhotoLocked(photo, companionId: item.companionId)
        {
            GalleryZoomablePhoto(source: item.photoSource)
        } else {
            Color.black
        }
    }
}

private struct GalleryVideoPage: View {
    let url: URL
    let isCurrent: Bool

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            if player == nil {
                player = AVPlayer(url: url)
            }
            if isCurrent {
                player?.play()
            }
        }
        .onDisappear {
            player?.pause()
        }
        .onChange(of: isCurrent) { _, current in
            if current {
                player?.seek(to: .zero)
                player?.play()
            } else {
                player?.pause()
            }
        }
    }
}

private struct GalleryZoomablePhoto: View {
    let source: PhotoSource?

    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else {
                    ProgressView()
                        .tint(.white)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .contentShape(Rectangle())
            .gesture(magnifyGesture)
            .gesture(dragGesture, including: scale > 1 ? .all : .subviews)
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if scale > 1 {
                        resetZoom()
                    } else {
                        scale = 2.5
                        lastScale = 2.5
                    }
                }
            }
        }
        .task(id: source) {
            await load()
        }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(5, max(1, lastScale * value.magnification))
            }
            .onEnded { _ in
                if scale <= 1.02 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        resetZoom()
                    }
                } else {
                    lastScale = scale
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }

    private func load() async {
        image = nil
        guard let source else {
            return
        }
        let loaded = await Task.detached(priority: .userInitiated) {
            GalleryImageLoader.fullImage(for: source, maxPixelSize: 2400)
        }.value
        guard !Task.isCancelled else {
            return
        }
        image = loaded
    }
}

// MARK: - Full-resolution loading

/// Loads images at full quality, bypassing the thumbnail cache used by `PhotoView`.
nonisolated enum GalleryImageLoader {
    static func fullImage(for source: PhotoSource, maxPixelSize: CGFloat) -> UIImage? {
        switch source {
        case .asset(let name):
            return UIImage(named: name)
        case .file(let name):
            return ImageLoader.downsample(url: MediaStore.url(for: name), maxPixelSize: maxPixelSize)
        }
    }
}

// MARK: - Share sheet

struct GalleryShareItems: Identifiable {
    let id = UUID()
    let mediaID: UUID?
    let items: [Any]

    // Profile also uses this payload for non-gallery exports.
    init(mediaID: UUID? = nil, items: [Any]) {
        self.mediaID = mediaID
        self.items = items
    }
}

struct GalleryActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
