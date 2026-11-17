import Foundation
import Observation
import SwiftData

enum CreateStep: Int, CaseIterable, Identifiable {
    case ethnicity
    case age
    case eyes
    case hair
    case body
    case personality
    case relationship
    case interests
    case voice
    case name
    case summary

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .ethnicity: LocalizedText("Choose her look", ru: "Выбери её внешность").value
        case .age: LocalizedText("How old is she?", ru: "Сколько ей лет?").value
        case .eyes: LocalizedText("Eye color", ru: "Цвет глаз").value
        case .hair: LocalizedText("Her hair", ru: "Её волосы").value
        case .body: LocalizedText("Body type", ru: "Телосложение").value
        case .personality: LocalizedText("Personality", ru: "Характер").value
        case .relationship: LocalizedText("Who is she to you?", ru: "Кто она для тебя?").value
        case .interests: LocalizedText("Her interests", ru: "Её интересы").value
        case .voice: LocalizedText("Her voice", ru: "Её голос").value
        case .name: LocalizedText("Give her a name", ru: "Дай ей имя").value
        case .summary: LocalizedText("Almost there", ru: "Почти готово").value
        }
    }

    var subtitle: String {
        switch self {
        case .ethnicity:
            LocalizedText("It defines her overall appearance", ru: "Определяет её общий облик").value
        case .age:
            LocalizedText("All characters are adults 21+", ru: "Все персонажи — взрослые 21+").value
        case .eyes:
            LocalizedText("The first thing you'll notice", ru: "Первое, что ты заметишь").value
        case .hair:
            LocalizedText("Pick a style and a color", ru: "Выбери причёску и цвет").value
        case .body:
            LocalizedText("Choose her figure", ru: "Выбери её фигуру").value
        case .personality:
            LocalizedText("Pick up to 3 traits", ru: "Выбери до 3 черт").value
        case .relationship:
            LocalizedText("It sets the tone of your chats", ru: "Задаёт тон ваших разговоров").value
        case .interests:
            LocalizedText("Pick up to 5 things she loves", ru: "Выбери до 5 увлечений").value
        case .voice:
            LocalizedText("Tap play to listen", ru: "Нажми, чтобы послушать").value
        case .name:
            LocalizedText("Or let fate decide", ru: "Или доверься случаю").value
        case .summary:
            LocalizedText("Check everything and bring her to life", ru: "Проверь всё и оживи её").value
        }
    }
}

struct CreateFailure: Equatable {
    enum Stage: Equatable {
        case portraits
        case saving
    }

    let stage: Stage
    let message: String
}

enum CreatePhase: Equatable {
    case wizard
    case generating
    case picking
    case finishing
    case failed(CreateFailure)
}

/// All choices and generation state of the character creation wizard.
@Observable
@MainActor
final class CreateWizardModel {
    static let maxTraits = 3
    static let maxInterests = 5
    static let maxNameLength = 20
    static let portraitCount = 4

    static let extraScenes = [
        "Candid photo in a cozy cafe holding a cup of coffee, sitting by the window, casual outfit",
        "Mirror selfie in a stylish outfit, full body, holding the phone, bedroom mirror"
    ]

    static let randomNames = [
        "Emma", "Olivia", "Ava", "Isabella", "Lily", "Zoe", "Nora", "Hannah",
        "Alina", "Mila", "Eva", "Kira", "Lucia", "Valentina", "Aria", "Maya",
        "Leah", "Sara", "Nina", "Jasmine", "Ruby", "Daria"
    ]

    var step: CreateStep = .ethnicity
    var isMovingForward = true

    var ethnicity: Ethnicity?
    var age: Double = 24
    var eyeColor: EyeColor = .brown
    var hairStyle: HairStyle = .longWavy
    var hairColor: HairColor = .brunette
    var bodyType: BodyType = .slim
    var traits: [CompanionTrait] = []
    var relationship: Relationship = .girlfriend
    var interests: [Interest] = []
    var voice: VoiceStyle = .soft
    var name = ""

    var phase: CreatePhase = .wizard
    private(set) var portraits: [String] = []
    var selectedPortrait: String?
    private(set) var seed = Int.random(in: 1...999_999_999)
    private(set) var savedCharacterID: String?
    private var isPerformingAction = false

    // MARK: Derived values

    var ageValue: Int {
        Int(age.rounded())
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSaveCharacter: Bool {
        ethnicity != nil
            && (21...45).contains(ageValue)
            && !trimmedName.isEmpty
            && name.count <= Self.maxNameLength
            && !traits.isEmpty
            && traits.count <= Self.maxTraits
            && !interests.isEmpty
            && interests.count <= Self.maxInterests
    }

    var progress: Double {
        Double(step.rawValue + 1) / Double(CreateStep.allCases.count)
    }

    var isFirstStep: Bool {
        step == CreateStep.allCases.first
    }

    var canContinue: Bool {
        switch step {
        case .ethnicity:
            ethnicity != nil
        case .personality:
            !traits.isEmpty
        case .interests:
            !interests.isEmpty
        case .name:
            !trimmedName.isEmpty
        default:
            true
        }
    }

    var appearance: String {
        PhotoGenerator.appearance(
            age: ageValue,
            ethnicity: ethnicity ?? .caucasian,
            eyeColor: eyeColor,
            hairStyle: hairStyle,
            hairColor: hairColor,
            bodyType: bodyType
        )
    }

    // MARK: Navigation

    func goNext() {
        guard canContinue, let next = CreateStep(rawValue: step.rawValue + 1) else {
            return
        }
        isMovingForward = true
        step = next
    }

    func goBack() {
        guard let previous = CreateStep(rawValue: step.rawValue - 1) else {
            return
        }
        isMovingForward = false
        step = previous
    }

    func jump(to target: CreateStep) {
        isMovingForward = target.rawValue > step.rawValue
        step = target
    }

    // MARK: Choices

    func toggle(_ trait: CompanionTrait) {
        if let index = traits.firstIndex(of: trait) {
            traits.remove(at: index)
        } else if traits.count < Self.maxTraits {
            traits.append(trait)
        }
    }

    func toggle(_ interest: Interest) {
        if let index = interests.firstIndex(of: interest) {
            interests.remove(at: index)
        } else if interests.count < Self.maxInterests {
            interests.append(interest)
        }
    }

    func randomizeName() {
        let options = Self.randomNames.filter { $0 != trimmedName }
        name = options.randomElement() ?? "Emma"
    }

    func limitNameLength() {
        if name.count > Self.maxNameLength {
            name = String(name.prefix(Self.maxNameLength))
        }
    }

    // MARK: Generation

    /// Generates the portrait options. All wizard choices are kept on failure.
    func generatePortraits(using app: AppModel) async {
        guard AIConsentStore.shared.request() else { return }
        guard !Task.isCancelled, !isPerformingAction, savedCharacterID == nil,
            canSaveCharacter, app.authorize(.characterCreate)
        else {
            return
        }
        isPerformingAction = true
        defer { isPerformingAction = false }
        discardPortraits()
        seed = Int.random(in: 1...999_999_999)
        phase = .generating
        do {
            let files = try await app.photoGenerator.generate(
                appearance: appearance,
                scene: PhotoGenerator.portraitScene,
                seed: seed,
                count: Self.portraitCount
            )
            if Task.isCancelled {
                files.forEach(MediaStore.delete)
                return
            }
            portraits = files
            selectedPortrait = files.first
            phase = .picking
            Haptics.success()
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else {
                return
            }
            phase = .failed(CreateFailure(stage: .portraits, message: Self.message(for: error)))
            Haptics.warning()
        }
    }

    /// Takes a couple of extra gallery photos (best effort) and saves the character.
    func finishCreation(using app: AppModel) async {
        guard AIConsentStore.shared.request() else { return }
        guard !Task.isCancelled, !isPerformingAction, savedCharacterID == nil,
            canSaveCharacter, let portrait = selectedPortrait,
            app.authorize(.characterCreate)
        else {
            return
        }
        isPerformingAction = true
        defer { isPerformingAction = false }
        phase = .finishing

        let appearance = appearance
        let baseSeed = seed
        async let first = extraPhoto(app: app, appearance: appearance, sceneIndex: 0, seed: baseSeed + 1)
        async let second = extraPhoto(app: app, appearance: appearance, sceneIndex: 1, seed: baseSeed + 2)
        let extras = [await first, await second].compactMap { $0 }

        if Task.isCancelled {
            extras.forEach(MediaStore.delete)
            return
        }

        // Entitlement/free allowance may have changed while the photos were generated.
        guard app.authorize(.characterCreate) else {
            extras.forEach(MediaStore.delete)
            phase = .picking
            return
        }

        let character = CustomCharacter(
            name: trimmedName,
            age: ageValue,
            ethnicity: ethnicity ?? .caucasian,
            eyeColor: eyeColor,
            hairStyle: hairStyle,
            hairColor: hairColor,
            bodyType: bodyType,
            traits: traits,
            relationship: relationship,
            interests: interests,
            voice: voice,
            appearancePrompt: appearance,
            seed: baseSeed,
            avatarFile: portrait,
            photoFiles: [portrait] + extras
        )
        app.context.insert(character)
        do {
            try app.context.save()
        } catch {
            app.context.delete(character)
            extras.forEach(MediaStore.delete)
            phase = .failed(CreateFailure(stage: .saving, message: Self.message(for: error)))
            Haptics.warning()
            return
        }

        app.access.recordCharacterAction()
        portraits.filter { $0 != portrait }.forEach(MediaStore.delete)
        portraits = []
        savedCharacterID = character.id
    }

    /// Deletes generated portraits that were not saved into a character.
    func discardPortraits() {
        portraits.forEach(MediaStore.delete)
        portraits = []
        selectedPortrait = nil
    }

    private func extraPhoto(app: AppModel, appearance: String, sceneIndex: Int, seed: Int) async -> String? {
        let files = try? await app.photoGenerator.generate(
            appearance: appearance,
            scene: Self.extraScenes[sceneIndex],
            seed: seed,
            count: 1
        )
        return files?.first
    }

    private static func message(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return LocalizedText(
            "Something went wrong. Please try again.",
            ru: "Что-то пошло не так. Попробуй ещё раз."
        ).value
    }
}
