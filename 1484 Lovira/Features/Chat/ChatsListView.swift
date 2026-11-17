import SwiftData
import SwiftUI

struct ChatsListView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \Conversation.lastMessageAt, order: .reverse) private var conversations: [Conversation]
    @State private var pendingDelete: Conversation?

    private var sorted: [Conversation] {
        conversations.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            return lhs.lastMessageAt > rhs.lastMessageAt
        }
    }

    var body: some View {
        Group {
            if conversations.isEmpty {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "No chats yet",
                    message: "Pick a girl you like and say hi — she's waiting for you",
                    actionTitle: "Start chatting"
                ) {
                    model.selectedTab = .explore
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(sorted) { conversation in
                        if let companion = model.companion(id: conversation.companionId) {
                            row(conversation, companion: companion)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Chats")
        .toolbarBackground(Theme.background, for: .navigationBar)
        .confirmationDialog(
            "Delete this chat?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete chat", role: .destructive) {
                if let pendingDelete {
                    model.delete(pendingDelete)
                }
                pendingDelete = nil
            }
        }
    }

    private func row(_ conversation: Conversation, companion: Companion) -> some View {
        Button {
            model.openChat(companion.id)
        } label: {
            HStack(spacing: 14) {
                AvatarView(source: companion.avatar, size: 58, showsOnline: true)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(verbatim: companion.name)
                            .font(.poppins(16, .semibold))
                            .foregroundStyle(.white)
                        if conversation.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        if conversation.scenarioId != nil {
                            Image(systemName: "theatermasks.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.violet)
                        }
                        Spacer()
                        Text(timeLabel(conversation.lastMessageAt))
                            .font(.appCaption)
                            .foregroundStyle(conversation.unreadCount > 0 ? Theme.pink : Theme.textTertiary)
                    }
                    HStack {
                        Text(verbatim: conversation.lastMessagePreview.isEmpty ? " " : conversation.lastMessagePreview)
                            .font(.appSubheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                        Spacer()
                        if conversation.unreadCount > 0 {
                            Text(verbatim: "\(conversation.unreadCount)")
                                .font(.poppins(11, .bold))
                                .foregroundStyle(.white)
                                .frame(minWidth: 20, minHeight: 20)
                                .padding(.horizontal, 4)
                                .background(Theme.ctaGradient, in: Capsule())
                        }
                    }
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .premiumLocked(model.isCharacterLocked(companion.id)) { model.showPaywall() }
        .listRowBackground(Color.clear)
        .listRowSeparatorTint(Theme.stroke)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                pendingDelete = conversation
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                conversation.isPinned.toggle()
                try? model.context.save()
            } label: {
                Label(conversation.isPinned ? "Unpin" : "Pin", systemImage: conversation.isPinned ? "pin.slash" : "pin")
            }
            .tint(Theme.violet)
        }
    }

    private func timeLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        if Calendar.current.isDateInYesterday(date) {
            return LocalizedText("Yesterday", ru: "Вчера").value
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}
