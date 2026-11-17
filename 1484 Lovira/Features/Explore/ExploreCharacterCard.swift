import SwiftUI

/// Photo-first 3:4 character card for the Explore grid.
struct ExploreCharacterCard: View {
    let companion: Companion

    var body: some View {
        PhotoView(source: companion.cover, maxPixelSize: 900)
            .aspectRatio(3 / 4, contentMode: .fit)
            .overlay {
                Theme.cardFade
            }
            .overlay(alignment: .bottomLeading) {
                info
            }
            .overlay(alignment: .topLeading) {
                if companion.isNew {
                    newTag
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.06), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .accessibilityElement(children: .combine)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(verbatim: "\(companion.name), \(companion.age)")
                    .font(.poppins(16, .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                OnlineDot(size: 8)
            }
            if !companion.occupation.isEmpty {
                Text(verbatim: companion.occupation)
                    .font(.appCaption)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }
        }
        .padding(12)
    }

    private var newTag: some View {
        Text("New")
            .font(.poppins(11, .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.ctaGradient, in: Capsule())
            .padding(10)
    }
}

/// Small card for the horizontal "My characters" row.
struct ExploreMiniCard: View {
    let companion: Companion

    var body: some View {
        PhotoView(source: companion.cover, maxPixelSize: 500)
            .frame(width: 120, height: 160)
            .overlay {
                Theme.cardFade
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: companion.name)
                        .font(.poppins(14, .semibold))
                        .lineLimit(1)
                    Text(verbatim: "\(companion.age)")
                        .font(.appCaption)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .foregroundStyle(.white)
                .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
