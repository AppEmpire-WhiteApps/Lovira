import SwiftUI

/// Displays a bundled asset or a locally stored photo, loading files off the main thread.
struct PhotoView: View {
    let source: PhotoSource?
    var maxPixelSize: CGFloat = 1200

    @State private var image: UIImage?

    var body: some View {
        Color.clear
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }
            }
            .clipped()
            .task(id: source) {
                await load()
            }
    }

    private var placeholder: some View {
        ZStack {
            Theme.surfaceHigh
            Image(systemName: "photo")
                .font(.system(size: 22))
                .foregroundStyle(Theme.textTertiary)
        }
        .shimmering()
    }

    private func load() async {
        guard let source else {
            image = nil
            return
        }
        if let cached = ImageLoader.cachedImage(for: source) {
            image = cached
            return
        }
        let size = maxPixelSize
        let loaded = await Task.detached(priority: .userInitiated) {
            ImageLoader.loadImage(for: source, maxPixelSize: size)
        }.value
        image = loaded
    }
}

struct AvatarView: View {
    let source: PhotoSource?
    var size: CGFloat = 44
    var showsOnline = false

    var body: some View {
        PhotoView(source: source, maxPixelSize: size * 3)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(alignment: .bottomTrailing) {
                if showsOnline {
                    OnlineDot(size: max(10, size * 0.24))
                }
            }
    }
}
