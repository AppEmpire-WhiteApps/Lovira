import Foundation

enum PhotoSource: Hashable, Codable {
    case asset(String)
    case file(String)

    var key: String {
        switch self {
        case .asset(let name):
            return "asset:\(name)"
        case .file(let name):
            return "file:\(name)"
        }
    }
}

struct Companion: Identifiable, Hashable {
    let id: String
    var name: String
    var age: Int
    var city: String
    var occupation: String
    var bio: String
    var traits: [CompanionTrait]
    var interests: [Interest]
    var relationship: Relationship
    var greeting: String
    var appearancePrompt: String
    var personaNotes: String
    var voice: VoiceStyle
    var cover: PhotoSource
    var avatar: PhotoSource
    var gallery: [PhotoSource]
    var chatPhotoPool: [ScenePhoto]
    var videoResource: String?
    var isCustom: Bool
    var isNew: Bool
    var popularity: Int
    var seed: Int?
}

struct ScenePhoto: Hashable {
    let photo: PhotoSource
    let keywords: [String]
    let caption: String
}
