import Foundation
import SwiftData

extension CreateWizardModel {
    /// A detached draft: changing wizard controls never mutates the stored character.
    convenience init(character: CustomCharacter) {
        self.init()
        name = character.name
        age = Double(character.age)
        ethnicity = Ethnicity(rawValue: character.ethnicityRaw) ?? .caucasian
        eyeColor = EyeColor(rawValue: character.eyeColorRaw) ?? .brown
        hairStyle = HairStyle(rawValue: character.hairStyleRaw) ?? .longWavy
        hairColor = HairColor(rawValue: character.hairColorRaw) ?? .brunette
        bodyType = BodyType(rawValue: character.bodyTypeRaw) ?? .slim
        traits = character.traits
        relationship = character.relationship
        interests = character.interests
        voice = character.voice
        step = .summary
    }

    /// Updates only editable attributes. Identity, media and related records are untouched.
    @discardableResult
    func saveChanges(to character: CustomCharacter, using app: AppModel) throws -> Bool {
        guard canSaveCharacter, app.authorize(.characterEdit) else {
            return false
        }

        let original = CharacterEditableValues(character: character)
        CharacterEditableValues(wizard: self).apply(to: character)
        do {
            try app.context.save()
            return true
        } catch {
            // Do not roll back the shared context: it may contain unrelated chat changes.
            original.apply(to: character)
            throw error
        }
    }
}

/// Exact raw values also let a failed save restore unknown legacy enum values unchanged.
private struct CharacterEditableValues {
    let name: String
    let age: Int
    let ethnicityRaw: String
    let eyeColorRaw: String
    let hairStyleRaw: String
    let hairColorRaw: String
    let bodyTypeRaw: String
    let traitsRaw: [String]
    let relationshipRaw: String
    let interestsRaw: [String]
    let voiceRaw: String
    let appearancePrompt: String

    init(character: CustomCharacter) {
        name = character.name
        age = character.age
        ethnicityRaw = character.ethnicityRaw
        eyeColorRaw = character.eyeColorRaw
        hairStyleRaw = character.hairStyleRaw
        hairColorRaw = character.hairColorRaw
        bodyTypeRaw = character.bodyTypeRaw
        traitsRaw = character.traitsRaw
        relationshipRaw = character.relationshipRaw
        interestsRaw = character.interestsRaw
        voiceRaw = character.voiceRaw
        appearancePrompt = character.appearancePrompt
    }

    @MainActor
    init(wizard: CreateWizardModel) {
        name = wizard.trimmedName
        age = wizard.ageValue
        ethnicityRaw = (wizard.ethnicity ?? .caucasian).rawValue
        eyeColorRaw = wizard.eyeColor.rawValue
        hairStyleRaw = wizard.hairStyle.rawValue
        hairColorRaw = wizard.hairColor.rawValue
        bodyTypeRaw = wizard.bodyType.rawValue
        traitsRaw = wizard.traits.map(\.rawValue)
        relationshipRaw = wizard.relationship.rawValue
        interestsRaw = wizard.interests.map(\.rawValue)
        voiceRaw = wizard.voice.rawValue
        appearancePrompt = wizard.appearance
    }

    func apply(to character: CustomCharacter) {
        character.name = name
        character.age = age
        character.ethnicityRaw = ethnicityRaw
        character.eyeColorRaw = eyeColorRaw
        character.hairStyleRaw = hairStyleRaw
        character.hairColorRaw = hairColorRaw
        character.bodyTypeRaw = bodyTypeRaw
        character.traitsRaw = traitsRaw
        character.relationshipRaw = relationshipRaw
        character.interestsRaw = interestsRaw
        character.voiceRaw = voiceRaw
        character.appearancePrompt = appearancePrompt
    }
}
