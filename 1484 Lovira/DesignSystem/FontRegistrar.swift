import CoreText
import SwiftUI
import UIKit

enum FontRegistrar {
    static func registerFonts() {
        let names = [
            PoppinsWeight.regular.rawValue,
            PoppinsWeight.medium.rawValue,
            PoppinsWeight.semibold.rawValue,
            PoppinsWeight.bold.rawValue
        ]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

enum Appearance {
    static func configure() {
        let navigation = UINavigationBarAppearance()
        navigation.configureWithTransparentBackground()
        navigation.backgroundColor = UIColor(Theme.background)
        navigation.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont(name: PoppinsWeight.semibold.rawValue, size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)
        ]
        navigation.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont(name: PoppinsWeight.bold.rawValue, size: 32) ?? .systemFont(ofSize: 32, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
        UINavigationBar.appearance().compactAppearance = navigation
        UINavigationBar.appearance().tintColor = UIColor(Theme.pink)

        UITextField.appearance().tintColor = UIColor(Theme.pink)
        UITextView.appearance().tintColor = UIColor(Theme.pink)
    }
}
