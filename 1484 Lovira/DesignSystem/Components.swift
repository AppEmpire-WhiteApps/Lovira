import SwiftUI

struct ChipView: View {
    let title: String
    var icon: String?
    var isSelected = false

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(title)
        }
        .font(.appCallout)
        .foregroundStyle(isSelected ? .white : Theme.textSecondary)
        .padding(.horizontal, 14)
        .frame(height: 36)
        .background(isSelected ? Theme.pinkBackground : Theme.surfaceHigh, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(isSelected ? Theme.pink : .clear, lineWidth: 1.5)
        }
    }
}

struct TagView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.appCaption)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

struct SectionHeader: View {
    let title: LocalizedStringKey
    var trailing: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.appH3)
                .foregroundStyle(.white)
            Spacer()
            if let trailing, let action {
                Button(action: action) {
                    Text(trailing)
                        .font(.appCallout)
                        .foregroundStyle(Theme.pink)
                }
            }
        }
    }
}

struct OnlineDot: View {
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(Theme.online)
            .frame(width: size, height: size)
            .overlay {
                Circle().strokeBorder(Theme.background, lineWidth: 2)
            }
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.12), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.6)
                    .offset(x: phase * proxy.size.width * 1.6)
                }
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }

    func cardBackground(cornerRadius: CGFloat = Theme.cornerRadius) -> some View {
        background(Theme.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct ToastView: View {
    let text: String
    var icon: String = "sparkles"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.pink)
            Text(text)
                .font(.appCallout)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.surfaceHigh, in: Capsule())
        .overlay {
            Capsule().strokeBorder(Theme.stroke, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.pinkBackground)
                    .frame(width: 96, height: 96)
                Image(systemName: icon)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Theme.ctaGradient)
            }
            Text(title)
                .font(.appH3)
                .foregroundStyle(.white)
            Text(message)
                .font(.appSubheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 260)
                    .padding(.top, 6)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
