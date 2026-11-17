import Foundation
import SwiftUI

enum WelcomeLegalDocument: String, Identifiable {
    case terms
    case privacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .terms: LocalizedText("Terms of Use", ru: "Условия использования").value
        case .privacy: LocalizedText("Privacy Policy", ru: "Политика конфиденциальности").value
        }
    }

    func loadContent(language: String, bundle: Bundle = .main) throws -> WelcomeLegalContent {
        let resource = "\(rawValue)-\(language)"
        guard
            let url = bundle.url(forResource: resource, withExtension: "json", subdirectory: "Legal")
                ?? bundle.url(forResource: resource, withExtension: "json")
        else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(WelcomeLegalContent.self, from: Data(contentsOf: url))
    }
}

struct WelcomeLegalContent: Decodable {
    struct Section: Decodable {
        let title: String
        let paragraphs: [String]
    }

    let title: String
    let effectiveDate: String
    let sections: [Section]
}

struct WelcomeLegalScreen: View {
    let document: WelcomeLegalDocument
    @Environment(\.dismiss) private var dismiss
    @State private var content: WelcomeLegalContent?
    @State private var loadingFailed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    if let content {
                        legalContent(content)
                    } else if loadingFailed {
                        unavailableContent
                    } else {
                        ProgressView()
                            .tint(Theme.pink)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: 640, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .foregroundStyle(.white)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedText("Close", ru: "Закрыть").value) { dismiss() }
                        .tint(Theme.pink)
                }
            }
            .task(id: document) {
                do {
                    content = try document.loadContent(language: AppLanguage.code)
                    loadingFailed = false
                } catch {
                    loadingFailed = true
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func legalContent(_ content: WelcomeLegalContent) -> some View {
        Group {
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: content.title)
                    .font(.appH2)
                    .accessibilityAddTraits(.isHeader)
                Text(
                    verbatim: LocalizedText(
                        "Effective date: \(content.effectiveDate)",
                        ru: "Дата вступления в силу: \(content.effectiveDate)"
                    ).value
                )
                .font(.appCaption)
                .foregroundStyle(Theme.textSecondary)
            }
            ForEach(Array(content.sections.enumerated()), id: \.offset) { _, section in
                VStack(alignment: .leading, spacing: 12) {
                    Text(verbatim: section.title)
                        .font(.appH3)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                        Text(verbatim: paragraph)
                            .font(.appBody)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .textSelection(.enabled)
    }

    private var unavailableContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: document.title)
                .font(.appH2)
            Text(
                verbatim: LocalizedText(
                    "The document could not be loaded. Please contact us for a copy.",
                    ru: "Не удалось загрузить документ. Свяжитесь с нами, чтобы получить копию."
                ).value)
            if let url = ProfileAppInfo.supportURL {
                Link(ProfileAppInfo.supportEmail, destination: url)
                    .tint(Theme.pink)
            }
        }
    }
}
