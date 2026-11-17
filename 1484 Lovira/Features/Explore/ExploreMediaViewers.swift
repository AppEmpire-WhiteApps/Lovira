import AVFoundation
import AVKit
import SwiftUI

struct ExplorePhotoViewerItem: Identifiable {
    let id = UUID()
    let photos: [PhotoSource]
    let index: Int
}

struct ExploreVideoItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// Full-screen paged photo viewer with pinch-to-zoom.
struct ExplorePhotoViewer: View {
    let companionId: String
    let photos: [PhotoSource]

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var selection: PhotoSource?

    init(companionId: String, photos: [PhotoSource], startIndex: Int) {
        self.companionId = companionId
        self.photos = photos
        let index = min(max(0, startIndex), max(0, photos.count - 1))
        _selection = State(initialValue: photos.indices.contains(index) ? photos[index] : nil)
    }

    private var unlockedPhotos: [PhotoSource] {
        photos.filter { !model.isGalleryPhotoLocked($0, companionId: companionId) }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(unlockedPhotos, id: \.self) { photo in
                    ExploreZoomablePhoto(source: photo)
                        .tag(Optional(photo))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            HStack {
                if let selection,
                   let index = unlockedPhotos.firstIndex(of: selection),
                   unlockedPhotos.count > 1 {
                    Text(verbatim: "\(index + 1) / \(unlockedPhotos.count)")
                        .font(.appCallout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.4), in: Capsule())
                }
                Spacer()
                CircleIconButton(systemName: "xmark", background: .black.opacity(0.45)) {
                    dismiss()
                }
                .accessibilityLabel(Text("Close"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .statusBarHidden()
        .onAppear {
            dismissIfSelectionLocked()
        }
        .onChange(of: unlockedPhotos) { _, _ in
            dismissIfSelectionLocked()
        }
    }

    private func dismissIfSelectionLocked() {
        guard let selection, unlockedPhotos.contains(selection) else {
            dismiss()
            return
        }
    }
}

private struct ExploreZoomablePhoto: View {
    let source: PhotoSource

    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var baseScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnification)
                        .simultaneousGesture(scale > 1 ? drag : nil)
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if scale > 1 {
                                    resetZoom()
                                } else {
                                    scale = 2.5
                                    baseScale = 2.5
                                }
                            }
                        }
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .task(id: source) {
            await load()
        }
    }

    private var magnification: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(5, max(1, baseScale * value.magnification))
            }
            .onEnded { _ in
                if scale <= 1.02 {
                    withAnimation(.spring(response: 0.3)) {
                        resetZoom()
                    }
                } else {
                    baseScale = scale
                }
            }
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: baseOffset.width + value.translation.width,
                    height: baseOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                baseOffset = offset
            }
    }

    private func resetZoom() {
        scale = 1
        baseScale = 1
        offset = .zero
        baseOffset = .zero
    }

    private func load() async {
        let source = source
        let loaded = await Task.detached(priority: .userInitiated) {
            ImageLoader.loadImage(for: source, maxPixelSize: 2400)
        }.value
        image = loaded
    }
}

/// Full-screen looping player for bundled character videos.
struct ExploreVideoPlayerView: View {
    let url: URL

    @Environment(\.dismiss) private var dismiss
    @State private var player = AVQueuePlayer()
    @State private var looper: AVPlayerLooper?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            VideoPlayer(player: player)
                .ignoresSafeArea()
            CircleIconButton(systemName: "xmark", background: .black.opacity(0.45)) {
                dismiss()
            }
            .accessibilityLabel(Text("Close"))
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .onAppear {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            let item = AVPlayerItem(url: url)
            looper = AVPlayerLooper(player: player, templateItem: item)
            player.play()
        }
        .onDisappear {
            player.pause()
            looper = nil
        }
    }
}
