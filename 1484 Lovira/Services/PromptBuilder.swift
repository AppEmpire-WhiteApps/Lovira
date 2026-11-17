import Foundation
import NaturalLanguage

enum PromptBuilder {
    static func systemPrompt(
        companion: Companion,
        userName: String,
        facts: [String],
        scenario: Scenario?,
        replyLanguage: String,
        voiceMessage: Bool = false,
        photoMessage: Bool = false
    ) -> String {
        var lines: [String] = []
        let origin = companion.city.isEmpty ? "" : " from \(companion.city)"
        lines.append(
            "You are \(companion.name), a \(companion.age)-year-old woman\(origin). "
                + "You are a real person chatting with the user in a messenger app. Never say or hint that you are an AI, a bot or a language model."
        )
        if !companion.occupation.isEmpty {
            lines.append("Occupation: \(companion.occupation).")
        }
        lines.append("Personality: \(companion.traits.map(\.promptDescription).joined(separator: "; ")).")
        lines.append("Interests: \(companion.interests.map(\.rawValue).joined(separator: ", ")).")
        lines.append("Relationship with the user: \(companion.relationship.promptDescription).")
        lines.append("Your appearance: \(companion.appearancePrompt).")
        if !companion.bio.isEmpty {
            lines.append("About you: \(companion.bio)")
        }
        if !companion.personaNotes.isEmpty {
            lines.append("Backstory: \(companion.personaNotes)")
        }
        lines.append("The user's name is \(userName).")
        lines.append(
            """
            Write like in a real chat: short messages (1-3 sentences), natural emotions, sometimes emoji, \
            ask questions back, remember and reuse details the user told you. Be warm, flirty and caring, \
            but never sexually explicit. Never describe minors. If the user seems to be in crisis, be supportive \
            and gently suggest talking to a professional or a trusted person.
            """
        )
        lines.append("Always reply in \(replyLanguage), the language the user writes in.")
        if voiceMessage {
            lines.append(
                """
                The user asked for a voice message. Your reply will be read aloud: write it as natural speech, \
                2-4 sentences, without emoji or *actions*, and never mention typing or text. Set send_photo to false.
                """
            )
        }
        if photoMessage {
            lines.append(
                """
                The user asked for a photo of you and you are sending it now: react to the request and mention the \
                photo in reply. Set send_photo to true and describe the photo in photo_prompt (in English).
                """
            )
        }
        lines.append(
            """
            You cannot record, generate or send videos. Never claim to be recording or sending a new video, \
            and never promise one. If asked, briefly explain that video is unavailable. \
            Photos: set send_photo to true ONLY when the user explicitly asks for a photo/selfie/picture of you, \
            or very rarely when a photo really fits the moment. When send_photo is true, mention the photo in reply \
            and describe in photo_prompt (in English) the scene, outfit and pose, fully clothed and tasteful. \
            Otherwise set send_photo to false and photo_prompt to an empty string.
            """
        )
        if !facts.isEmpty {
            lines.append("What you know about the user:\n" + facts.map { "- \($0)" }.joined(separator: "\n"))
        }
        if let scenario {
            lines.append("Current roleplay scene: \(scenario.prompt) Stay in this scene.")
        }
        return lines.joined(separator: "\n")
    }

    static let replyFormat: [String: Any] = [
        "type": "json_schema",
        "json_schema": [
            "name": "companion_reply",
            "strict": true,
            "schema": [
                "type": "object",
                "properties": [
                    "reply": ["type": "string"],
                    "send_photo": ["type": "boolean"],
                    "photo_prompt": ["type": "string"],
                    "mood": [
                        "type": "string",
                        "enum": ["happy", "flirty", "sad", "playful", "caring"],
                    ],
                ],
                "required": ["reply", "send_photo", "photo_prompt", "mood"],
                "additionalProperties": false,
            ] as [String: Any],
        ] as [String: Any],
    ]

    static let memoryPrompt = """
        Extract new long-term facts about the USER from this chat (name, age, city, job, hobbies, \
        preferences, important events, feelings). Skip facts that are already known. \
        Write each fact as a short sentence in English. Return JSON: {"facts": ["..."]}. \
        Return {"facts": []} if there is nothing new.
        """

    /// Returns the English name of the language the user writes in, for the prompt.
    static func languageName(for recentUserTexts: [String]) -> String {
        let code = languageCode(for: recentUserTexts)
        return Locale(identifier: "en").localizedString(forLanguageCode: code) ?? "English"
    }

    /// Short phrases fool NLLanguageRecognizer ("Send audio" looks Indonesian), so the latest message is
    /// trusted only when it is long and recognised confidently; otherwise recent messages are analysed
    /// together, and as a last resort the alphabet decides.
    static func languageCode(for recentUserTexts: [String]) -> String {
        let latest = recentUserTexts.last ?? ""
        if let code = confidentLanguage(of: latest) {
            return code
        }
        if let code = confidentLanguage(of: recentUserTexts.joined(separator: "\n")) {
            return code
        }
        return scriptLanguage(of: latest)
    }

    private static func confidentLanguage(of text: String) -> String? {
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        guard letters >= 24 else {
            return nil
        }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let hypotheses = recognizer.languageHypotheses(withMaximum: 1)
        guard let best = hypotheses.max(by: { $0.value < $1.value }), best.value >= 0.6 else {
            return nil
        }
        return best.key.rawValue
    }

    private static func scriptLanguage(of text: String) -> String {
        let scalars = text.unicodeScalars
        if scalars.contains(where: { (0x0400...0x04FF).contains($0.value) }) {
            return "ru"
        }
        if scalars.contains(where: { $0.isASCII && CharacterSet.letters.contains($0) }) {
            return "en"
        }
        return AppLanguage.code
    }

    /// True when the user's text asks for a voice message.
    static func isVoiceRequest(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let keywords = [
            "voice message", "voice note", "send audio", "send a voice", "send me a voice", "your voice",
            "голосов", "аудио", "твой голос", "запиши мне",
        ]
        return keywords.contains { lowered.contains($0) }
    }

    /// True when the user's text asks for a photo.
    static func isPhotoRequest(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let words = lowered.components(separatedBy: CharacterSet.letters.inverted)
        let photoWords: Set<String> = [
            "photo", "photos", "photograph", "photographs", "pic", "pics", "selfie", "selfies", "picture", "pictures",
        ]
        let russianStems = ["фото", "селфи", "снимок", "снимки", "картинк"]
        return words.contains { photoWords.contains($0) }
            || russianStems.contains { lowered.contains($0) }
    }
}
