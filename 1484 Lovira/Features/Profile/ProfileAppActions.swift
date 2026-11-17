import SwiftUI
import UIKit

struct ProfileAppActions: View {
    @Environment(\.openURL) private var openURL
    @Environment(AppModel.self) private var model
    @State private var share: GalleryShareItems?
    @State private var legalDocument: WelcomeLegalDocument?
    @State private var showsSupportEmail = false
    @State private var showsVersion = false

    var body: some View {
        VStack(spacing: 22) {
            sharingSection
            supportSection
            legalSection
        }
        .sheet(item: $share) { item in
            GalleryActivityView(items: item.items)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $legalDocument) { document in
            WelcomeLegalScreen(document: document)
        }
        .alert(LocalizedText("Contact support", ru: "Связаться с поддержкой").value, isPresented: $showsSupportEmail) {
            Button(LocalizedText("Copy email", ru: "Скопировать почту").value) {
                UIPasteboard.general.string = ProfileAppInfo.supportEmail
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(verbatim: ProfileAppInfo.supportEmail)
        }
        .alert(LocalizedText("Current version", ru: "Текущая версия").value, isPresented: $showsVersion) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(verbatim: ProfileAppInfo.versionText)
        }
    }

    private var sharingSection: some View {
        ProfileSettingsSection(title: "About") {
            ProfileActionRow(
                icon: "square.and.arrow.up",
                title: "Share app",
                subtitle: LocalizedText("Share with friends", ru: "Поделиться с друзьями").value
            ) {
                guard let url = ProfileAppInfo.appStoreURL else { return }
                share = GalleryShareItems(items: [url])
            }
            .accessibilityIdentifier("profile.shareApp")
            ProfileRowDivider()
            ProfileActionRow(
                icon: "star.fill",
                tint: Theme.gold,
                title: "Rate app",
                subtitle: LocalizedText("Your feedback matters", ru: "Ваш отзыв важен").value
            ) {
                openStore(ProfileAppInfo.reviewURL)
            }
            .accessibilityIdentifier("profile.rateApp")
        }
    }

    private var supportSection: some View {
        ProfileSettingsSection(title: "Support") {
            ProfileActionRow(icon: "envelope.fill", title: "Contact support") {
                guard let url = ProfileAppInfo.supportURL else {
                    showsSupportEmail = true
                    return
                }
                openURL(url) { accepted in
                    if !accepted {
                        showsSupportEmail = true
                    }
                }
            }
            .accessibilityIdentifier("profile.support")
            ProfileRowDivider()
            ProfileActionRow(
                icon: "arrow.down.circle.fill",
                tint: Theme.blue,
                title: "Update app",
                subtitle: LocalizedText("Check for the latest version", ru: "Проверить новую версию").value
            ) {
                openStore(ProfileAppInfo.appStoreURL)
            }
            .accessibilityIdentifier("profile.updateApp")
            ProfileRowDivider()
            ProfileActionRow(
                icon: "info.circle.fill",
                tint: Theme.textSecondary,
                title: "Current version",
                subtitle: ProfileAppInfo.versionText
            ) {
                showsVersion = true
            }
            .accessibilityIdentifier("profile.version")
        }
    }

    private var legalSection: some View {
        ProfileSettingsSection(title: "Legal") {
            ProfileActionRow(icon: "hand.raised.fill", tint: Theme.textSecondary, title: "Privacy Policy") {
                legalDocument = .privacy
            }
            .accessibilityIdentifier("profile.privacy")
            ProfileRowDivider()
            ProfileActionRow(icon: "doc.text.fill", tint: Theme.textSecondary, title: "Terms of Use") {
                legalDocument = .terms
            }
            .accessibilityIdentifier("profile.terms")
        }
    }

    private func openStore(_ url: URL?) {
        guard let url else { return }
        openURL(url) { accepted in
            if !accepted {
                model.showToast(
                    LocalizedText("Could not open the App Store", ru: "Не удалось открыть App Store").value,
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
    }
}
