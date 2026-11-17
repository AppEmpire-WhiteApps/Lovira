import Foundation

/// Builds a plain-text export of all conversations for the share sheet.
enum ProfileChatExporter {
    static func makeFile(
        conversations: [Conversation],
        userName: String,
        companionName: (String) -> String
    ) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        var lines: [String] = ["AI Companion — \(formatter.string(from: .now))", ""]
        let sorted = conversations.sorted { $0.lastMessageAt > $1.lastMessageAt }
        for conversation in sorted {
            let name = companionName(conversation.companionId)
            lines.append("=== \(name) ===")
            for message in conversation.sortedMessages {
                let time = formatter.string(from: message.createdAt)
                switch message.role {
                case .system:
                    lines.append("[\(time)] — \(message.text) —")
                case .user, .assistant:
                    let author = message.role == .user ? userName : name
                    lines.append("[\(time)] \(author): \(body(of: message))")
                }
            }
            lines.append("")
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Chats.txt")
        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func body(of message: ChatMessage) -> String {
        let text = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let transcript = message.transcript?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        switch message.kind {
        case .voice:
            let spoken = transcript.isEmpty ? text : transcript
            return "[Voice] \(spoken)"
        case .photo:
            return text.isEmpty ? "[Photo]" : "[Photo] \(text)"
        case .video:
            return text.isEmpty ? "[Video]" : "[Video] \(text)"
        case .text, .system:
            return text
        }
    }
}
