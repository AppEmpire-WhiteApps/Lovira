import Foundation
import SwiftData

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

enum MessageKind: String, Codable {
    case text
    case voice
    case photo
    case video
    case system
}

enum MessageStatus: String, Codable {
    case sent
    case sending
    case failed
    case generating
}

@Model
final class Conversation {
    @Attribute(.unique) var id: UUID
    var companionId: String
    var scenarioId: String?
    var isPinned: Bool
    var disappearAfter: Double
    var createdAt: Date
    var lastMessageAt: Date
    var lastMessagePreview: String
    var unreadCount: Int
    var userMessageCount: Int
    var memoryCheckpoint: Int

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.conversation)
    var messages: [ChatMessage] = []

    init(companionId: String) {
        self.id = UUID()
        self.companionId = companionId
        self.scenarioId = nil
        self.isPinned = false
        self.disappearAfter = 0
        self.createdAt = .now
        self.lastMessageAt = .now
        self.lastMessagePreview = ""
        self.unreadCount = 0
        self.userMessageCount = 0
        self.memoryCheckpoint = 0
    }

    var sortedMessages: [ChatMessage] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }
}

@Model
final class ChatMessage {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var roleRaw: String
    var kindRaw: String
    var text: String
    var transcript: String?
    var mediaFile: String?
    var mediaAsset: String?
    var audioFile: String?
    var duration: Double
    var statusRaw: String
    var expiresAt: Date?
    var photoPrompt: String?
    var freeMessageCharged: Bool = false
    var subscriptionLocked: Bool = false
    /// Generated video (MP4 in `MediaStore`); `mediaFile` then holds its thumbnail.
    var videoFile: String? = nil
    var conversation: Conversation?

    init(
        role: MessageRole,
        kind: MessageKind,
        text: String,
        status: MessageStatus = .sent,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.roleRaw = role.rawValue
        self.kindRaw = kind.rawValue
        self.text = text
        self.transcript = nil
        self.mediaFile = nil
        self.mediaAsset = nil
        self.audioFile = nil
        self.duration = 0
        self.statusRaw = status.rawValue
        self.expiresAt = nil
        self.photoPrompt = nil
    }

    var role: MessageRole {
        get { MessageRole(rawValue: roleRaw) ?? .user }
        set { roleRaw = newValue.rawValue }
    }

    var kind: MessageKind {
        get { MessageKind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }

    var status: MessageStatus {
        get { MessageStatus(rawValue: statusRaw) ?? .sent }
        set { statusRaw = newValue.rawValue }
    }

    var photoSource: PhotoSource? {
        if let mediaAsset {
            return .asset(mediaAsset)
        }
        if let mediaFile {
            return .file(mediaFile)
        }
        return nil
    }
}

@Model
final class MemoryFact {
    @Attribute(.unique) var id: UUID
    var companionId: String
    var text: String
    var createdAt: Date

    init(companionId: String, text: String) {
        self.id = UUID()
        self.companionId = companionId
        self.text = text
        self.createdAt = .now
    }
}

@Model
final class CollectedMedia {
    @Attribute(.unique) var id: UUID
    var companionId: String
    var mediaFile: String?
    var mediaAsset: String?
    var videoResource: String?
    /// Generated video (MP4 in `MediaStore`); `mediaFile` then holds its thumbnail.
    var videoFile: String? = nil
    var createdAt: Date

    init(companionId: String, photo: PhotoSource) {
        self.id = UUID()
        self.companionId = companionId
        switch photo {
        case .asset(let name):
            self.mediaAsset = name
        case .file(let name):
            self.mediaFile = name
        }
        self.videoResource = nil
        self.createdAt = .now
    }

    init(companionId: String, videoResource: String) {
        self.id = UUID()
        self.companionId = companionId
        self.mediaFile = nil
        self.mediaAsset = nil
        self.videoResource = videoResource
        self.createdAt = .now
    }

    init(companionId: String, videoFile: String, thumbnailFile: String) {
        self.id = UUID()
        self.companionId = companionId
        self.mediaFile = thumbnailFile
        self.mediaAsset = nil
        self.videoResource = nil
        self.videoFile = videoFile
        self.createdAt = .now
    }

    var isVideo: Bool {
        videoFile != nil || videoResource != nil
    }

    var videoURL: URL? {
        if let videoFile {
            return MediaStore.url(for: videoFile)
        }
        if let videoResource {
            return Bundle.main.url(forResource: videoResource, withExtension: "mp4")
        }
        return nil
    }

    var photoSource: PhotoSource? {
        if let mediaAsset {
            return .asset(mediaAsset)
        }
        if let mediaFile {
            return .file(mediaFile)
        }
        return nil
    }
}

@Model
final class CustomCharacter {
    @Attribute(.unique) var id: String
    var createdAt: Date
    var name: String
    var age: Int
    var ethnicityRaw: String
    var eyeColorRaw: String
    var hairStyleRaw: String
    var hairColorRaw: String
    var bodyTypeRaw: String
    var traitsRaw: [String]
    var relationshipRaw: String
    var interestsRaw: [String]
    var voiceRaw: String
    var appearancePrompt: String
    var seed: Int
    var avatarFile: String
    var photoFiles: [String]

    init(
        name: String,
        age: Int,
        ethnicity: Ethnicity,
        eyeColor: EyeColor,
        hairStyle: HairStyle,
        hairColor: HairColor,
        bodyType: BodyType,
        traits: [CompanionTrait],
        relationship: Relationship,
        interests: [Interest],
        voice: VoiceStyle,
        appearancePrompt: String,
        seed: Int,
        avatarFile: String,
        photoFiles: [String]
    ) {
        self.id = "custom_" + UUID().uuidString
        self.createdAt = .now
        self.name = name
        self.age = age
        self.ethnicityRaw = ethnicity.rawValue
        self.eyeColorRaw = eyeColor.rawValue
        self.hairStyleRaw = hairStyle.rawValue
        self.hairColorRaw = hairColor.rawValue
        self.bodyTypeRaw = bodyType.rawValue
        self.traitsRaw = traits.map(\.rawValue)
        self.relationshipRaw = relationship.rawValue
        self.interestsRaw = interests.map(\.rawValue)
        self.voiceRaw = voice.rawValue
        self.appearancePrompt = appearancePrompt
        self.seed = seed
        self.avatarFile = avatarFile
        self.photoFiles = photoFiles
    }

    var traits: [CompanionTrait] {
        traitsRaw.compactMap(CompanionTrait.init(rawValue:))
    }

    var interests: [Interest] {
        interestsRaw.compactMap(Interest.init(rawValue:))
    }

    var relationship: Relationship {
        Relationship(rawValue: relationshipRaw) ?? .girlfriend
    }

    var voice: VoiceStyle {
        VoiceStyle(rawValue: voiceRaw) ?? .soft
    }

    var companion: Companion {
        let photos = photoFiles.map { PhotoSource.file($0) }
        let traitList = traits.map(\.title).joined(separator: ", ")
        let bio = LocalizedText(
            "Your own creation. \(traitList).",
            ru: "Создана тобой. \(traitList)."
        ).value
        let greeting = LocalizedText(
            "Hi, it's \(name) 💕 I've been waiting to meet you. Tell me about yourself?",
            ru: "Привет, это \(name) 💕 Я так ждала нашего знакомства. Расскажешь о себе?"
        ).value
        return Companion(
            id: id,
            name: name,
            age: age,
            city: "",
            occupation: relationship.title,
            bio: bio,
            traits: traits,
            interests: interests,
            relationship: relationship,
            greeting: greeting,
            appearancePrompt: appearancePrompt,
            personaNotes: "",
            voice: voice,
            cover: photos.first ?? .file(avatarFile),
            avatar: .file(avatarFile),
            gallery: photos,
            chatPhotoPool: [],
            videoResource: nil,
            isCustom: true,
            isNew: false,
            popularity: 0,
            seed: seed
        )
    }
}
