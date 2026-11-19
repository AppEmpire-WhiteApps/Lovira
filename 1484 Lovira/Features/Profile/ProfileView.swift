import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \Conversation.lastMessageAt, order: .reverse) private var conversations: [Conversation]

    @State private var isEditingName = false
    @State private var nameDraft = ""
    @State private var isConfirmingDelete = false
    @State private var exportShare: GalleryShareItems?

    private let achievementColumns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                titleBar
                ProfilePremiumBanner()
                headerCard
                achievementsSection
                privacySection
                voiceSection
                dataSection
                ProfileAppActions()
                footer
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .alert("Your name", isPresented: $isEditingName) {
            TextField("Name", text: $nameDraft)
                .textInputAutocapitalization(.words)
            Button("Save") {
                model.profile.userName = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("How should she call you?")
        }
        .confirmationDialog(
            "Delete all data?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete everything", role: .destructive) {
                model.deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All chats, photos, created characters and progress will be permanently deleted from this device.")
        }
        .sheet(item: $exportShare) { share in
            GalleryActivityView(items: share.items)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: Header

    private var titleBar: some View {
        Text("Profile")
            .font(.appTitle)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var initial: String {
        let name = model.profile.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.first.map { String($0).uppercased() } ?? ""
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.ctaGradient)
                if initial.isEmpty {
                    Image(systemName: "person.fill")
                        .font(.system(size: 28, weight: .semibold))
                } else {
                    Text(verbatim: initial)
                        .font(.poppins(30, .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(width: 72, height: 72)
            .shadow(color: Theme.pink.opacity(0.4), radius: 12, y: 4)

            VStack(alignment: .leading, spacing: 6) {
                Button {
                    nameDraft = model.profile.userName
                    isEditingName = true
                } label: {
                    HStack(spacing: 8) {
                        Text(model.profile.displayName)
                            .font(.appH2)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Edit name"))

                HStack(spacing: 8) {
                    statChip(icon: "bubble.left.fill", value: model.profile.totalMessages)
                    statChip(icon: "heart.fill", value: conversations.count)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .cardBackground()
    }

    private func statChip(icon: String, value: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.pink)
            Text(verbatim: "\(value)")
                .font(.appCaptionBold)
                .foregroundStyle(Theme.textSecondary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Theme.surfaceHigh, in: Capsule())
    }

    // MARK: Achievements

    private var achievementsSection: some View {
        let unlocked = Achievement.allCases.filter { model.profile.hasAchievement($0) }.count
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.appH3)
                    .foregroundStyle(.white)
                Spacer()
                Text(verbatim: "\(unlocked)/\(Achievement.allCases.count)")
                    .font(.appCallout)
                    .foregroundStyle(Theme.textSecondary)
            }
            LazyVGrid(columns: achievementColumns, spacing: 10) {
                ForEach(Achievement.allCases) { achievement in
                    ProfileAchievementTile(
                        achievement: achievement,
                        isUnlocked: model.profile.hasAchievement(achievement)
                    )
                }
            }
        }
    }

    // MARK: Settings

    private var privacySection: some View {
        ProfileSettingsSection(title: "Privacy") {
            ProfileToggleRow(
                icon: "faceid",
                tint: Theme.violet,
                title: "App lock",
                subtitle: AppLock.isAvailable
                    ? AppLock.biometryName
                    : LocalizedText(
                        "Set up a passcode on this device first", ru: "Сначала настрой код-пароль на устройстве"
                    ).value,
                isDisabled: !AppLock.isAvailable,
                isOn: appLockBinding
            )
            ProfileRowDivider()
            Menu {
                Picker(selection: disappearBinding) {
                    ForEach(DisappearOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                } label: {
                    EmptyView()
                }
            } label: {
                ProfileRowContent(
                    icon: "timer",
                    tint: Theme.pink,
                    title: "Disappearing messages",
                    subtitle: LocalizedText("Default for new chats", ru: "По умолчанию для новых чатов").value,
                    value: model.profile.defaultDisappear.title,
                    trailingIcon: "chevron.up.chevron.down"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var voiceSection: some View {
        ProfileSettingsSection(title: "Voice & feel") {
            ProfileToggleRow(
                icon: "waveform",
                tint: Theme.pink,
                title: "Voice replies",
                subtitle: LocalizedText(
                    "She replies with a voice message only when you ask", ru: "Она отвечает голосовым только по твоей просьбе"
                ).value,
                isOn: voiceRepliesBinding
            )
            ProfileRowDivider()
            ProfileToggleRow(
                icon: "iphone.radiowaves.left.and.right",
                tint: Theme.blue,
                title: "Haptics",
                isOn: hapticsBinding
            )
        }
    }

    private var dataSection: some View {
        ProfileSettingsSection(title: "Data") {
            ProfileActionRow(
                icon: "square.and.arrow.up",
                tint: Theme.online,
                title: "Export chats",
                subtitle: LocalizedText(
                    "Text file with all your conversations", ru: "Текстовый файл со всеми переписками"
                ).value
            ) {
                exportChats()
            }
            ProfileRowDivider()
            ProfileActionRow(
                icon: "trash.fill",
                tint: Theme.error,
                title: "Delete all data",
                titleColor: Theme.error
            ) {
                isConfirmingDelete = true
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text(verbatim: ProfileAppInfo.versionText)
                .font(.appCaption)
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.top, 8)
    }

    // MARK: Bindings

    private var appLockBinding: Binding<Bool> {
        Binding {
            model.profile.appLockEnabled
        } set: { newValue in
            guard newValue else {
                model.profile.appLockEnabled = false
                return
            }
            Task {
                if await model.lock.authenticate() {
                    model.profile.appLockEnabled = true
                    Haptics.success()
                }
            }
        }
    }

    private var disappearBinding: Binding<DisappearOption> {
        Binding {
            model.profile.defaultDisappear
        } set: { newValue in
            model.profile.defaultDisappear = newValue
        }
    }

    private var voiceRepliesBinding: Binding<Bool> {
        Binding {
            model.access.isPremium && model.profile.autoVoiceReplies
        } set: { newValue in
            guard !newValue || model.authorize(.voice) else { return }
            model.profile.autoVoiceReplies = newValue
        }
    }

    private var hapticsBinding: Binding<Bool> {
        Binding {
            model.profile.hapticsEnabled
        } set: { newValue in
            model.profile.hapticsEnabled = newValue
            Haptics.isEnabled = newValue
            Haptics.tap()
        }
    }

    // MARK: Actions

    private func exportChats() {
        guard !conversations.isEmpty else {
            model.showToast(
                LocalizedText("No chats to export yet", ru: "Пока нечего экспортировать").value,
                icon: "tray"
            )
            return
        }
        do {
            let url = try ProfileChatExporter.makeFile(
                conversations: conversations,
                userName: model.profile.displayName
            ) { companionId in
                model.companion(id: companionId)?.name ?? LocalizedText("Companion", ru: "Собеседница").value
            }
            exportShare = GalleryShareItems(items: [url])
        } catch {
            model.showToast(error.localizedDescription, icon: "exclamationmark.triangle.fill")
        }
    }

}
