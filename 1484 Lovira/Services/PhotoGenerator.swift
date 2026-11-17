import Foundation

/// Photorealistic character photo generation through LLMApps text2image.
final class PhotoGenerator {
    private let client: LLMAppsClient

    static let styleSuffix = """
        RAW candid photo shot on iPhone 15 Pro, natural light, realistic natural skin texture with visible pores \
        and tiny imperfections, subtle natural makeup, realistic proportions and hands, shallow depth of field, \
        photorealistic, looks like a real person's social media photo, not a model shoot, no text, no watermark
        """

    static let negativePrompt = """
        cartoon, anime, illustration, 3d render, cgi, doll, plastic skin, airbrushed, oversaturated, \
        deformed hands, extra fingers, distorted face, blurry, watermark, text, logo, nudity, child, teen
        """

    init(client: LLMAppsClient) {
        self.client = client
    }

    static func appearance(
        age: Int,
        ethnicity: Ethnicity,
        eyeColor: EyeColor,
        hairStyle: HairStyle,
        hairColor: HairColor,
        bodyType: BodyType
    ) -> String {
        """
        \(age)-year-old adult \(ethnicity.prompt) woman, \(hairStyle.prompt) \(hairColor.prompt) hair, \
        \(eyeColor.rawValue) eyes, \(bodyType.prompt) build, attractive girl-next-door look
        """
    }

    static func prompt(appearance: String, scene: String) -> String {
        "Photo of a \(appearance). \(scene). Tasteful and fully clothed. \(styleSuffix)"
    }

    static let portraitScene =
        "Waist-up portrait, smiling softly at the camera, cozy bright apartment background, casual stylish outfit"

    /// Scene ideas used when the chat model did not describe the photo itself.
    static let defaultScenes: [(keywords: [String], caption: String)] = [
        (["cafe", "coffee", "latte", "tea", "кафе", "кофе"], "Selfie in a cozy cafe holding a cup of coffee"),
        (["home", "sofa", "cozy", "дом", "диван"], "Selfie at home relaxing on the sofa in a soft oversized sweater"),
        (["mirror", "outfit", "look", "образ", "наряд", "зеркал"], "Mirror selfie showing a stylish new outfit"),
        (
            ["dinner", "restaurant", "date", "ужин", "ресторан", "свидан"],
            "Photo at a candle-lit restaurant in an elegant evening dress"
        ),
        (
            ["sunset", "park", "walk", "beach", "закат", "парк", "прогул", "пляж"],
            "Selfie outdoors at golden-hour sunset in a light summer dress"
        ),
        (
            ["night", "city", "street", "ноч", "город", "улиц"],
            "Selfie on a city street at night with soft neon lights"
        ),
        (
            ["morning", "bed", "wake", "утр", "кроват", "просн"],
            "Morning selfie in bed in cozy pajamas, soft window light"
        ),
    ]

    /// Generates images and stores them in `MediaStore`; returns file names.
    func generate(appearance: String, scene: String, seed: Int, count: Int = 1) async throws -> [String] {
        let urls = try await client.textToImage(
            prompt: Self.prompt(appearance: appearance, scene: scene),
            negativePrompt: Self.negativePrompt,
            imageSize: "portrait_4_3",
            numImages: count,
            seed: seed
        )
        var files: [String] = []
        for url in urls {
            let data = try await client.download(url)
            let jpeg = ImageLoader.jpegData(from: data, maxPixelSize: 1400) ?? data
            files.append(try MediaStore.save(jpeg, fileExtension: "jpg"))
        }
        return files
    }
}
