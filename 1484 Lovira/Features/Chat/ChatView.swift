import Combine
import SwiftUI

struct ChatView: View {
    let companionId: String

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var controller: ChatController?

    var body: some View {
        Group {
            if let controller {
                ChatContentView(controller: controller)
            } else {
                Theme.background.ignoresSafeArea()
            }
        }
        .onAppear {
            guard AIConsentStore.shared.request(onApprove: prepareChat, onCancel: { dismiss() }) else {
                return
            }
            prepareChat()
        }
        .onDisappear {
            if !AIConsentStore.shared.hasGranted {
                AIConsentStore.shared.cancel(notifyCancellation: false)
            }
        }
        .premiumLocked(model.isCharacterLocked(companionId)) { model.showPaywall() }
    }

    private func prepareChat() {
        guard AIConsentStore.shared.hasGranted, controller == nil,
            let companion = model.companion(id: companionId)
        else {
            return
        }
        controller = ChatController(companion: companion, model: model)
    }
}

private struct ChatContentView: View {
    @Bindable var controller: ChatController

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    @State private var confirmClear = false
    @State private var confirmDelete = false
    @State private var viewerPhoto: PhotoSource?
    @State private var videoItem: ChatVideoItem?
    @State private var followsBottom = true
    @GestureState private var isDraggingMessages = false
    @State private var isReturningToBottom = false
    @State private var scrollMetrics = ChatScrollMetrics()
    @State private var scrollRevision = 0

    private let purgeTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var companion: Companion {
        controller.companion
    }

    var body: some View {
        VStack(spacing: 0) {
            if let scenario = controller.scenario {
                scenarioBanner(scenario)
            }
            messageList
            ChatInputArea(controller: controller, isInputFocused: $isInputFocused)
        }
        .background(background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.backgroundSecondary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                header
            }
            ToolbarItem(placement: .topBarTrailing) {
                menu
            }
        }
        .confirmationDialog("Clear this chat?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear chat", role: .destructive) {
                model.clear(controller.conversation)
            }
        }
        .confirmationDialog("Delete this chat?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete chat", role: .destructive) {
                let conversation = controller.conversation
                dismiss()
                model.delete(conversation)
            }
        }
        .fullScreenCover(item: $viewerPhoto) { photo in
            ChatPhotoViewer(photo: photo)
        }
        .fullScreenCover(item: $videoItem) { item in
            ChatVideoPlayer(url: item.url)
        }
        .onChange(of: model.access.isPremium) { _, premium in
            if !premium {
                viewerPhoto = nil
                model.speech.stop()
                model.voicePlayer.stop()
            }
        }
        .onAppear {
            controller.isVisible = true
            controller.markRead()
            controller.recoverInterruptedMedia()
            model.purgeExpiredMessages()
            #if DEBUG
                if let text = UserDefaults.standard.string(forKey: "debugMessage"), controller.messages.count <= 1 {
                    controller.sendText(text)
                }
            #endif
        }
        .onDisappear {
            controller.isVisible = false
            model.speech.stop()
            model.voicePlayer.stop()
        }
        .onReceive(purgeTimer) { _ in
            model.purgeExpiredMessages()
        }
    }

    private var background: some View {
        ZStack {
            Theme.background
            RadialGradient(
                colors: [Theme.pink.opacity(0.10), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        Button {
            model.path(for: model.selectedTab).wrappedValue.append(.companion(companion.id))
        } label: {
            HStack(spacing: 10) {
                AvatarView(source: companion.avatar, size: 36, showsOnline: true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: companion.name)
                        .font(.poppins(16, .semibold))
                        .foregroundStyle(.white)
                    Group {
                        if controller.isTyping {
                            Text("typing…")
                                .foregroundStyle(Theme.pink)
                        } else {
                            Text("online")
                                .foregroundStyle(Theme.online)
                        }
                    }
                    .font(.appCaption)
                }
                IntimacyHearts(level: controller.intimacyLevel)
            }
        }
        .buttonStyle(.plain)
    }

    private var menu: some View {
        Menu {
            Button {
                model.path(for: model.selectedTab).wrappedValue.append(.companion(companion.id))
            } label: {
                Label("View profile", systemImage: "person.crop.circle")
            }
            Button {
                model.path(for: model.selectedTab).wrappedValue.append(.scenarios(companion.id))
            } label: {
                Label("Scenarios", systemImage: "theatermasks")
            }
            Menu {
                ForEach(DisappearOption.allCases) { option in
                    Button {
                        controller.setDisappear(option)
                    } label: {
                        if controller.conversation.disappearAfter == option.rawValue {
                            Label(option.title, systemImage: "checkmark")
                        } else {
                            Text(option.title)
                        }
                    }
                }
            } label: {
                Label("Disappearing messages", systemImage: "timer")
            }
            Divider()
            Button(role: .destructive) {
                confirmClear = true
            } label: {
                Label("Clear chat", systemImage: "eraser")
            }
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label("Delete chat", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Theme.surfaceHigh, in: Circle())
        }
    }

    private func scenarioBanner(_ scenario: Scenario) -> some View {
        HStack(spacing: 10) {
            Image(systemName: scenario.icon)
                .foregroundStyle(Color(hex: scenario.tint))
            VStack(alignment: .leading, spacing: 0) {
                Text("Scenario")
                    .font(.appCaption)
                    .foregroundStyle(Theme.textSecondary)
                Text(verbatim: scenario.title.value)
                    .font(.appCallout)
                    .foregroundStyle(.white)
            }
            Spacer()
            Button("End") {
                model.endScenario(in: controller.conversation)
            }
            .font(.appCaptionBold)
            .foregroundStyle(Theme.pink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.surface)
    }

    private var scrollUpdate: ChatScrollUpdate {
        ChatScrollUpdate(
            messageIDs: controller.messages.map(\.id),
            lastUserMessageID: controller.messages.last(where: { $0.role == .user })?.id,
            isTyping: controller.isTyping,
            isInputFocused: isInputFocused
        )
    }

    private var messageList: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        LazyVStack(spacing: 6) {
                            ForEach(Array(controller.messages.enumerated()), id: \.element.id) { index, message in
                                if showsDate(at: index) {
                                    DaySeparator(date: message.createdAt)
                                }
                                MessageRow(
                                    message: message,
                                    companion: companion,
                                    isLastAssistant: message.role == .assistant
                                        && message.id == controller.messages.last?.id,
                                    controller: controller,
                                    onOpenPhoto: { viewerPhoto = $0 },
                                    onOpenVideo: { videoItem = ChatVideoItem(url: $0) }
                                )
                                .id(message.id)
                            }
                            if controller.isTyping {
                                TypingIndicator(avatar: companion.avatar)
                            }
                        }
                        .frame(maxWidth: 760)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)

                        // Outside the lazy stack: the target exists even while reading old messages.
                        Color.clear
                            .frame(height: 1)
                            .id(ChatScrollAnchor.bottom)
                    }
                    .background {
                        GeometryReader { content in
                            Color.clear.preference(
                                key: ChatScrollMetricsKey.self,
                                value: ChatScrollMetrics(
                                    contentHeight: content.size.height,
                                    bottomY: content.frame(in: .named(ChatScrollAnchor.viewport)).maxY,
                                    viewportHeight: viewport.size.height
                                )
                            )
                        }
                    }
                }
                .coordinateSpace(name: ChatScrollAnchor.viewport)
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 4)
                        .updating($isDraggingMessages) { _, dragging, _ in
                            dragging = true
                        }
                        .onChanged { value in
                            followsBottom = false
                            isReturningToBottom = value.translation.height < 0
                        }
                        .onEnded { value in
                            // Neither a slow drag nor a fling into history should snap back down.
                            isReturningToBottom =
                                value.translation.height < 0
                                && value.predictedEndTranslation.height <= value.translation.height + 20
                        }
                )
                .onChange(of: isDraggingMessages) { _, dragging in
                    if dragging {
                        followsBottom = false
                        scrollRevision += 1
                    } else {
                        // GestureState also resets when recognition is cancelled (e.g. keyboard dismissal).
                        if isReturningToBottom && scrollMetrics.isNearBottom {
                            followsBottom = true
                        }
                        requestBottomScroll()
                    }
                }
                .onPreferenceChange(ChatScrollMetricsKey.self) { metrics in
                    updateScrollMetrics(metrics)
                }
                .onAppear {
                    requestBottomScroll()
                }
                .onChange(of: scrollUpdate) { old, new in
                    // A new outgoing message may follow even when its reply arrives in the same update.
                    if let userID = new.lastUserMessageID, !old.messageIDs.contains(userID) {
                        followsBottom = true
                    }
                    requestBottomScroll()
                }
                .task(id: scrollRevision) {
                    // Cancel/restart one request as message, typing and keyboard layout changes settle.
                    do {
                        try await Task.sleep(for: .milliseconds(35))
                    } catch {
                        return
                    }
                    guard !Task.isCancelled, followsBottom, !isDraggingMessages else { return }
                    var transaction = Transaction(animation: nil)
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        proxy.scrollTo(ChatScrollAnchor.bottom, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func requestBottomScroll() {
        guard followsBottom, !isDraggingMessages else { return }
        scrollRevision += 1
    }

    private func updateScrollMetrics(_ metrics: ChatScrollMetrics) {
        let layoutChanged =
            metrics.contentHeight != scrollMetrics.contentHeight
            || metrics.viewportHeight != scrollMetrics.viewportHeight
        let movedTowardsBottom = metrics.bottomY < scrollMetrics.bottomY
        scrollMetrics = metrics

        // Offset changes alone never schedule a scroll. They only restore follow at the bottom.
        if !layoutChanged, !isDraggingMessages, isReturningToBottom,
            !followsBottom, movedTowardsBottom, metrics.isNearBottom
        {
            followsBottom = true
        }
        if layoutChanged {
            requestBottomScroll()
        }
    }

    private func showsDate(at index: Int) -> Bool {
        let messages = controller.messages
        guard index > 0 else {
            return true
        }
        return !Calendar.current.isDate(messages[index].createdAt, inSameDayAs: messages[index - 1].createdAt)
    }
}

private enum ChatScrollAnchor: Hashable {
    case bottom
    case viewport
}

private struct ChatScrollUpdate: Equatable {
    let messageIDs: [UUID]
    let lastUserMessageID: UUID?
    let isTyping: Bool
    let isInputFocused: Bool
}

private struct ChatScrollMetrics: Equatable {
    var contentHeight: CGFloat = 0
    var bottomY: CGFloat = 0
    var viewportHeight: CGFloat = 0

    var isNearBottom: Bool {
        viewportHeight > 0 && bottomY <= viewportHeight + 44
    }
}

private struct ChatScrollMetricsKey: PreferenceKey {
    static var defaultValue: ChatScrollMetrics { ChatScrollMetrics() }

    static func reduce(value: inout ChatScrollMetrics, nextValue: () -> ChatScrollMetrics) {
        value = nextValue()
    }
}

struct ChatVideoItem: Identifiable {
    let url: URL

    var id: String { url.absoluteString }
}

extension PhotoSource: Identifiable {
    var id: String { key }
}

struct IntimacyHearts: View {
    let level: Int

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < level ? "heart.fill" : "heart")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(index < level ? Theme.pink : Theme.textTertiary)
            }
        }
        .accessibilityLabel(Text(LocalizedText("Closeness level \(level) of 5", ru: "Близость: \(level) из 5").value))
    }
}

private struct DaySeparator: View {
    let date: Date

    var body: some View {
        Text(label)
            .font(.appCaption)
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Theme.surface.opacity(0.8), in: Capsule())
            .padding(.vertical, 8)
    }

    private var label: String {
        if Calendar.current.isDateInToday(date) {
            return LocalizedText("Today", ru: "Сегодня").value
        }
        if Calendar.current.isDateInYesterday(date) {
            return LocalizedText("Yesterday", ru: "Вчера").value
        }
        return date.formatted(.dateTime.day().month(.wide))
    }
}

struct TypingIndicator: View {
    let avatar: PhotoSource
    @State private var phase = 0

    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            AvatarView(source: avatar, size: 28)
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Theme.textSecondary)
                        .frame(width: 7, height: 7)
                        .offset(y: phase == index ? -3 : 0)
                        .opacity(phase == index ? 1 : 0.5)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(Theme.surfaceHigh, in: BubbleShape(isUser: false))
            Spacer()
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.25)) {
                phase = (phase + 1) % 3
            }
        }
    }
}
