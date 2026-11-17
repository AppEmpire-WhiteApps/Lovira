import SwiftUI

struct ProfileSettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.appCaptionBold)
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)
                .padding(.leading, 6)
            VStack(spacing: 0) {
                content
            }
            .cardBackground(cornerRadius: 18)
        }
    }
}

struct ProfileRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.stroke)
            .frame(height: 0.5)
            .padding(.leading, 62)
    }
}

struct ProfileRowIcon: View {
    let systemName: String
    let tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 34, height: 34)
            .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct ProfileRowLabel: View {
    let icon: String
    var tint: Color = Theme.pink
    let title: LocalizedStringKey
    var subtitle: String?
    var titleColor: Color = .white

    var body: some View {
        HStack(spacing: 14) {
            ProfileRowIcon(systemName: icon, tint: tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appBodyMedium)
                    .foregroundStyle(titleColor)
                if let subtitle {
                    Text(subtitle)
                        .font(.appCaption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer(minLength: 8)
        }
    }
}

struct ProfileToggleRow: View {
    let icon: String
    var tint: Color = Theme.pink
    let title: LocalizedStringKey
    var subtitle: String?
    var isDisabled = false
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            ProfileRowLabel(icon: icon, tint: tint, title: title, subtitle: subtitle)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.pink)
                .disabled(isDisabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

struct ProfileActionRow: View {
    let icon: String
    var tint: Color = Theme.pink
    let title: LocalizedStringKey
    var subtitle: String?
    var value: String?
    var titleColor: Color = .white
    var trailingIcon = "chevron.right"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ProfileRowContent(
                icon: icon,
                tint: tint,
                title: title,
                subtitle: subtitle,
                value: value,
                titleColor: titleColor,
                trailingIcon: trailingIcon
            )
        }
        .buttonStyle(.plain)
    }
}

struct ProfileRowContent: View {
    let icon: String
    var tint: Color = Theme.pink
    let title: LocalizedStringKey
    var subtitle: String?
    var value: String?
    var titleColor: Color = .white
    var trailingIcon = "chevron.right"

    var body: some View {
        HStack(spacing: 10) {
            ProfileRowLabel(icon: icon, tint: tint, title: title, subtitle: subtitle, titleColor: titleColor)
            if let value {
                Text(value)
                    .font(.appSubheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Image(systemName: trailingIcon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct ProfileAchievementTile: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: achievement.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isUnlocked ? AnyShapeStyle(Color.white) : AnyShapeStyle(Theme.textTertiary))
                    .frame(width: 40, height: 40)
                    .background {
                        if isUnlocked {
                            Circle().fill(Theme.premiumGradient)
                        } else {
                            Circle().fill(Theme.surfaceHigh)
                        }
                    }
                Spacer()
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.online)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.poppins(14, .semibold))
                    .foregroundStyle(isUnlocked ? .white : Theme.textSecondary)
                    .lineLimit(1)
                Text(achievement.subtitle)
                    .font(.appCaption)
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(2, reservesSpace: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: 18)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isUnlocked ? Theme.violet.opacity(0.5) : .clear, lineWidth: 1)
        }
    }
}
