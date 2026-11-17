import Foundation

struct CompanionReply {
    var text: String
    var sendPhoto: Bool
    var photoPrompt: String
    var mood: String
}

/// High-level LLM operations on top of `LLMAppsClient`.
final class ChatEngine {
    private let client: LLMAppsClient

    init(client: LLMAppsClient) {
        self.client = client
    }

    func reply(system: String, history: [[String: Any]], maxTokens: Int) async throws -> CompanionReply {
        var messages: [[String: Any]] = [["role": "system", "content": system]]
        messages.append(contentsOf: history)
        let content = try await client.chat(
            messages: messages,
            maxTokens: maxTokens,
            responseFormat: PromptBuilder.replyFormat
        )
        return Self.parseReply(content)
    }

    static func parseReply(_ content: String) -> CompanionReply {
        let cleaned = stripCodeFence(content)
        guard let data = cleaned.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = object["reply"] as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return CompanionReply(text: content.trimmingCharacters(in: .whitespacesAndNewlines), sendPhoto: false, photoPrompt: "", mood: "happy")
        }
        return CompanionReply(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            sendPhoto: object["send_photo"] as? Bool ?? false,
            photoPrompt: object["photo_prompt"] as? String ?? "",
            mood: object["mood"] as? String ?? "happy"
        )
    }

    func extractFacts(transcript: String, known: [String]) async throws -> [String] {
        var prompt = PromptBuilder.memoryPrompt
        if !known.isEmpty {
            prompt += "\nAlready known facts:\n" + known.map { "- \($0)" }.joined(separator: "\n")
        }
        let messages: [[String: Any]] = [
            ["role": "system", "content": prompt],
            ["role": "user", "content": transcript]
        ]
        let content = try await client.chat(
            messages: messages,
            maxTokens: 300,
            responseFormat: ["type": "json_object"]
        )
        guard let data = Self.stripCodeFence(content).data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let facts = object["facts"] as? [String] else {
            return []
        }
        return facts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Speech-to-text through the chat endpoint (`input_audio`).
    func transcribe(audioURL: URL) async throws -> String {
        let data = try Data(contentsOf: audioURL)
        let content: [[String: Any]] = [
            [
                "type": "text",
                "text": "Transcribe this voice message verbatim in its original language. Output only the transcript text, nothing else."
            ],
            [
                "type": "input_audio",
                "input_audio": [
                    "data": data.base64EncodedString(),
                    "format": audioURL.pathExtension.lowercased()
                ]
            ]
        ]
        let text = try await client.chat(messages: [["role": "user", "content": content]], maxTokens: 500)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Builds a user message that contains an image for vision-capable chat.
    static func imageMessage(text: String, jpeg: Data) -> [String: Any] {
        [
            "role": "user",
            "content": [
                ["type": "text", "text": text],
                [
                    "type": "image_url",
                    "image_url": ["url": "data:image/jpeg;base64," + jpeg.base64EncodedString()]
                ]
            ] as [[String: Any]]
        ]
    }

    private static func stripCodeFence(_ text: String) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if result.hasPrefix("```") {
            if let newline = result.firstIndex(of: "\n") {
                result = String(result[result.index(after: newline)...])
            }
            if result.hasSuffix("```") {
                result = String(result.dropLast(3))
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
