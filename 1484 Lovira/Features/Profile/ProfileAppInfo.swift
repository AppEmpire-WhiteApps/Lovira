import Foundation

enum ProfileAppInfo {
    static let supportEmail = "recruitment@marissagallagher.com"
    static let appStoreID = "6827970568"

    static var appStoreURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")
    }

    static var reviewURL: URL? {
        guard let appStoreURL else { return nil }
        var components = URLComponents(url: appStoreURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "action", value: "write-review")]
        return components?.url
    }

    static var supportURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [URLQueryItem(name: "subject", value: "App Support")]
        return components.url
    }

    static var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return LocalizedText("Version \(version) (\(build))", ru: "Версия \(version) (\(build))").value
    }
}
