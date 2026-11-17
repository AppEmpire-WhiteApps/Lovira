import SwiftUI

private struct PremiumLockModifier: ViewModifier {
    let locked: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .blur(radius: locked ? 16 : 0)
            .allowsHitTesting(!locked)
            .accessibilityHidden(locked)
            .overlay {
                if locked {
                    Button(action: action) {
                        ZStack {
                            Color.black.opacity(0.18)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(16)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        Text(LocalizedText("Available with a subscription", ru: "Доступно по подписке").value))
                }
            }
            .clipped()
    }
}

extension View {
    func premiumLocked(_ locked: Bool, action: @escaping () -> Void) -> some View {
        modifier(PremiumLockModifier(locked: locked, action: action))
    }
}
