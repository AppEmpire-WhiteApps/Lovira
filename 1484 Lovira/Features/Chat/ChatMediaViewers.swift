import AVKit
import SwiftUI

struct ChatPhotoViewer: View {
    let photo: PhotoSource

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            PhotoView(source: photo, maxPixelSize: 2000)
                .aspectRatio(3 / 4, contentMode: .fit)
                .scaleEffect(scale)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            scale = max(1, min(4, lastScale * value.magnification))
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring) {
                        scale = scale > 1 ? 1 : 2
                        lastScale = scale
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            CircleIconButton(systemName: "xmark", background: Color.black.opacity(0.5)) {
                dismiss()
            }
            .padding(16)
        }
    }
}

struct ChatVideoPlayer: View {
    let url: URL

    @Environment(\.dismiss) private var dismiss
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }
            CircleIconButton(systemName: "xmark", background: Color.black.opacity(0.5)) {
                dismiss()
            }
            .padding(16)
        }
        .onAppear {
            guard player == nil else {
                return
            }
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            let queue = AVQueuePlayer()
            looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: url))
            player = queue
            queue.play()
        }
        .onDisappear {
            player?.pause()
        }
    }
}
