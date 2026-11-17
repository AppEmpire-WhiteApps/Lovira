import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color.black

            Image("LaunchIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 128, height: 128)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LocalizedText("Loading", ru: "Загрузка").value)
        .accessibilityIdentifier("app.splash")
    }
}
